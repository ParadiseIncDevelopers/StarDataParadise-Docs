---
title: "SDK seçimi ve ortak çalışma kuralları"
slug: "/sdk/"
---

# SDK seçimi ve ortak çalışma kuralları

**Kapsam:** Server 0.5.2 ile ilişkilendirilen SDK kaynak sürümleri. Her rehber kendi API sözleşmesini kullanır.

SDK, bağlantı kurma, parametre iletme, sonuçları dilin türlerine dönüştürme ve hata bilgisini koruma görevlerini üstlenir. Programlama dilinizi seçerken uygulamanın mevcut çalışma ortamını esas alın; aynı işi yalnız bir SDK yapmak zorunda değildir. Ekipler, ortak SQL modelini koruyup farklı hizmetleri farklı dillerde yazabilir.

## Sürücü ailesi

| Rehber | Kaynak sürümü | Çalışma ortamı | Ana programlama arayüzü |
| --- | --- | --- | --- |
| [Node.js](nodejs/01-kurulum.md) | 0.2.0 | Node.js 22+ | Asenkron ESM, `connect` |
| [Python](python/01-kurulum.md) | 0.3.0 | Python 3.12+ | DB-API 2.0, `connect` |
| [Java](java/kurulum.md) | 0.3.0 | Java 17+ | JDBC |
| [.NET](dotnet/kurulum.md) | Drive 2.1.0 | .NET 8 / .NET 10 | ADO.NET |
| [.NET Framework](dotnet/framework-ve-uyumluluk.md) | 2.0.0 | .NET Framework 4.8 | Ayrı paket, ADO.NET ailesi |
| [C/C++](c-cpp/01-kurulum.md) | Native SDK 0.4.1 | Windows x64, C / C++20 | C ABI 1 ve RAII başlığı |

Kaynak sürüm numarası, paketin bütün herkese açık kayıt depolarında yayımlandığını kanıtlamaz. Rehberlerde yerel paket veya doğrulanmış depo akışı ayrıntılandırılır. Java kaynağı Maven Central yayımını henüz bekleyen bir adım olarak belirtir. Kullandığınız paketin gerçekten bu sürüm ve kaynaktan geldiğini doğrulayın.

## Varsayılanları ezberden genellemeyin

| SDK / API | Normal wire parametresi | Varsayılan transaction yaklaşımı | Native SQL bağlantısı |
| --- | --- | --- | --- |
| Node.js `connect` | `:ad` | Manual; yazma sonrası açık commit gerekir | `connectNative`, `?` |
| Python `connect` | `:ad` | Manual; context başarı/hatayı yönetir | `connect_native`, `?` |
| Java JDBC | JDBC `?` | Autocommit varsayılan açık; çok adım için kapatın | `SdpNativeConnection`, `?` |
| .NET ADO.NET | `:ad` | Explicit transaction yoksa autocommit | `SdpNativeConnection`, `?` |
| C/C++ C ABI | `:ad` ve ayrı tipli JSON | Explicit tx API; bağımsız yazmada request token | Bu 0.4.1 başlığında managed SDK native SQL API'siyle eşdeğer arayüz varsayılmaz |

Native SQL oturumunun varsayılan autocommit davranışı normal wire bağlantısından ayrıdır. Ayrıca Python context manager'ının başarıda commit etmesi gibi dil özellikleri, AI turuna istenmeden ek COMMIT göndermemek için bilinmelidir. Native AI örnekleri bu yüzden kendi bağlantı kapatma akışını açık gösterir.

## Her sorgunun yaşam döngüsü

1. İlgili sunucu profiliyle bağlantı açın ve gereken capability'yi kontrol edin.
2. SQL kaynağını sabit tutup kullanıcı değerlerini parametre olarak bağlayın.
3. Sorgu sonucunu tüketin veya kapatın; açık sonuçla aynı bağlantıda başka bir işi başlatmayın.
4. Bir iş birimi birden fazla yazmadan oluşuyorsa aynı transaction içinde yürütün.
5. Kesin başarıda commit sonucunu kaydedin; iş kuralı hatasında rollback yapın.
6. Bağlantı kopması sonucu belirsiz bırakıyorsa işin durumunu sorgulayın; yazmayı otomatik tekrarlamayın.

Bu liste kod biçiminden bağımsızdır. `try/finally`, context manager, try-with-resources ve `using` aynı kaynak yaşam döngüsünü farklı dillerde görünür kılar. Bir kaynağın dispose edilmesi, daha önce cevabı kaybolmuş commit'in geri alındığını kanıtlamaz.

## Örnek veri modelinin kullanımı

SDK sorguları `musteriler`, `urunler`, `siparisler` ve `siparis_kalemleri` tablolarını kullanır. Özgün motor örnekleri `main.public` bağlamına aittir. Native örneklerde `sdp_lab` hazırlanır. Aynı mantıksal verinin bu iki SQL profilinde farklı DDL karşılığı olabilir; kurulum betiklerini doğru yola gönderin.

Uygulama örneklerinde ürün 101 üzerinden stok kontrolü yapılır. Stok azaltmanın WHERE koşulunda `stok >= :adet` benzeri bir koşul bulunması, uygulama ön kontrolü ile gerçek yazma arasında başka isteğin stoğu tüketmesini ele almaya yardımcı olur. Sonuçta etkilenen satır sayısı beklenenden farklıysa transaction tamamlanmamalıdır.

## Rehberler nasıl kullanılmalı?

Seçtiğiniz dilde sırayla kurulum, bağlantı, CRUD, türler, transaction, native SQL, uygulama örneği ve sorun giderme sayfalarını okuyun. Yalnız SELECT örneğini kopyalayarak üretim yazma akışını tamamlanmış saymayın. Veri bütünlüğü, yetki ve işlem sonucu uygulamanın davranışına da bağlanmalıdır.

## Kaynaklar

- [StarDataParadiseServer / release.json](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/release.json)
- [StarDataParadise.SDK.Node / README.md](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/README.md)
- [StarDataParadise.SDK.Python / README.md](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/README.md)
- [StarDataParadise.SDK.Java / README.md](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/README.md)
- [StarDataParadise.SDK.NET / README.md](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/README.md)
- [StarDataParadiseDLLler / README.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseDLLler/blob/3199235c9641733332e9b8c82f9e875170c4eedb/README.md)
