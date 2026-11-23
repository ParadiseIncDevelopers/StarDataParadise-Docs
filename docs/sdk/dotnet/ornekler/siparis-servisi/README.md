---
title: "Çalıştırılabilir proje: .NET sipariş servisi"
slug: "/sdk/dotnet/ornekler/siparis-servisi/"
---

# Çalıştırılabilir proje: .NET sipariş servisi

Bu klasör [.NET sipariş servisi bölümündeki](../../uygulama-ornegi.md) tam örneği net8.0 konsol projesi olarak sunar. Ürün fiyatını okur, stoku koşullu azaltır, sipariş başlığını ve kalemini aynı ADO.NET transaction'ında ekler. Çalışması için gerçek paket, Server ve laboratuvar şeması gerekir.

## Önkoşullar

- .NET 8 SDK ve gerekli net8.0 targeting/runtime bileşenleri.
- `StarDataParadiseDrive` 2.1.0 paketini içeren gerçek yerel/kurumsal NuGet kaynağı. SDK deposunun `ci.ps1` akışı paketi `out/packages` altında üretir.
- Wire v1 orijinal engine laboratuvarındaki `main.public.musteriler`, `urunler`, `siparisler` ve `siparis_kalemleri` tabloları.
- SELECT/INSERT/UPDATE izinleri verilmiş kullanıcı, TLS listener ve onu doğrulayan CA PEM dosyası.

`SdpAyarlar.cs` içinde örnek endpoint `127.0.0.1:7443`, sertifika adı `localhost` seçilmiştir. Kendi endpoint'iniz farklıysa bu dosyayı değiştirin. Native `sdp_lab` şemasıyla bu wire örneğini karıştırmayın. Paket eklemek Server'ı veya tabloları kurmaz.

## Proje dosyaları

- `SdpSiparis.csproj`: net8.0 hedefi, nullable kontrolü ve sabit Drive 2.1.0 bağımlılığı.
- `SdpAyarlar.cs`: connection string builder ve ortam değişkenleri.
- `SiparisServisi.cs`: sorgu, koşullu stok güncelleme, sipariş/kalem ekleme ve transaction yönetimi.
- `Program.cs`: komut satırı argümanlarını parse edip servisi çağırır.

## Restore, build ve çalıştırma

PowerShell'de bu proje klasöründen:

```powershell
$env:SDP_NUGET_SOURCE = 'C:/SDP/StarDataParadise.SDK.NET/out/packages'
$env:SDP_CA = 'C:/SDP/certs/ca.pem'
$kimlik = Get-Credential -UserName 'lab_user'
$env:SDP_USER = $kimlik.UserName
$env:SDP_PASSWORD = $kimlik.GetNetworkCredential().Password

dotnet restore SdpSiparis.csproj --source "$env:SDP_NUGET_SOURCE"
dotnet build SdpSiparis.csproj --no-restore
dotnet run --project SdpSiparis.csproj --no-build --no-restore -- 2002 1 101 2
```

Argüman sırası `siparis-id musteri-id urun-id adet` şeklindedir. Restore için paket koordinatının herkese açık NuGet'te bulunacağı varsayılmaz; verdiğiniz kaynağın gerçek 2.1.0 paketini içermesi gerekir. Kaynak modern SDK projesi ek NuGet çalışma zamanı bağımlılığı tanımlamaz; yerel SDK/targeting bileşenlerinin hazır olması yine gereklidir.

Paket bulunamadığında önce `SDP_NUGET_SOURCE` yolunu ve paketin sürümünü kontrol edin. Yanlış hedef framework hatasında net8.0 SDK/targeting pack kurulumunu inceleyin. TLS veya kullanıcı hatası ise build/restore hatası değildir; sunucuya bağlantı aşamasına aittir.

## Beklenen kalıcı değişiklik

Başlangıç verisi değiştirilmemişse ürün 101 fiyatı 750.00 ve stoku 20'dir. Tek başarılı çalıştırma 1500.00 toplam verir; stok 18 olur, 2002 numaralı sipariş ve bağlı kalemi eklenir. Konsolun ondalık ayıracı sistem kültürüne göre nokta veya virgül görünebilir; veritabanı parametresi kesin decimal olarak aktarılır.

Java veya diğer örnekleri daha önce aynı laboratuvarda çalıştırdıysanız mevcut stok değişmiş olabilir. Aynı sipariş ID'sini ikinci kez kullanmak primary key hatasına yol açabilir. Örnek veritabanını otomatik temizlemez; her yeni iş için uygun kimlik belirleyin ve başlangıç durumunu sorgulayın.

## Hata ve belirsiz commit

Ürün bulunamaz veya stok yetersizse işlem başarısız olur. Sonraki INSERT hata verirse aynı transaction'daki stok değişikliği geri alınmalıdır. `SdpException.UnknownOutcome` durumunda işlem kaydedilmiş olabilir; `RequestToken` ile [wire outcome akışını](../../transaction.md) kullanın. Yeni sipariş ID'si üretip aynı işi yeniden göndermek belirsizliği çözmez.

Örnek SQL hatasını üst katmana taşır. Gerçek bir web servisi kullanıcıya ham connection string, SQL veya parola göstermeden uygun yanıt verir ve inceleme için sipariş ID'si/receipt bilgilerini ilişkilendirir.

## Süreç çıkış kodları ve receipt kaydı

| Kod | Anlamı |
| --- | --- |
| `0` | Sipariş transaction'ı başarıyla tamamlandı. |
| `1` | İş kuralı, yapılandırma veya kesin SQL/bağlantı hatası. |
| `2` | Eksik/geçersiz komut satırı argümanı veya geçersiz adet. |
| `7` | Yazma/commit sonucu belirsiz; SQL otomatik tekrar gönderilmedi. |

Belirsiz sonuçta giriş noktası `stderr` üzerine `siparis_id`, `request_token`, hata kodu, SQLSTATE ve varsa correlation ID yazar. Varsayılan exception stack trace'inin token taşımasına güvenilmez. `request_token=<yok>` görünürse receipt sorgulanabilecek token yoktur; uygulama sipariş kimliği ve sunucu kayıtlarıyla durumu incelemelidir. Bu durum da otomatik yeniden gönderme izni değildir.

Build sonrasında uygulamayı doğrudan çalıştırırken yönlendirmeyi **ilk çalıştırmaya** ekleyebilirsiniz. Önceden belirsiz kalan bir siparişi bu komutla yeniden göndermeyin:

```powershell
dotnet .\bin\Debug\net8.0\SdpSiparis.dll 2002 1 101 2 `
  2> .\siparis-2002-receipt.log
$sonuc = $LASTEXITCODE
if ($sonuc -eq 7) { Get-Content .\siparis-2002-receipt.log }
```

Logdaki token'ı aynı hesapla açılan **yeni bağlantıda** `GetOutcomeAsync(token)` çağrısına verin. `committed` siparişin kaydedildiğini doğrular; `unknown` işlemin uygulanmadığını kanıtlamaz. Sipariş kimliğiyle birlikte receipt dosyasını sonuç kesinleşene kadar saklayın. Console giriş noktası hiçbir hata dalında SQL'i ikinci kez çalıştırmaz.

## Doğrulama durumu

Dosyalar dokümandaki tam örnekten çıkarıldı, proje XML'i ve kullanılan sağlayıcı yöntemleri kaynaklarla karşılaştırıldı. Bu dokümantasyon ortamında .NET SDK, hazır NuGet paketi ve çalışan Server bulunmadığından proje burada derlenmedi veya canlı veritabanına karşı çalıştırılmadı. Kendi test ortamınızdaki kabul kontrolü restore, build ve örnek transaction'ı kapsamalıdır.

## Kaynak

- [.NET SDK proje hedefi ve bağımlılıkları](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/src/StarDataParadise.SDK.NET.csproj)
- [SDK derleme ve paket üretme kılavuzu](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/BUILD.md)
