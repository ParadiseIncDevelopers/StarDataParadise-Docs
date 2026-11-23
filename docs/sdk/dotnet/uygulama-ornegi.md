---
title: ".NET SDK: transaction içinde sipariş oluşturma"
slug: "/sdk/dotnet/uygulama-ornegi"
---

# .NET SDK: transaction içinde sipariş oluşturma

> **Kapsam:** Drive 2.1.0, .NET 8/10 wire v1; `main.public` laboratuvarındaki müşteriler, ürünler, siparişler ve sipariş kalemleri. Örnek kaynak API'leriyle karşılaştırılmış uygulama kodudur.

Bu servis bir ürün için sipariş oluşturur. Birim fiyat sunucudan okunur; istemcinin gönderdiği fiyat kullanılmaz. Stok koşullu UPDATE ile azaltılır. Sipariş ve kalem aynı transaction içinde eklenir. İşlem tamamlandığında toplam döndürülür; başarısızlıkta uygulamanın üst katmanı bilgilendirilir.

Servis kendi HTTP endpoint'ini, kullanıcı oturumunu veya kimlik üretme algoritmasını tanımlamaz. Bu sorumluluklar çağıran uygulamadadır. Örneğin ASP.NET uygulamasında kimliği doğrulanmış kullanıcıdan müşteri ID'si çıkarılır; başka bir müşterinin sipariş vermesine izin verilmez. Bu örnekte müşteriler laboratuvar verisinden seçilir.

Tam kaynak dosyaları ve çalıştırma adımları [ayrı örnek proje klasöründe](ornekler/siparis-servisi/README.md) bulunur.

## Servis kodu

`SdpAyarlar.cs` dosyasını [bağlantı bölümünden](baglanti.md) ekleyin. Aşağıdaki sınıfı ayrı `SiparisServisi.cs` dosyasında tutabilirsiniz:

```csharp
using System.Data;
using StarDataParadise.SDK;

public static class SiparisServisi
{
    public static async Task<decimal> OlusturAsync(
        long siparisId, long musteriId, long urunId, long adet,
        CancellationToken ct = default)
    {
        if (adet <= 0) throw new ArgumentOutOfRangeException(nameof(adet));
        await using var db = new SdpConnection(SdpAyarlar.BaglantiMetni());
        await db.OpenAsync(ct);
        await using var tx = (SdpTransaction)await db.BeginTransactionAsync(
            IsolationLevel.Serializable, ct);
        try
        {
            decimal fiyat;
            await using (var sorgu = db.CreateCommand())
            {
                sorgu.Transaction = tx;
                sorgu.CommandText = "SELECT fiyat FROM urunler WHERE id = :id";
                sorgu.Parameters.Add(new SdpParameter("id", urunId));
                await using var rows = await sorgu.ExecuteReaderAsync(ct);
                if (!await rows.ReadAsync(ct))
                    throw new InvalidOperationException("Ürün bulunamadı");
                fiyat = rows.GetDecimal(0);
            }

            await YazAsync(db, tx,
                "UPDATE urunler SET stok = stok - :adet " +
                "WHERE id = :id AND stok >= :adet", ct,
                new SdpParameter("id", urunId),
                new SdpParameter("adet", adet));

            decimal toplam = checked(fiyat * adet);
            await YazAsync(db, tx,
                "INSERT INTO siparisler (id, musteri_id, durum, toplam) " +
                "VALUES (:id, :musteri, :durum, :toplam)", ct,
                new SdpParameter("id", siparisId),
                new SdpParameter("musteri", musteriId),
                new SdpParameter("durum", "hazirlaniyor"),
                new SdpParameter("toplam", toplam));

            await YazAsync(db, tx,
                "INSERT INTO siparis_kalemleri " +
                "(siparis_id, urun_id, adet, birim_fiyat) " +
                "VALUES (:siparis, :urun, :adet, :fiyat)", ct,
                new SdpParameter("siparis", siparisId),
                new SdpParameter("urun", urunId),
                new SdpParameter("adet", adet),
                new SdpParameter("fiyat", fiyat));

            await tx.CommitAsync(ct);
            return toplam;
        }
        catch (SdpException hata) when (hata.UnknownOutcome)
        {
            // Üst katman RequestToken ve sipariş ID'sini uzlaştırma için saklar.
            throw;
        }
        catch (Exception hata)
        {
            try { await tx.RollbackAsync(CancellationToken.None); }
            catch (Exception ek) { hata.Data["RollbackError"] = ek.Message; }
            throw;
        }
    }

    private static async Task YazAsync(
        SdpConnection db, SdpTransaction tx, string sql,
        CancellationToken ct, params SdpParameter[] parametreler)
    {
        await using var cmd = db.CreateCommand();
        cmd.Transaction = tx;
        cmd.CommandText = sql;
        foreach (var p in parametreler) cmd.Parameters.Add(p);
        if (await cmd.ExecuteNonQueryAsync(ct) != 1)
            throw new InvalidOperationException("Kayıt değişmedi; stok yetersiz olabilir");
    }
}
```

`Program.cs` giriş noktası:

```csharp
using System.Globalization;
using StarDataParadise.SDK;

if (args.Length != 4)
{
    Console.Error.WriteLine(
        "Kullanım: dotnet run -- <siparis-id> <musteri-id> <urun-id> <adet>");
    return 2;
}
if (!long.TryParse(args[0], NumberStyles.Integer, CultureInfo.InvariantCulture, out var siparisId)
    || !long.TryParse(args[1], NumberStyles.Integer, CultureInfo.InvariantCulture, out var musteriId)
    || !long.TryParse(args[2], NumberStyles.Integer, CultureInfo.InvariantCulture, out var urunId)
    || !long.TryParse(args[3], NumberStyles.Integer, CultureInfo.InvariantCulture, out var adet))
{
    Console.Error.WriteLine("Argümanların tamamı signed 64 bit tamsayı olmalı.");
    return 2;
}

try
{
    Console.WriteLine(await SiparisServisi.OlusturAsync(siparisId, musteriId, urunId, adet));
    return 0;
}
catch (SdpException hata) when (hata.UnknownOutcome)
{
    Console.Error.WriteLine(
        $"status=unknown_outcome siparis_id={siparisId} request_token={Alan(hata.RequestToken)} " +
        $"code={hata.Code} sqlstate={Alan(hata.SqlState)} correlation_id={Alan(hata.CorrelationId)}");
    Console.Error.WriteLine("SQL yeniden gönderilmedi. Token ile yeni oturumdan sonucu sorgulayın.");
    Console.Error.Flush();
    return 7;
}
catch (SdpException hata)
{
    Console.Error.WriteLine(
        $"status=failed siparis_id={siparisId} code={hata.Code} sqlstate={Alan(hata.SqlState)} " +
        $"correlation_id={Alan(hata.CorrelationId)} reason={Alan(hata.Message)}");
    return 1;
}
catch (ArgumentException hata)
{
    Console.Error.WriteLine($"status=invalid_input reason={Alan(hata.Message)}");
    return 2;
}
catch (Exception hata)
{
    Console.Error.WriteLine($"status=failed siparis_id={siparisId} reason={Alan(hata.Message)}");
    return 1;
}

static string Alan(string? deger) =>
    deger?.Replace('\r', ' ').Replace('\n', ' ') ?? "<yok>";
```

Giriş noktası sipariş ID'si, müşteri ID'si, ürün ID'si ve adedi komut satırından alır. Belirsiz sonuçta receipt token'ı, sipariş ID'sini, hata kodunu, SQLSTATE ve correlation ID'yi `stderr` üzerine yazar ve `7` koduyla çıkar. Diğer hatalar `1`, geçersiz giriş `2`, başarı `0` kodudur. SQL yeniden çalıştırılmaz. Receipt bilgisini kaybetmemek için [örnek proje README'sindeki stderr kaydını](ornekler/siparis-servisi/README.md) ilk çalıştırmada kullanın.

## Beklenen sonuç ve tekrar çalıştırma

Laboratuvar başlangıcında ürün 101 fiyatı 750.00, stok 20 ise tek başarılı çağrı 1500.00 toplam döndürür ve stoku 18 yapar. 2002 numaralı sipariş ile ona bağlı bir kalem eklenir. Önce Java veya başka örneği çalıştırdıysanız başlangıç stoku değişmiş olabilir. Testi değerlendirirken mevcut veriyi esas alın.

2002 ID'si örnek için sabittir. İkinci çağrı yeni sipariş niyetiyle yapılıyorsa yeni ID gerekir; aynı HTTP isteğinin tekrarıysa uygulamanın bu isteği tanıyıp önceki durumunu döndürmesi gerekir. Yeni ID üreterek her ağ hatasını yeniden denemek aynı işin ikinci kez yapılmasına neden olabilir. Foreign key ve primary key, bütünlük sağlar; tek başına tüm idempotency akışını tasarlamaz.

## Neden bu sıralama?

Fiyat okumasının reader'ı stok güncellemesinden önce kapanır. Her komut `Transaction=tx` ile aynı işleme katılır. Sipariş kalemi kaydı birim fiyatı saklar; ürün kataloğunun gelecekteki fiyatı geçmiş siparişi değiştirmez. Toplam hesabı `decimal` ile yapılır; tablonun precision/scale sınırını aşan değer sunucuda reddedilebilir ve tüm işlem geri alınır.

## Uygulamaya taşırken

Servis metodunu sınırsız paralellik altında tek bir paylaşılan `SdpConnection` kullanacak şekilde dönüştürmeyin. Her iş biriminin bağlantı ve transaction sahipliği belli olsun. HTTP yanıtını ancak commit kesinleşince başarılı verin. Commit belirsizse uygulamanın işlem durumunu "inceleme bekliyor" gibi ayrı bir durumla saklayıp [outcome akışını](transaction.md) kullanın.

Örnek ödeme tahsilatı veya e-posta göndermez. Bu tür dış yan etkiler veritabanı rollback'iyle kendiliğinden geri alınmaz. Uygulama akışına eklendiğinde veritabanı işlemiyle dış servis işinin hangi noktada kesinleştiği ayrıca belirlenmelidir.

## Kaynaklar

- [ADO.NET komut ve transaction sözleşmesi](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/BUILD.md)
- [Aktif transaction eşleştirme kontrolü](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/src/SdpCommand.cs)
- [Commit ve rollback uygulaması](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/src/SdpTransaction.cs)

