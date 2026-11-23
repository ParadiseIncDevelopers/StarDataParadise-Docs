---
title: ".NET SDK: parametreli CRUD ve satır okuma"
slug: "/sdk/dotnet/crud"
---

# .NET SDK: parametreli CRUD ve satır okuma

> **Kapsam:** Drive 2.1.0, wire v1; orijinal engine laboratuvarı. Bağlantı örneklerinde [SdpAyarlar](baglanti.md) sınıfı kullanılır.

ADO.NET komutunda SQL metni `CommandText`, bağlı değerler `Parameters` koleksiyonunda tutulur. SQL içinde `:id` gibi isimli parametre kullanın. Kullanıcıdan gelen ürün adı, fiyat veya arama değeri SQL metniyle birleştirilmemelidir. Böylece tırnak karakteri, ondalık ayıracı ve SQL sözdizimi veri aktarımını etkilemez.

## Kayıt ekleme

Aşağıdaki kod laboratuvar tablosuna yeni bir ürün ekler. 9001 örnek kimliğinin boş olduğu varsayılır; tekrar çalıştırıldığında mevcut primary key nedeniyle hata alınabilir.

```csharp
using StarDataParadise.SDK;

await using var db = new SdpConnection(SdpAyarlar.BaglantiMetni());
await db.OpenAsync();
await using var cmd = db.CreateCommand();
cmd.CommandText = "INSERT INTO urunler (id, ad, fiyat, stok) " +
                  "VALUES (:id, :ad, :fiyat, :stok)";
cmd.Parameters.Add(new SdpParameter("id", 9001L));
cmd.Parameters.Add(new SdpParameter("ad", "Deneme ürünü"));
cmd.Parameters.Add(new SdpParameter("fiyat", 149.90m));
cmd.Parameters.Add(new SdpParameter("stok", 12L));
int etkilenen = await cmd.ExecuteNonQueryAsync();
Console.WriteLine($"Eklenen kayıt: {etkilenen}");
```

`149.90m`, C# `decimal` değeridir. `149.90` sonuna `m` eklemeden yazılırsa C# farklı sayısal tip seçer. Para için ondalık doğruluğu açıkça belirleyin. Parametre tipi ve tablo sütununun `DECIMAL(12,2)` kapasitesi birbirine uygun olmalıdır.

## Filtreleme ve sonuçları işleme

```csharp
using StarDataParadise.SDK;

await using var db = new SdpConnection(SdpAyarlar.BaglantiMetni());
await db.OpenAsync();
await using var cmd = db.CreateCommand();
cmd.CommandText = "SELECT id, ad, fiyat, stok FROM urunler " +
                  "WHERE id >= :ilk AND stok > 0 ORDER BY id";
cmd.CommandTimeout = 15; // Saniye, her üretim RPC'sine uygulanan sınır.
cmd.Parameters.Add(new SdpParameter("ilk", 101L));

await using var rows = await cmd.ExecuteReaderAsync();
int okunan = 0;
while (okunan < 100 && await rows.ReadAsync())
{
    long id = rows.GetInt64(0);
    string ad = rows.GetString(1);
    decimal fiyat = rows.GetDecimal(2);
    long stok = rows.GetInt64(3);
    Console.WriteLine($"{id}: {ad}, {fiyat}, stok={stok}");
    okunan++;
}
```

Bu örnekte 100 satır **istemci okuma sınırıdır**. Sunucunun sorgu yürütme maliyetini veya ağda daha önce alınan batch miktarını 100'e sabitlediği iddia edilmez. Orijinal engine SQL'ine desteklenmeyen `LIMIT` veya `OFFSET` eklenmez. Büyük veri üzerinde sorgunun `WHERE` koşulunu iş ihtiyacına göre daraltın, uygun indeksleri kullanın ve sonuç kaynaklarını kapatın. Reader kendi protokol batch'lerini yönetir; uygulamaya uydurma bir `FetchSize` özelliği verilmez.

## Güncelleme

Önceki reader kapsamı kapandıktan sonra aynı açık `db` bağlantısında:

```csharp
await using var guncelle = db.CreateCommand();
guncelle.CommandText = "UPDATE urunler SET stok = stok - :adet " +
                      "WHERE id = :id AND stok >= :adet";
guncelle.Parameters.Add(new SdpParameter("adet", 2L));
guncelle.Parameters.Add(new SdpParameter("id", 9001L));
int degisen = await guncelle.ExecuteNonQueryAsync();
if (degisen != 1)
    throw new InvalidOperationException("Ürün bulunamadı veya stok yetersiz");
```

İsimli `:adet` parametresi SQL'de iki defa kullanılabilir; koleksiyona bir defa eklenir. Sıfır satır etkilenmesi SQL yürütme hatası değildir. İş kuralınız bir kayıt değişmesini gerektiriyorsa bu sayıyı uygulama değerlendirmelidir. Stok güncellemesini sipariş eklemeyle birleştirmek için açık transaction kullanın.

## Silme ve nullable alan

Örnek deneme ürününü silme:

```csharp
await using var sil = db.CreateCommand();
sil.CommandText = "DELETE FROM urunler WHERE id = :id";
sil.Parameters.Add(new SdpParameter("id", 9001L));
Console.WriteLine(await sil.ExecuteNonQueryAsync());
```

Silinecek ürün sipariş kalemlerinde kullanılıyorsa referans bütünlüğü işlemi reddedebilir. İlişkili geçmişin ne zaman saklanacağını veya silineceğini veri modeliniz belirler. Uygulama ekranından bir kaydın kaldırılması her zaman fiziksel DELETE anlamına gelmez.

Nullable bir metin alanını okurken `rows.IsDBNull(index)` kullanın; SQL NULL değeri `DBNull.Value` olarak taşınır. Boş metin, `null` CLR referansı ve SQL NULL kavramlarını uygulama modelinde bilinçli eşleyin.

## Hangi çalıştırma metodu?

`ExecuteReaderAsync` satır sonuçlarını akış halinde okumak içindir. `ExecuteNonQueryAsync` değişiklik komutunun etkilenen kayıt sayısını verir. `ExecuteScalarAsync` ilk sonuçtaki ilk değeri almak için kullanılabilir; değer döndüğünde bunun türünü, satır yokluğunda `null`, SQL NULL durumunda `DBNull.Value` olabileceğini kontrol edin. Metot seçimi transaction politikasını değiştirmez: açık transaction yoksa wire mutation autocommit akışında çalışır.

## Kaynaklar

- [Komut ve parametre uygulaması](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/src/SdpCommand.cs)
- [Reader, batch ve tip dönüşümleri](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/src/SdpDataReader.cs)

