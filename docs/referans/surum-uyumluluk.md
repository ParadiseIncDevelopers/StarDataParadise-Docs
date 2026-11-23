---
title: "Sürüm ve yetenek kapsamı"
slug: "/referans/surum-uyumluluk"
---

# Sürüm ve yetenek kapsamı

**Kaynak inceleme tarihi:** 23 Kasım 2026. Sürüm bilgisi sunucunun `release.json` dosyası ve ilgili SDK kaynaklarıyla eşleştirilmiştir.

Bir ürünü yalnız sürüm numarasıyla tanımlamak, bağlantı yolunu ve etkin modülleri açıklamaz. Aynı Server kaynağında özgün motor, Classic yaması ve uyumluluk servisi bulunduğu için kurulum profilini de kaydedin. Aşağıdaki tablo paket deposu yayımını veya sizin makinenizdeki binary'nin hash'ini doğrulamaz; incelenen kaynak görünümünü belirtir.

| Bileşen | Kaynak sürümü |
| --- | --- |
| Server | 0.5.2, stable |
| Workbench | 0.3.1 |
| Classic tabanı | Kaynakta 26.10.0 olarak belirtilir |
| Python SDK | 0.3.0 |
| Node.js SDK | 0.2.0 |
| Java JDBC | 0.3.0 |
| .NET Drive | 2.1.0 |
| .NET Framework SDK | 2.0.0 |
| C/C++ Native SDK | 0.4.1, C ABI 1 |

CLI'ın kaynak derlemesinde sabit Native SDK 0.4.0, Workbench'te 0.4.1 kullanılması kaynak README'lerinde ayrı belirtilir. Ürün ailesindeki bütün bileşenlerin aynı sürüm numarasını taşıması beklenmez.

## Destek açıklamasını nasıl okuyacaksınız?

| Özellik | Bu kitapta ele alınışı |
| --- | --- |
| SQL ve PL/SQL | Özgün motor eğitimi ve ayrıca etiketli Classic/native kapsamı |
| AI/Knowledge | Native bağlantı, uygun katalog/worker ve capability koşullarıyla |
| Özgün History v1 | Mevcut wire RPC/kaynak sözleşmesi |
| Özgün jobs v1 | Mevcut iş/takvim RPC/kaynak sözleşmesi |
| Yeni SQL HIST/Git | Release metadata'sında ertelenmiş |
| Yeni public SQL JOB | Release metadata'sında ertelenmiş |
| Classic kısa SQL/PLSQL uzantıları | Kendi native dil profili ve kaynak sözleşmesi; özgün grammar'a genellenmez |

Önceki geliştirme raporları farklı tarihlerdeki PASS, RED veya NOT_RUN sonuçlarını birlikte içerebilir. Bir belgenin erken bölümünü okuyup sonraki düzeltmeleri yok saymak da, son bir testi bütün özelliklere genellemek de doğru değildir. Bu kitap ürün README/release bilgisini başlangıç noktası alır; komut davranışını ilgili grammar, sürücü kaynağı ve test kaynağıyla karşılaştırır.

## Yayımlanan API ile kullanılan backend

Bir SDK'nın tüm metodları her backend üzerinde çalışmayabilir. Örneğin temel wire köprüsü DDL ve bileşik değerleri özgün `sql_crud_v1` kapsamıyla sunmaz. Native SQL aktarımı açık diye bütün AI/Knowledge/Action modülleri de açık değildir. Kullanılacak özellik için ilgili capability ve hesap izni birlikte gerekir.

Uygulamanın açılışında gereksinimleri açık denetleyin. Eksik capability varsa kullanıcıya somut bir yapılandırma hatası gösterin; rastgele alternatif SQL göndererek özelliği tahmin etmeye çalışmayın. Bir modül yoksa bütün hizmeti çalışamaz yapmak yerine, iş ihtiyacına göre o özelliğin arayüzünü kapatmak tercih edilebilir.

## Bu dokümanın doğrulama düzeyi

Belge hazırlanırken kaynak dosyalar ve gerçek SDK API'leri incelendi. Paket içinde Markdown bağlantıları, navigasyon, kod blokları ve uygun bağımsız örneklerin sözdizimi denetlendi. Canlı StarDataParadise/Windows kurulumu, dış AI sağlayıcı çağrısı veya bütün SDK'ların paketle derleme testi bu çalışmanın parçası değildir. Kaynaktaki kabul sonuçları, bu dokümantasyon çalışmasında yeniden yapılmış test diye sunulmaz.

Dağıtım kabulünde kendi binary, katalog ve SDK paketlerinin eşleşmesini doğrulayın. Eğitim betikleriyle tablo/seed doğrulamasını yapın; ardından kendi uygulama hesabınızla okuma, yazma, rollback ve hata davranışını gözlemleyin. Doküman güncellendiğinde [kaynak kayıtları](kaynaklar.md) incelenen commit'leri gösterir.

## Kaynaklar

- [StarDataParadiseServer / release.json](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/release.json)
- [StarDataParadiseServer / README.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/README.md)
- [StarDataParadiseServer / contracts/sql/native-sql-v1.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/contracts/sql/native-sql-v1.md)
- [StarDataParadiseServer / compatibility/wire_v1/README.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/compatibility/wire_v1/README.md)
- [StarDataParadiseServer / compatibility/upstream/sql-short-native.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/compatibility/upstream/sql-short-native.md)
- [StarDataParadiseDLLler / README.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseDLLler/blob/3199235c9641733332e9b8c82f9e875170c4eedb/README.md)
