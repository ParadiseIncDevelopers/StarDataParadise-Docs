---
title: ".NET SDK: bağlantı ayarları, TLS ve kaynak yönetimi"
slug: "/sdk/dotnet/baglanti"
---

# .NET SDK: bağlantı ayarları, TLS ve kaynak yönetimi

> **Kapsam:** Drive 2.1.0, .NET 8/10, wire v1 ADO.NET. Örneklerde sunucu TLS endpoint'i `127.0.0.1:7443` olarak kullanılır; kendi kurulumunuzun endpoint'ini uygulayın.

Bağlantı ayarlarını uygulamanın yapılandırma katmanında toplayın. Kullanıcı adı, parola ve sertifika dosyası işletim sistemi ortam değişkenlerinden veya dağıtımınızın gizli bilgi yönetiminden alınabilir. Örnek yalnızca ortam değişkenlerini kullanır. SDK'nın `.env` dosyasını kendiliğinden okuyacağı varsayılmaz.

## Desteklenen connection string anahtarları

| Anahtar | Anlamı |
| --- | --- |
| `Host` | Sunucu adresi; varsayılan `127.0.0.1` |
| `Port` | 1–65535 arası port; varsayılan 7443 |
| `User`, `Password` | Zorunlu hesap bilgileri |
| `TLS Mode` | Varsayılan `Required`; yerel geliştirme için `Disabled` seçeneği |
| `TLS Name` | Sertifikada doğrulanan ad; varsayılan host |
| `CA File` | İsteğe bağlı PEM güven zinciri; verilmezse sistem güven deposu |
| `Timeout` | Bağlantı/taşıma ayarı, saniye; 1–300 arası, wire bağlantısında varsayılan 15 |
| `Pooling` | Varsayılan `false`; wire bağlantılarında isteğe bağlı havuz |

`Database` veya başka bir sağlayıcıdan kopyalanmış `TrustServerCertificate` gibi seçenekler desteklenen listeye dahil değildir. SDK'nın ADO.NET oturumu sabit `main` veritabanını kullanır; `ChangeDatabase()` desteklenmez. Native SQL tarafındaki `sdp_lab` örnekleri ayrı bağlantı ve SQL katmanına aittir.

## Ortak yapılandırma sınıfı

Bu sınıf sonraki .NET örneklerinde kullanılan **uygulama yardımcı sınıfıdır**, SDK'nın hazır bir bileşeni değildir:

```csharp
using System;
using StarDataParadise.SDK;

public static class SdpAyarlar
{
    public static string BaglantiMetni()
    {
        var b = SdpFactory.Instance.CreateConnectionStringBuilder();
        b["Host"] = "127.0.0.1";
        b["Port"] = 7443;
        b["TLS Name"] = "localhost";
        b["CA File"] = Zorunlu("SDP_CA");
        b["User"] = Zorunlu("SDP_USER");
        b["Password"] = Zorunlu("SDP_PASSWORD");
        b["Timeout"] = 15;
        b["Pooling"] = false;
        return b.ConnectionString;
    }

    private static string Zorunlu(string ad)
    {
        var deger = Environment.GetEnvironmentVariable(ad);
        return !string.IsNullOrEmpty(deger)
            ? deger : throw new InvalidOperationException("Eksik ayar: " + ad);
    }
}
```

`Host` ağ yönlendirmesinde kullanılır; `TLS Name` sunucu kimliğini doğrular. Yerel geliştirmede sertifikanın adı `localhost` iken ağ adresi `127.0.0.1` olabilir. Sertifika kimliği ile bağlantı adresinin farklı olması builder'da açıkça gösterilir.

## İlk sorgu

`Program.cs` içinde, `SdpAyarlar.cs` ayrı dosyada olmak üzere:

```csharp
using StarDataParadise.SDK;

await using var db = new SdpConnection(SdpAyarlar.BaglantiMetni());
await db.OpenAsync();

var capabilities = await db.GetCapabilitiesAsync();
Console.WriteLine(capabilities.GetRawText());

await using var command = db.CreateCommand();
command.CommandText = "SELECT id, ad FROM urunler WHERE id = :id";
command.Parameters.Add(new SdpParameter("id", 101L));
await using var rows = await command.ExecuteReaderAsync();
while (await rows.ReadAsync())
    Console.WriteLine($"{rows.GetInt64(0)} - {rows.GetString(1)}");
```

Burada kolon indeksleri **0'dan başlar**. Parametre SQL'de `:id`, koleksiyonda `id` olarak tanımlanır. Sayısal kimliğe `101L` verilmesi `long` tipini açık eder. Sorguyu çalıştırmadan önce laboratuvar tabloları hazırlanmış olmalıdır.

## Async ve yaşam döngüsü

`await using` reader, command ve connection kaynaklarını kapatır. Bir bağlantıda bir açık reader bulunabilir. Aynı bağlantıda sonraki sorgu veya commit çalıştırmadan önce reader kapsamını bitirin. `await` kullanmak, aynı bağlantı üstünde birden fazla komutun paralel gönderilebileceği anlamına gelmez.

Uygulama isteğinin `CancellationToken` değerini `OpenAsync`, `ExecuteReaderAsync`, `ReadAsync` ve diğer async çağrılara taşıyabilirsiniz. Bir yazma isteği iptal edildiğinde veya ağ bağlantısı koptuğunda bunun sunucu değişikliğini kesin olarak geri aldığı varsayılmaz; sonuç yönetimi [transaction bölümünde](transaction.md) anlatılır.

## Havuz ve yerel plaintext modu

`Pooling=true` isteğe bağlıdır. Kaynak kılavuzu havuz dönüşü ve yeniden kullanımda sunucu session reset çağrısını, endpoint/güven/kullanıcı/credential ayrımını belirtir. Her mantıksal bağlantıda yeniden kimlik doğrulama gerekiyorsa havuzu kapalı tutun. Native SQL oturumları `Pooling=true` değerini reddeder.

Yerel ortak listener özellikle açılmışsa `Host=127.0.0.1;Port=3197;TLS Mode=Disabled` ile geliştirme bağlantısı kullanılabilir. Bu ayar yalnızca loopback adresini kabul eder; kullanıcı bilgileri ve SQL o bağlantıda şifrelenmez. Bu modda `CA File` ve `TLS Name` eklenmez. Normal TLS örneğini bu seçenekle değiştirmeniz gerekmez; tercih sunucu listener yapılandırmasıyla eşleşmelidir.

## Kaynaklar

- [Connection string ayrıştırma ve havuz davranışı](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/src/SdpConnection.cs)
- [ADO.NET bağlantı kullanım kılavuzu](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/BUILD.md)

