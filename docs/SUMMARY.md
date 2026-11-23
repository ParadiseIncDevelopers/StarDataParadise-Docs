---
title: "İçindekiler"
slug: "/icindekiler"
---

# İçindekiler

## 1. StarDataParadise ve ilk adımlar

* [StarDataParadise — Kapsamlı Türkçe Dokümantasyon](README.md)
* [StarDataParadise nedir?](baslangic/stardataparadise-nedir.md)
* [Mimari ve isteklerin izlediği yol](baslangic/mimari-ve-bilesenler.md)
* [Doğru bağlantı profilini seçmek](baslangic/baglanti-profilleri.md)
* [Yerel eğitim için TLS sertifikaları](baslangic/yerel-tls.md)
* [Windows üzerinde eğitim ortamını hazırlama](baslangic/kurulum.md)
* [İlk bağlantı ve ilk sorgu](baslangic/ilk-sorgu.md)
* [Workbench ile günlük çalışma](araclar/workbench.md)
* [CLI ile sorgu, betik ve otomasyon](araclar/cli.md)

## 2. SQL öğrenme yolu

* [SQL'e giriş ve çalışma biçimi](sql/README.md)
* [SELECT: veriyi okumak](sql/select.md)
* [WHERE, mantıksal koşullar ve NULL](sql/filtreleme-null.md)
* [Sıralama, sonuç parçaları ve sayfalama](sql/siralama-sayfalama.md)
* [INSERT: yeni satır oluşturmak](sql/insert.md)
* [UPDATE ve DELETE: mevcut veriyi değiştirmek](sql/update-delete.md)
* [JOIN: tablolar arasındaki ilişkileri okumak](sql/join.md)
* [GROUP BY, toplulaştırma ve HAVING](sql/gruplama.md)
* [Alt sorgular, CTE ve UNION](sql/alt-sorgu-cte.md)
* [Transaction, commit, rollback ve belirsiz sonuç](sql/transaction.md)
* [PL/SQL: fonksiyon, prosedür ve sunucu mantığı](sql/plsql.md)
* [SQL çalışma seti ve çözümler](sql/alistirmalar.md)

## 3. Veritabanı ve tablolar

* [Veritabanı, schema, tablo ve oturum](veritabani/README.md)
* [Ortak laboratuvarı kurmak](veritabani/laboratuvar.md)
* [Tablo tasarımı ve veri modelleme](veritabani/veri-modelleme.md)
* [Veri tiplerini doğru seçmek](veritabani/veri-tipleri.md)
* [Anahtarlar, ilişkiler ve veri bütünlüğü](veritabani/anahtarlar-kisitlar.md)
* [Index, view, sequence ve identity](veritabani/index-view-sequence.md)
* [Şema değişiklikleri ve migration düzeni](veritabani/migration.md)
* [Kullanıcılar, roller ve tablo yetkileri](veritabani/kullanicilar-roller.md)
* [Sorgu performansı ve kaynak kullanımı](veritabani/performans.md)
* [History, geri yükleme ve Decision kuralları](veritabani/history-decision.md)
* [Original wire SQL ile Classic/native SQL farkları](veritabani/classic-farklari.md)
* [Classic/native laboratuvarını kurmak](veritabani/native-laboratuvar.md)
* [Native SQL: kısa projeksiyonlar ve ilişkisel akışlar](sql/native-kisa-sql.md)
* [Native PL/SQL: LET, kısa gövde ve satır cursor'ı](sql/native-kisa-plsql.md)

## 4. SDK rehberleri

* [SDK seçimi ve ortak çalışma kuralları](sdk/README.md)

## Node.js SDK

* [Node.js SDK: kurulum ve ilk sorgu](sdk/nodejs/01-kurulum.md)
* [Node.js: bağlantı, TLS ve kaynak yaşam döngüsü](sdk/nodejs/02-baglanti.md)
* [Node.js: CRUD ve sorgu sonuçlarını işleme](sdk/nodejs/03-crud.md)
* [Node.js: SQL ve JavaScript veri tipleri](sdk/nodejs/04-veri-tipleri.md)
* [Node.js: transaction, rollback ve belirsiz sonuç](sdk/nodejs/05-transaction.md)
* [Node.js: yordamlar, çoklu sonuçlar ve yönetim API'leri](sdk/nodejs/06-yordam-yonetim.md)
* [Node.js: native SQL ve AI oturumları](sdk/nodejs/07-native-ai.md)
* [Node.js: stok servisi örneği ve sorun giderme](sdk/nodejs/08-uygulama-sorun-giderme.md)

## Python SDK

* [Python SDK: kurulum ve ilk sorgu](sdk/python/01-kurulum.md)
* [Python: bağlantı, TLS ve cursor yaşam döngüsü](sdk/python/02-baglanti.md)
* [Python: CRUD, cursor ve toplu işlemler](sdk/python/03-crud.md)
* [Python: tip dönüşümleri, Decimal ve zaman değerleri](sdk/python/04-veri-tipleri.md)
* [Python: transaction ve belirsiz commit sonucunu çözme](sdk/python/05-transaction.md)
* [Python: yordamlar, çoklu sonuçlar ve yönetim çağrıları](sdk/python/06-yordam-yonetim.md)
* [Python: native SQL ve AI oturumları](sdk/python/07-native-ai.md)
* [Python: stok servisi örneği ve sorun giderme](sdk/python/08-uygulama-sorun-giderme.md)

## Java SDK

* [Java SDK: JDBC ile başlama ve kurulum](sdk/java/kurulum.md)
* [Java SDK: bağlantı, TLS ve oturum yaşam döngüsü](sdk/java/baglanti.md)
* [Java SDK: parametreli CRUD ve sonuç okuma](sdk/java/crud.md)
* [Java SDK: veri tipleri, NULL ve yordamlar](sdk/java/veri-tipleri-ve-yordamlar.md)
* [Java SDK: transaction, savepoint ve belirsiz sonuçlar](sdk/java/transaction.md)
* [Java SDK: native SQL ve AI oturumları](sdk/java/native-sql-ai.md)
* [Java SDK: tek ürünlü sipariş servisi](sdk/java/uygulama-ornegi.md)
* [Çalıştırılabilir proje: Java sipariş servisi](sdk/java/ornekler/siparis-servisi/README.md)
* [Java SDK: uyumluluk, yönetim API'leri ve sorun giderme](sdk/java/uyumluluk.md)

## .NET SDK ve .NET Framework

* [.NET SDK: ADO.NET sağlayıcısı ve paket kurulumu](sdk/dotnet/kurulum.md)
* [.NET SDK: bağlantı ayarları, TLS ve kaynak yönetimi](sdk/dotnet/baglanti.md)
* [.NET SDK: parametreli CRUD ve satır okuma](sdk/dotnet/crud.md)
* [.NET SDK: kesin tipler, NULL ve yordam sonuçları](sdk/dotnet/veri-tipleri-ve-yordamlar.md)
* [.NET SDK: transaction, savepoint ve sonuç uzlaştırma](sdk/dotnet/transaction.md)
* [.NET SDK: native SQL, Knowledge ve AI](sdk/dotnet/native-sql-ai.md)
* [.NET SDK: transaction içinde sipariş oluşturma](sdk/dotnet/uygulama-ornegi.md)
* [Çalıştırılabilir proje: .NET sipariş servisi](sdk/dotnet/ornekler/siparis-servisi/README.md)
* [.NET Framework 4.8, uyumluluk ve sorun giderme](sdk/dotnet/framework-ve-uyumluluk.md)

## C/C++ SDK

* [C/C++ SDK — Paket ve derleme](sdk/c-cpp/01-kurulum.md)
* [C/C++ SDK — Bağlantı ve bellek sahipliği](sdk/c-cpp/02-baglanti-bellek.md)
* [C/C++ SDK — Parametreli SQL ve sonuç okuma](sdk/c-cpp/03-sql-ve-turler.md)
* [C/C++ SDK — Transaction ve belirsiz sonuç](sdk/c-cpp/04-transaction-hatalar.md)
* [C/C++ SDK — Yönetim, History ve işler](sdk/c-cpp/05-yonetim.md)

## 5. Uygulama ve örnekler

* [Uçtan uca sipariş uygulamasını tasarlamak](uygulamalar/siparis-akisi.md)
* [Örnek dosyalar ve çalışma sırası](ornekler/README.md)

## 6. AI ve Knowledge

* [AI ve Knowledge'ın çalışma mantığı](ai/temeller.md)
* [Model, kimlik bilgisi ve worker kurulumu](ai/model-kurulumu.md)
* [Konuşma, prompt ve yapılandırılmış yanıt](ai/konusmalar.md)
* [Knowledge ile veriyi kontrollü sunma](ai/knowledge.md)
* [Araç çağrıları ve onaylanan eylemler](ai/araclar-onay.md)

## 7. İşletim

* [Kullanıcı, rol ve uygulama güvenliği](isletim/guvenlik.md)
* [Yedekleme ve geri yükleme](isletim/yedek-kurtarma.md)
* [Instance, sağlık ve performans gözlemi](isletim/gozlemleme.md)
* [History, Decision ve kalıcı işler](isletim/history-jobs.md)

## 8. Referans ve aktarım

* [Sürüm ve yetenek kapsamı](referans/surum-uyumluluk.md)
* [Hataları teşhis etmek ve sonucu korumak](referans/hatalar.md)
* [Terimler sözlüğü](referans/sozluk.md)
* [Mevcut kapsam ve sonraki özellikler](referans/yol-haritasi.md)
* [Kaynaklar ve doğrulama kaydı](referans/kaynaklar.md)
* [GitBook'a aktarma (isteğe bağlı arşiv)](GITBOOK_IMPORT_TR.md)
* [Dokümantasyon doğrulama kaydı](DOGRULAMA.md)

* [Docusaurus ve GitHub Pages yayın rehberi](referans/yayinlama.md)
