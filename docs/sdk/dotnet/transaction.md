---
title: ".NET SDK: transaction, savepoint ve sonuç uzlaştırma"
slug: "/sdk/dotnet/transaction"
---

# .NET SDK: transaction, savepoint ve sonuç uzlaştırma

> **Kapsam:** Drive 2.1.0 wire v1. Açık transaction yoksa mutation autocommit akışını kullanır. Native AI request key'leri bu bölümdeki wire receipt token'larıyla aynı değildir.

ADO.NET bağlantısı üzerinde transaction başlatmak tek başına yeterli değildir: transaction'a katılacak her komutun `Transaction` özelliği de aynı nesneye ayarlanır. Sağlayıcı bu eşleşmeyi kontrol eder. Bu sayede bir komutun yanlışlıkla işlem dışına çıkması önlenir.

## İki değişikliği tek işlemde yapma

Aşağıdaki örnek iki ürünün stoklarını aynı transaction'da azaltır. İkinci üründe yeterli stok yoksa ilk değişiklik de geri alınır. `SdpAyarlar` sınıfı [bağlantı bölümündedir](baglanti.md).

```csharp
using System.Data;
using StarDataParadise.SDK;

await using var db = new SdpConnection(SdpAyarlar.BaglantiMetni());
await db.OpenAsync();
await using var tx = (SdpTransaction)await db.BeginTransactionAsync(
    IsolationLevel.Serializable);

try
{
    await AzaltAsync(101L, 1L);
    await AzaltAsync(102L, 2L);
    await tx.CommitAsync();
    Console.WriteLine("Her iki ürünün stoku güncellendi.");
}
catch (SdpException hata) when (hata.UnknownOutcome)
{
    Console.Error.WriteLine($"İşlem sonucu belirsiz; token={hata.RequestToken}");
    throw;
}
catch (Exception hata)
{
    try { await tx.RollbackAsync(); }
    catch (Exception geriAlma) { hata.Data["RollbackError"] = geriAlma.Message; }
    throw;
}

async Task AzaltAsync(long id, long adet)
{
    if (adet <= 0) throw new ArgumentOutOfRangeException(nameof(adet));
    await using var cmd = db.CreateCommand();
    cmd.Transaction = tx;
    cmd.CommandText = "UPDATE urunler SET stok = stok - :adet " +
                      "WHERE id = :id AND stok >= :adet";
    cmd.Parameters.Add(new SdpParameter("id", id));
    cmd.Parameters.Add(new SdpParameter("adet", adet));
    if (await cmd.ExecuteNonQueryAsync() != 1)
        throw new InvalidOperationException("Ürün yok veya stok yetersiz");
}
```

Başlangıç laboratuvar verisi aynıysa tek başarılı çalıştırma ürün 101'i 20'den 19'a, ürün 102'yi 50'den 48'e indirir. Kod tekrar çalıştırılırsa bu bir başka stok değişikliğidir. Test amacıyla önceki çalışmanın kalıcı etkisini hesaba katın.

Sağlayıcı serializable işlemler sunar; `IsolationLevel.Unspecified` veya `Serializable` desteklenen seçimlerdir. Sunucunun capability ve erişim denetimi yine geçerlidir. MySQL tabanlı bridge kullanılıyorsa ilgili wire transaction desteği ve desteklenen tablolar önceden sağlanmış olmalıdır.

## Savepoint ve okuyucu kuralı

`SdpTransaction` somut tipinde `SaveAsync`, `RollbackAsync(name)` ve `ReleaseAsync` metotları vardır:

```csharp
await tx.SaveAsync("ek_kalem_oncesi");
// Bu noktadan sonra isteğe bağlı ek işlemler yapılabilir.
await tx.RollbackAsync("ek_kalem_oncesi");
await tx.ReleaseAsync("ek_kalem_oncesi");
```

Savepoint yalnızca açık transaction içindeki değişiklikleri kapsar. Başka bağlantıya taşınamaz ve commit sonrası kullanılmaz. Commit, rollback veya savepoint çağrısından önce açık `SdpDataReader` kapanmalıdır. Kodda `await using var rows` aynı metodun sonuna kadar yaşıyorsa commit'i yanlışlıkla reader kapanmadan çağırabilirsiniz; reader için ayrı bir blok kullanın.

## Token'ı commit öncesinde belirleme

Uygulama token'ı commit gönderilmeden önce kendi işlem kaydına yazmak isterse:

```csharp
string token = Guid.NewGuid().ToString("N");
// token'ı iş isteği kimliğiyle güvenilir uygulama kaydında ilişkilendirin.
await tx.CommitWithTokenAsync(token);
```

Token 32 küçük harfli hex karakter olmalıdır. `CommitAsync()` kullanıldığında sağlayıcı token üretir; `SdpTransaction.LastRequestToken` ve hata içindeki `RequestToken` inceleme için bulunur. Autocommit komutta `SdpCommand.LastRequestToken` aynı amaçla kullanılabilir. Bir token'ı başka bir iş işleminin kimliği olarak tekrar kullanmayın.

## Yanıt kaybı başarısızlık kanıtı değildir

`SdpException.UnknownOutcome=true` sunucunun sonucu istemci açısından kesinleşmediğini belirtir. Aynı hesapla yeni bağlantıdan wire receipt sorgulayın:

```csharp
await using var kontrol = new SdpConnection(SdpAyarlar.BaglantiMetni());
await kontrol.OpenAsync();
var belge = await kontrol.GetOutcomeAsync(token);
var durum = belge.GetProperty("status").GetString();
if (durum == "committed")
    Console.WriteLine("Commit doğrulandı.");
else
    throw new InvalidOperationException("İşlem sonucu çözülmedi: " + durum);
```

`unknown` yanıtı işlem uygulanmadı demek değildir. SDK otomatik yazma tekrarı yapmaz. HTTP retry politikası veya background job katmanı bu hatayı körlemesine yeniden gönderirse aynı stok azaltma iki defa gerçekleşebilir. İstek durumunu belirsiz olarak saklayın, receipt ve uygulamanın sipariş kimliği üzerinden uzlaştırın.

Bir işlemi loglamak için parola veya bütün connection string gerekmez. İş ID'si, token, SQLSTATE ve correlation ID genellikle hangi adımın inceleneceğini belirlemek için daha uygundur. Native SQL'de receipt token olmadan `UnknownOutcome` oluşabileceği için [native hata alanlarını](native-sql-ai.md) ayrıca kullanın.

## Kaynaklar

- [Transaction metotları](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/src/SdpTransaction.cs)
- [Connection ve outcome API'si](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/src/SdpConnection.cs)
- [Belirsiz sonuç ve yapılandırılmış hata alanları](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/src/SdpException.cs)

