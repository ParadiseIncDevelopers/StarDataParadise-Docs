---
title: ".NET Framework 4.8, uyumluluk ve sorun giderme"
slug: "/sdk/dotnet/framework-ve-uyumluluk"
---

# .NET Framework 4.8, uyumluluk ve sorun giderme

> **Kapsam:** `StarDataParadiseNetFramework` 2.0.0 ve modern Drive 2.1.0 arasındaki uygulama farkları. 1.x node API'siyle aynı sözleşme değildir.

Mevcut bir Windows uygulaması .NET Framework 4.8 üzerinde kalacaksa Framework paketini kullanın. Kaynak kılavuzu Visual Studio 2019 tüketicileri ve Framework 4.8 targeting pack'iyle çalışmayı açıklar. Modern .NET 8/10 paketini bu projeye eklemek hedef framework farkını çözmez.

## Paket ve fabrika kaydı

```xml
<PackageReference Include="StarDataParadiseNetFramework" Version="2.0.0" />
```

NuGet kaynağınızın bu paketi içerdiği doğrulanmış olmalıdır. Doğrudan `SdpConnection` oluşturmak için fabrika kaydı gerekli değildir. Uygulama `DbProviderFactories` üzerinden sağlayıcı arıyorsa `app.config` dosyasının mevcut `<configuration>` öğesi içine şu bölüm eklenebilir:

```xml
<system.data>
  <DbProviderFactories>
    <remove invariant="StarDataParadise.SDK.NET" />
    <add name="StarDataParadise"
         invariant="StarDataParadise.SDK.NET"
         description="StarDataParadise ADO.NET provider"
         type="StarDataParadise.SDK.SdpFactory, StarDataParadise.SDK.NET" />
  </DbProviderFactories>
</system.data>
```

Uygulamanın mevcut `system.data` bölümü varsa ikinci bir bölüm oluşturmak yerine ilgili kaydı düzenleyin. Bu örnek veritabanı hesabını veya parolayı config dosyasına eklemeyi gerektirmez; bağlantı metnini uygulama üretir.

## Framework'e uygun kullanım

Aşağıdaki metot eski C# proje düzenlerine uygun `using` blokları kullanır. `connectionString`, [bağlantı bölümünde](baglanti.md) açıklanan seçeneklerle uygulamanın güvenli ayar katmanında hazırlanır:

```csharp
using StarDataParadise.SDK;

public static class UrunOkuma
{
    public static void Yazdir(string connectionString, long urunId)
    {
        using (var connection = new SdpConnection(connectionString))
        {
            connection.Open();
            using (var command = connection.CreateCommand())
            {
                command.CommandText = "SELECT id, ad FROM urunler WHERE id = :id";
                command.Parameters.Add(new SdpParameter("id", urunId));
                using (var rows = command.ExecuteReader())
                {
                    while (rows.Read())
                        System.Console.WriteLine(
                            rows.GetInt64(0) + " - " + rows.GetString(1));
                }
            }
        }
    }
}
```

Framework paketi TLS 1.2 kullanır. DATE sonuçları modern paketteki `DateOnly` yerine saat dilimi belirtilmemiş `DateTime` olarak sunulur. TIME ve TIMESTAMP hassasiyetini `SdpTime` ve `SdpTimestamp`, kesin decimal'i `SdpDecimal` korur. Savepoint ve async kolaylık metotları somut sağlayıcı tiplerinde bulunur; bir API'nin Framework temel sınıfında bulunmaması, somut `SdpTransaction` üzerinde de bulunmadığı anlamına gelmez.

## 1.x'ten geçiş

Kaynak kılavuzundaki eski 1.0.6 paketi node API'sine dayanır. 2.0 sürümü SQL, parametre, ADO.NET transaction ve isimli yordam sonuçları kullanır. Geçişte önce bir okuma akışını, sonra bir yazma transaction'ını dönüştürün. Eski nesne erişim metodunu isim benzerliğiyle yeni metoda eşlemeyin. Mevcut veriyi kullanacak SQL ve null/type dönüşümlerini açıkça yazın.

Native SQL oturumu modern paket ve Framework paketinde ayrı `SdpNativeConnection` API'siyle bulunur. Framework'te kullanılan C# dil sürümü modern doküman örneğindeki nullable sözdizimi veya `using var` ifadesini desteklemiyorsa eşdeğer eski sözdizimini kullanın; sunucunun SQL sözleşmesi bundan değişmez.

## Sorun giderme tablosu

| Belirti | Kontrol |
| --- | --- |
| NuGet restore başarısız | Paket adı, sürüm ve gerçek paket kaynağı |
| Uygulama paketi yükleyemiyor | net48/modern .NET hedefi ve çalışma zamanı bağımlılıkları |
| TLS hatası | CA zinciri, dosya erişimi, `TLS Name`, doğru listener |
| Unsupported connection option | Desteklenmeyen `Database`, başka sağlayıcının TLS anahtarları |
| Aktif transaction uyarısı | `command.Transaction` doğru `SdpTransaction` nesnesi mi? |
| Açık reader hatası | Sonuç ayrı blokta kapatıldı mı? |
| NULL parametre hatası | `DbType` veya `SqlTypeName` belirtilmiş mi? |
| Decimal/timestamp overflow | Değer CLR tipine kayıpsız sığıyor mu; kesin SDK tipi korunabilir mi? |
| `CommandType.StoredProcedure` hatası | `CommandType.Text` ve `CALL` SQL'i kullanılıyor mu? |
| UnknownOutcome | Aynı kullanıcıyla yeni bağlantıda wire receipt veya native run takibi |

## Yönetim işlemleri

`SdpConnection` üzerinde `GetCapabilitiesAsync`, `GetMetadataAsync`, `GetOutcomeAsync`, `GetHistoryAsync`, `ReadHistoryAsync`, `PredictAsync`, `GetJobAsync` ve yönetim sağlık metotları bulunur. Bunların kullanılabilirliği sunucu capability'lerine ve kullanıcı yetkilerine bağlıdır. Yeni SQL `HIST`/`JOB` komutlarının ertelenmiş olmasıyla mevcut wire History/job API'sini birbirine karıştırmayın.

Bir ORM veya raporlama aracı eklemeden önce onun beklentilerini doğrulayın. ADO.NET sağlayıcısı bulunması Entity Framework migration, çoklu aktif sonuç veya belirli bir üçüncü taraf havuz desteğini kendiliğinden sağlamaz. Önce temel parametreli sorgu ve transaction akışını doğrudan sağlayıcıyla çalıştırıp sonra üst katmanı ekleyin.

## Kaynaklar

- [Framework 4.8 kılavuzu ve 1.x geçişi](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/framework/BUILD.md)
- [Modern .NET kapsamı](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/BUILD.md)
- [Connection yönetim metotları](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/src/SdpConnection.cs)
