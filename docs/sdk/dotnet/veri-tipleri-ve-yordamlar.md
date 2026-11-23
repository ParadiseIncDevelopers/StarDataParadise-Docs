---
title: ".NET SDK: kesin tipler, NULL ve yordam sonuçları"
slug: "/sdk/dotnet/veri-tipleri-ve-yordamlar"
---

# .NET SDK: kesin tipler, NULL ve yordam sonuçları

> **Kapsam:** Drive 2.1.0 wire değerleri. Framework 4.8 için DATE farkı ayrıca belirtilir; native değerler ayrı sözleşmedir.

Veritabanı değerleri her zaman basit CLR tiplerinin sınırlarına sığmaz. Orijinal wire DECIMAL 38 basamak taşıyabilir; `System.Decimal` tüm bu değerleri temsil edemez. SDK bu nedenle kesinliği koruyan kapsayıcılar sunar. Uygulamanızın alanı dar bir `DECIMAL(12,2)` ise `decimal` yeterlidir; genel amaçlı veri dışa aktarmada ham kesin tipi korumak daha doğru olabilir.

## Tip eşlemesi

| SQL / wire | .NET karşılığı | Açıklama |
| --- | --- | --- |
| BIGINT | `long` | Signed 64 bit |
| BOOLEAN | `bool` | SQL NULL için ayrıca kontrol gerekir |
| TEXT | `string` | Metin |
| BLOB | `byte[]` | İkili veri |
| DECIMAL | `SdpDecimal` | Katsayı + scale, en fazla 38 katsayı basamağı |
| DATE | `DateOnly` | Modern .NET'te takvim günü |
| DATE / Framework 4.8 | `DateTime` | Saat dilimi belirtilmemiş takvim günü |
| TIME | `SdpTime` | Gün içi saat ve nanosaniye |
| TIMESTAMP WITH TIME ZONE | `SdpTimestamp` | UTC saniye, nanosaniye, offset ve isteğe bağlı zone |
| RECORD | `SdpRecord` | İsimli PL/SQL alanları |
| COLLECTION | `SdpCollection` | PL/SQL değer koleksiyonu |
| SQL NULL | `DBNull.Value` | Sonuç okuyucusunda NULL temsili |

`GetFieldValue<SdpDecimal>` kesin decimal değerini verir. `GetDecimal` veya `SdpDecimal.ToDecimal()` dönüşümü kayıpsız sığmazsa hata üretir. Bu davranış özellikle rapor dışa aktarımında sayının sessizce yuvarlanmasını önler.

## Decimal ve timestamp örneği

```csharp
using System.Numerics;
using StarDataParadise.SDK;

var fiyat = SdpDecimal.FromDecimal(750.00m);
Console.WriteLine(fiyat.Unscaled); // 75000
Console.WriteLine(fiyat.Scale);    // 2

var genis = new SdpDecimal(
    BigInteger.Parse("12345678901234567890123456789012345678"), 2);
Console.WriteLine(genis.ToString());
// genis.ToDecimal() CLR decimal kapasitesini aşabilir.

var an = SdpTimestamp.FromDateTimeOffset(DateTimeOffset.UtcNow);
Console.WriteLine(an.Seconds);
```

Bir timestamp'ın görüntüleme offset'i, saklanan an ve adı verilmiş zaman dilimi farklı bilgilerdir. `ToDateTimeOffset()` nanosaniye hassasiyeti veya zone bilgisini kayıpsız taşıyamazsa hata verebilir. Genel dönüştürücüde hata yakalayıp veriyi başka bir zamanmış gibi yazmak yerine kesin kapsayıcıyı veya açık metin temsilini saklayın.

## Tipli NULL bağlama

Sadece `new SdpParameter("eposta", null)` vermek, SQL tipini çıkarmak için yeterli değildir. `DbType` veya `SqlTypeName` belirtin:

```csharp
using System.Data;
using StarDataParadise.SDK;

await using var cmd = db.CreateCommand();
cmd.CommandText = "UPDATE musteriler SET eposta = :eposta WHERE id = :id";
cmd.Parameters.Add(new SdpParameter("eposta", DbType.String)
{
    Value = DBNull.Value
});
cmd.Parameters.Add(new SdpParameter("id", 3L));
await cmd.ExecuteNonQueryAsync();
```

Burada `db` açık bağlantıdır. Sonuçta nullable alanı okuma: `string? eposta = rows.IsDBNull(2) ? null : rows.GetString(2);`. İndeksin sorgudaki sütun sırasına uyduğunu kontrol edin. NULL alanın varlığı kaydın bulunmadığı anlamına gelmez; bu iki durumu uygulamada farklı ele alın.

## PL/SQL CALL ve OUT parametresi

Sağlayıcı `CommandType.Text` kullanır; `CommandType.StoredProcedure` desteklenmez. Yordamı `CALL` SQL'iyle çağırın. Aşağıdaki örnek, önceden tanımlanmış `public.stok_ozeti(IN p_id BIGINT, OUT p_stok BIGINT)` yordamı olduğunu varsayar; laboratuvar bu yordamı kendiliğinden oluşturmaz.

```csharp
using System.Data;
using StarDataParadise.SDK;

await using var cmd = db.CreateCommand();
cmd.CommandText = "CALL public.stok_ozeti(:p_id, NULL)";
cmd.Parameters.Add(new SdpParameter("p_id", 101L));
var cikis = new SdpParameter("p_stok", DbType.Int64)
{
    Direction = ParameterDirection.Output
};
cmd.Parameters.Add(cikis);

await using (var rows = await cmd.ExecuteReaderAsync())
{
    do
    {
        while (await rows.ReadAsync())
            Console.WriteLine(rows.GetValue(0));
    }
    while (await rows.NextResultAsync());
}
Console.WriteLine(cikis.Value);
```

Saf OUT pozisyonunda SQL NULL kullanılır ve isimli output parametresi dönen sütunla eşleşir. IN OUT parametresinde başlangıç değeri bağlanır ve `ParameterDirection.InputOutput` seçilir. Output isimleri gerçek yordam imzasıyla uyumlu olmalıdır.

Autocommit CALL bir sunucu transaction'ı içinde yürür ve sonuç kapandığında tamamlanabilir. Bu nedenle reader'ı erken kapatmak "yordamın yaptığı değişiklikler geri alındı" anlamına gelmez. Veri değiştiren yordamın bir iş akışına katılması gerekiyorsa açık `SdpTransaction` kullanıp komuta atayın; işlemi geri almak için rollback yapın.

## Kaynaklar

- [Kesin wire değerleri](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/src/SdpValues.cs)
- [Parametre tipi ve NULL doğrulaması](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/src/SdpParameter.cs)
- [CALL ve sonuç yaşam döngüsü](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/BUILD.md)
