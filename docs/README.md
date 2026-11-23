---
title: "StarDataParadise — Kapsamlı Türkçe Dokümantasyon"
slug: "/"
---

# StarDataParadise — Kapsamlı Türkçe Dokümantasyon

**Veriyi modellemekten ilk SQL sorgusuna, uygulama geliştirmekten işletime kadar adım adım rehber.**

Bu kitap StarDataParadise'ı ilk kez öğrenen bir geliştiricinin ürünün parçalarını tanıması, SQL mantığını kavraması, kendi veritabanını tasarlaması ve seçtiği dilde çalışan bir uygulama geliştirmesi için hazırlandı. Konular aynı örnek işletmenin müşteri, ürün, sipariş ve sipariş kalemi verileri üzerinden ilerler. Böylece bir `JOIN` sorgusunun, tablo ilişkisinin ve SDK'da yazılan transaction'ın aynı iş ihtiyacına nasıl hizmet ettiğini görebilirsiniz.

Belgenin kaynak inceleme tarihi **23 Kasım 2026**; ürün temeli **Server 0.5.2** ve **Workbench 0.3.1**. SDK sürümleri ilgili bölümlerin başında belirtilir. Kaynakta desteklenen davranışlarla tasarım aşamasındaki özellikler ayrı işaretlenmiştir. Bu çalışma sırasında canlı bir StarDataParadise sunucusunda örnekler çalıştırılmadı; söz dizimi ve API'ler ürün belgeleri, başlıklar, sürücü kaynakları ve kabul testi kaynaklarıyla karşılaştırıldı.

## Kitabı nasıl okumalıyım?

| Sıra | Bölüm | Edineceğiniz beceri |
| --- | --- | --- |
| 1 | [StarDataParadise'ı tanıma](baslangic/stardataparadise-nedir.md) | Server, istemci, protokol, motor ve SDK ilişkisini anlamak |
| 2 | [SQL](sql/README.md) | Veriyi seçmek, eklemek, değiştirmek; ilişkili veriden sonuç üretmek |
| 3 | [Veritabanı ve tablolar](veritabani/README.md) | Veri modelini, anahtarları, kısıtları ve değişiklik sürecini tasarlamak |
| 4 | [SDK rehberleri](sdk/README.md) | Node.js, Python, Java, .NET ve C/C++ ile bağlantı ve işlem yönetmek |
| 5 | [AI ve Knowledge](ai/temeller.md) | Yetkili veriyi modele sunmak ve kontrollü araç çağrıları tasarlamak |
| 6 | [İşletim](isletim/guvenlik.md) | Yetkileri, yedekleri, sağlık kontrollerini ve hata çözümünü yönetmek |

İlk kez SQL öğreniyorsanız bu sırayı izleyin. Mevcut uygulamanıza sürücü ekliyorsanız önce bağlantı profillerini, ardından kendi SDK'nızın kurulum, transaction ve hata yönetimi bölümlerini okuyun. Sunucuyu kuracak kişi için Windows kurulumu, güvenlik ve yedekleme sayfaları birlikte bir başlangıç yolu oluşturur.

## Örneklerin kapsamını okuyun

StarDataParadise birden fazla sunucu/bağlantı yolu içerir. Aynı port veya aynı ürün adı, bütün SQL ifadelerinin aynı şekilde çalışacağı anlamına gelmez.

- **Özgün wire v1 motoru:** `StarDataParadiseServer.exe`; SQL eğitimindeki `main.public` bağlamı bu profile aittir.
- **Classic/native SQL:** Classic tabanlı motor ve native SQL bağlantısı; AI/Knowledge örnekleri bu yolu kullanır.
- **Classic'e wire köprüsü:** SDK'nın wire protokolünü Classic'e aktarır; `wire_sql_basic_v1` kapsamı özgün motorun bütün DDL ve tür sistemini kapsamaz.

Sayfa başındaki kapsamı, bağlı sunucunun capability yanıtıyla eşleştirin. Özellikle özgün motordaki üç parçalı nesne adlarını, transaction API'lerini ve türleri Classic'e doğrudan taşımayın. Ayrıntılı seçim tablosu [bağlantı profillerinde](baslangic/baglanti-profilleri.md).

## Uygulamalı çalışmanın düzeni

Örnek veriler gerçek müşteri bilgisi içermez. Kurulum ve seed betiklerini boş bir eğitim instance'ında çalıştırın. Aynı betiği tekrar uygulamadan önce tabloların mevcut durumuna bakın; kitap sessizce var olan veriyi silen bir başlangıç komutu kullanmaz. SQL dersindeki beklenen sonuçlar verilen başlangıç veri kümesine aittir. DML alıştırmaları kalıcılaştırıldıysa sonraki sonuçların değişmesi normaldir.

Her SDK rehberi bağlantı açma ve kapatmayı, parametre bağlamayı, sonuç tüketmeyi, exact sayı türlerini ve transaction sonucunu ayrı ayrı ele alır. Uygulama örneklerinde kullanılan kullanıcı, parola, CA yolu ve adres değerleri sizin ortamınızdan sağlanır. Parola veya sağlayıcı anahtarı doküman içinde sabitlenmez.

## Bu sürümde nereden devam edeceksiniz?

Başlangıç noktası [StarDataParadise nedir?](baslangic/stardataparadise-nedir.md) sayfasıdır. Tüm sayfaların sıralı listesi [içindekilerde](SUMMARY.md), siteyi düzenleme ve yayımlama adımları [yayın rehberinde](referans/yayinlama.md), kaynak sürümleri ise [kaynak kayıtlarında](referans/kaynaklar.md) bulunur.

## Kaynaklar

- [StarDataParadiseServer / README.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/README.md)
- [StarDataParadiseServer / release.json](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/release.json)
