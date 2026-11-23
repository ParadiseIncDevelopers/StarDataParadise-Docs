---
title: ".NET SDK: ADO.NET sağlayıcısı ve paket kurulumu"
slug: "/sdk/dotnet/kurulum"
---

# .NET SDK: ADO.NET sağlayıcısı ve paket kurulumu

> **Kapsam:** `StarDataParadiseDrive` 2.1.0 için .NET 8 / .NET 10; `StarDataParadiseNetFramework` 2.0.0 için .NET Framework 4.8. Kaynak kontrolü: 23 Kasım 2026.

StarDataParadise .NET SDK, C# uygulamalarını Server'a bağlayan bir ADO.NET sağlayıcısıdır. Bağlantı için `SdpConnection`, SQL için `SdpCommand`, bağlanan değerler için `SdpParameter` ve satır sonuçları için `SdpDataReader` kullanılır. Bunlar `DbConnection`, `DbCommand` ve `DbDataReader` gibi ADO.NET arayüzlerine dayanır; SDK ek native DLL kurulumu gerektirmez.

Sağlayıcının görevi veri aktarımı ve oturum yönetimidir. İş nesnelerini otomatik tabloya eşleyen bir ORM, migration aracı veya Entity Framework provider olduğu varsayılmamalıdır. Bu rehber SQL'in açıkça yazıldığı uygulama modelini kullanır. Böylece hangi tabloya hangi komutun gönderildiği, transaction'ın nerede başladığı ve hatanın hangi işlemde oluştuğu görünür kalır.

## Doğru paketi seçin

| Uygulamanın hedefi | Paket | Sürüm |
| --- | --- | --- |
| .NET 8 veya .NET 10 | `StarDataParadiseDrive` | 2.1.0 |
| .NET Framework 4.8 | `StarDataParadiseNetFramework` | 2.0.0 |

İki paket aynı hedef framework'e yönelik seçenekler değildir. Eski 1.x node API'sine dayanan bir uygulamada yalnızca paket numarasını yükseltmek yeterli değildir; bağlantı, SQL, parametre ve transaction kullanımı 2.x ADO.NET API'sine taşınmalıdır. Framework farkları [uyumluluk bölümünde](framework-ve-uyumluluk.md) açıklanır.

## Modern bir C# projesi hazırlama

Örneğin .NET 8 konsol uygulamasında:

```powershell
dotnet new console --framework net8.0 --name SdpOrnek
cd SdpOrnek
dotnet add package StarDataParadiseDrive --version 2.1.0 --source C:\SDP\packages
```

`C:\SDP\packages` yerel veya kurumsal dağıtımınızdaki gerçek NuGet kaynağı olmalıdır. Kaynak depo `ci.ps1` akışı paketleri `out/packages` altında üretir. README'de bir paket koordinatının verilmesi, herkese açık NuGet kaynağında yayımlandığının bağımsız doğrulaması değildir. Paket restore hatasında önce kaynağın doğru sürümü içerdiğini kontrol edin.

Proje dosyasında sonuç şu bağımlılığa karşılık gelir:

```xml
<ItemGroup>
  <PackageReference Include="StarDataParadiseDrive" Version="2.1.0" />
</ItemGroup>
```

Sürümü sabitlemek, geliştirme ve dağıtım ortamlarının aynı API'yi kullanmasını kolaylaştırır. Server, SDK, Workbench ve CLI sürüm numaraları birbirine eşit olmak zorunda değildir. Bağlantıdaki gerçek özellik desteği Server'ın capability yanıtıyla belirlenir.

## İsim alanı ve sağlayıcı fabrikası

Kodun başında `using StarDataParadise.SDK;` kullanın. Doğrudan `new SdpConnection(...)` ile çalışabilirsiniz. Uygulama ADO.NET sağlayıcısını invariant name üzerinden buluyorsa modern sağlayıcı için `SdpFactory.Register()` kullanılabilir. Framework uygulamalarındaki `app.config` kaydı ayrıca açıklanır.

Provider fabrikası üzerinden oluşturulan connection string builder, parolanın içinde noktalı virgül gibi karakterler olduğunda bağlantı metnini doğru biçimde kaçışlar. Kullanıcı adı ve parolayı elle birleştirilmiş bir metin içine yapıştırmak yerine builder tercih edin. Builder'ın ürettiği metni loglamak gerekmez.

## Kaynaktan paket üretme

SDK geliştirmek veya paketi kendi dağıtımınız için üretmek istiyorsanız SDK deposunun kökünde kaynak tarafından belirtilen .NET SDK 10.0.402 ile şu akışı kullanın:

```powershell
pwsh -NoProfile -File .\ci.ps1
```

Bu derleme ortamı gereksinimi, tüketici uygulamanın mutlaka .NET 10 üzerinde çalışması gerektiği anlamına gelmez. Modern paket .NET 8 ve .NET 10 hedeflerini destekler; test akışı bu çalışma zamanlarındaki ayrı tüketicileri çalıştırır. Framework tüketicisi için uygun Framework 4.8 ortamı gerekir.

Kaynak testleri paket sınırlarını ve protokol davranışını denetler. Gerçek Server'a bağlanan fixture ayrıca hazırlanır. Bu dokümanda verilen örneklerin sizin makinenizde çalıştırıldığı iddia edilmez; hedef endpoint, sertifika, kullanıcı izinleri ve şema ile yerel kabul kontrolü yapmalısınız.

## İlk çalışan akış

Önce [bağlantı ve TLS](baglanti.md) bölümünde ayarları oluşturun, ardından ürün 101'i okuyan sorguyu çalıştırın. Bağlantı başarılı olduktan sonra [CRUD](crud.md), [tipler](veri-tipleri-ve-yordamlar.md), [transaction](transaction.md) ve [sipariş servisi](uygulama-ornegi.md) sırasını izleyin. AI veya native SQL kullanacaksanız ayrı [native oturum](native-sql-ai.md) bölümüne geçin.

## Kaynaklar

- [.NET SDK README ve paket hedefleri](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/README.md)
- [Modern paket derleme ve kullanım kılavuzu](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/BUILD.md)
- [Framework 4.8 kılavuzu](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/framework/BUILD.md)

