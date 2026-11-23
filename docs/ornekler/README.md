---
title: "Örnek dosyalar ve çalışma sırası"
slug: "/ornekler/"
---

# Örnek dosyalar ve çalışma sırası

Bu dizin ve SDK bölümlerindeki örnek proje dizinleri, kitabın açıklamalarını dosya halinde uygulamanız için hazırlanmıştır. Ürün binary'leri, SDK paketleri, parolalar, sertifikalar ve yerel model dosyaları bu arşive dahil değildir.

## SQL laboratuvarı

| Sıra | Dosya | Çalıştırılacağı profil |
| --- | --- | --- |
| 1 | [01_sema.sql](pathname:///StarDataParadise-Docs/downloads/ornekler/sql/01_sema.sql) | Özgün wire motor, boş eğitim instance'ı |
| 2 | [02_ornek_veri.sql](pathname:///StarDataParadise-Docs/downloads/ornekler/sql/02_ornek_veri.sql) | Aynı özgün motor; şema sonrası |
| 3 | [03_sorgular.sql](pathname:///StarDataParadise-Docs/downloads/ornekler/sql/03_sorgular.sql) | Özgün motor salt okunur doğrulama |
| 4 | [04_classic_sema.sql](pathname:///StarDataParadise-Docs/downloads/ornekler/sql/04_classic_sema.sql) | Ayrı Classic/native yönetim bağlantısı |
| 5 | [05_classic_ornek_veri.sql](pathname:///StarDataParadise-Docs/downloads/ornekler/sql/05_classic_ornek_veri.sql) | Classic/native şema sonrası |
| 6 | [06_classic_sorgular.sql](pathname:///StarDataParadise-Docs/downloads/ornekler/sql/06_classic_sorgular.sql) | Classic/native salt okunur doğrulama |

İlk üç dosya bir yol, son üç dosya alternatif native laboratuvar yoludur. Altısını aynı wire bağlantısına sırayla göndermeyin. Özgün kurulum için [laboratuvar](../veritabani/laboratuvar.md), native kurulum için [native laboratuvar](../veritabani/native-laboratuvar.md) sayfasını okuyun. Native SDK execute çağrısı başına tek ifade gönderir; çok ifadeli dosyayı tek execute içine koymayın. Her iki kurulum da var olan veriyi sessizce silmek yerine yeni nesneler bekler.

Başlangıç veri kümesinde 4 müşteri, 4 ürün, 4 sipariş, 6 sipariş kalemi vardır. Tüm siparişlerin toplamı 9950.00, yalnız tamamlananların toplamı 7600.00'dır. DML alıştırmalarını commit ettikten sonra başlangıç sonuçlarının değişmesi beklenebilir. Yeni temiz bir çalışma için ayrı instance/şema hazırlamak, mevcut veriyi kontrolsüz DROP etmekten daha açık bir eğitim akışıdır.

## SDK örnekleri

| Dil | Başlangıç/uygulama | Gereksinim |
| --- | --- | --- |
| Node.js | [İlk sorgu](pathname:///StarDataParadise-Docs/downloads/sdk/nodejs/ornekler/ilk-sorgu.mjs), [stok servisi](pathname:///StarDataParadise-Docs/downloads/sdk/nodejs/ornekler/stok-servisi.mjs), [deneme](pathname:///StarDataParadise-Docs/downloads/sdk/nodejs/ornekler/deneme.mjs) | Node 22+, SDK 0.2.0, ortam ayarları |
| Python | [İlk sorgu](pathname:///StarDataParadise-Docs/downloads/sdk/python/ornekler/ilk_sorgu.py), [stok servisi](pathname:///StarDataParadise-Docs/downloads/sdk/python/ornekler/stok_servisi.py), [deneme](pathname:///StarDataParadise-Docs/downloads/sdk/python/ornekler/deneme.py) | Python 3.12+, SDK 0.3.0 |
| Java | [Sipariş projesi](../sdk/java/ornekler/siparis-servisi/README.md) | Java 17+, yerel JDBC 0.3.0 ve Gson |
| .NET | [Sipariş projesi](../sdk/dotnet/ornekler/siparis-servisi/README.md) | .NET 8 hedefi, yerel Drive 2.1.0 |
| C | [Bağlantı ve capability](pathname:///StarDataParadise-Docs/downloads/ornekler/c/main.c), [CMake](pathname:///StarDataParadise-Docs/downloads/ornekler/c/CMakeLists.txt) | Native SDK 0.4.1, Windows x64 |
| C++ | [Rollback ile işlem](pathname:///StarDataParadise-Docs/downloads/ornekler/cpp/main.cpp), [CMake](pathname:///StarDataParadise-Docs/downloads/ornekler/cpp/CMakeLists.txt) | Native SDK 0.4.1, C++20, Windows x64 |

Her dilin kendi bağlantı sayfası gerçek ortam değişkenlerini ve paket kurulumunu açıklar. C/C++ örnekleri `SDP_HOST`, `SDP_PORT`, `SDP_TLS_NAME`, `SDP_CA`, `SDP_USER`, `SDP_PASSWORD` değerlerini bekler. Node/Python helper dosyalarını örnekle aynı dizinde tutun. Uygulama örnekleri gerçek eğitim verisini değiştirebilir; C++ örneği açıklanan INSERT'i rollback ile bitirir.

## Hata akışını da uygulayın

Başarılı okumadan sonra, kontrollü bir duplicate key veya yetersiz stok durumunu deneyin. İş kuralı hatasının rollback ile bittiğini görün. Belirsiz commit kaydı ise normal SQL hatasından ayrı ele alınmalıdır; ilgili SDK'nın outcome rehberini tamamlamadan genel retry katmanı eklemeyin. Kaynak ve doğrulama sınırları [doğrulama kaydında](../DOGRULAMA.md) bulunur.

## Bütün örnekleri indirme

[26 örnek dosyasını ZIP olarak indirin](pathname:///StarDataParadise-Docs/downloads/StarDataParadise-Ornekler.zip). ZIP, Java ve .NET proje dizinleri ile Node.js, Python, C/C++ ve SQL dosyalarının klasör yapısını korur.
