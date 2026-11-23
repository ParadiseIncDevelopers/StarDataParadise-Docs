---
title: "Dokümantasyon doğrulama kaydı"
slug: "/referans/dogrulama"
---

# Dokümantasyon doğrulama kaydı

**Tarih:** 23 Kasım 2026. Bu kayıt belge ve örnek kaynak kontrollerini anlatır; canlı StarDataParadise kabul raporu değildir.

## İçerik paketinin kaynak kontrolü

| Kontrol | Sonuç ve sınırı |
| --- | --- |
| Navigasyon | 93 içerik sayfası SUMMARY içinde birer kez yer alır; erişilemeyen içerik sayfası yoktur |
| Yerel bağlantılar | Bütün Markdown sayfalarının yerel dosya hedefleri çözümlenir |
| Kod blokları | Açılış/kapanış sınırları dengelidir |
| İçerik yapısı | İlk Markdown paketindeki README ve SUMMARY ilişkileri kontrol edilmiştir; web yayını Docusaurus yapısına dönüştürülür |
| SQL veri kümesi | 4 müşteri, 4 ürün, 4 sipariş ve 6 kalem; toplamlar Decimal ile hesaplanmıştır |
| Beklenen tutarlar | Sipariş toplamı 9950.00; tamamlanan siparişler 7600.00; kalemler başlıklarla eşleşir |
| Node.js / Python | 42 kod bloğu ve 8 bağımsız örnek dosyası sözdizimi kontrolünden geçmiştir |
| C / C++ | İki tam örnek gerçek SDK başlıklarıyla C11/C++20 syntax-only kontrolünden geçmiştir |
| Java / .NET | API imzaları, proje dosyaları, transaction akışı, exact fiyat hesabı ve schema uyumu kaynakla incelenmiştir |
| Belirsiz işlem örnekleri | Java/.NET konsolları token ve sipariş kimliğini stderr'e yazar, kod 7 ile biter; SQL'i yeniden göndermez |
| Kaynak atıfları | Repo bağlantıları incelenen commit'e sabitlenmiş; kaynak envanteri arşivde verilmiştir |
| Arşiv | Dosya hash manifesti ve ZIP bütünlüğü teslim sırasında kontrol edilir |

## İncelemede düzeltilen önemli noktalar

Yeni ham Server instance'ında bootstrap sonrasında storage başlatma adımı eklendi. Bu adım olmadan başarılı ağ bağlantısı SQL'in kullanılabilir olduğunu göstermiyordu. Özgün ve native SQL profilleri ayrıldı; LIMIT, transaction komutu ve adlandırma varsayımları iki yola birlikte uygulanmadı. Primary key ile sorgu erişim indeksi arasındaki ürüne özgü fark açıklandı.

SDK varsayılan transaction kipleri ve wire/native parametre biçimleri ayrı tablolara işlendi. Python native context manager'ının ek commit etkisi AI örneğinde önlendi. Java/.NET sipariş projelerinin konsol girişleri, belirsiz commit token'ını kaybetmeyecek şekilde tamamlandı. Knowledge NULL kuralları ve onaylı action profilinin FK sınırlaması açıklaştırıldı.

## Yapılmayan kontroller

Bu ortamda Windows Server, Classic motor veya canlı AI worker çalıştırılmadı. SQL dosyaları canlı StarDataParadise'a uygulanmadı. OpenAI/Claude anahtarı kullanılmadı ve GGUF inference başlatılmadı. C/C++ kontrolü Windows link/DLL çalıştırması değildir. Java ve .NET derleyici/çalışma zamanı burada bulunmadığı için bu projeler derlenmedi. Kaynak kabul testi dosyalarında görülen PASS kayıtları, bu dokümantasyon işinde yeniden alınmış sonuç diye sunulmaz.

Bu sitenin güncellenen kaynakları Docusaurus deposundaki `docs/` dizinidir. Yerel derleme ve GitHub Pages'e aktarım [yayın rehberinde](referans/yayinlama.md) açıklanır. GitBook aktarım sayfası isteğe bağlı arşiv rehberi olarak korunur; bu sitenin yayın yöntemi değildir.

## Docusaurus web sürümü

Özgün 93 içerik sayfası korunmuştur. İçindekiler ve GitHub Pages yayın rehberiyle bu web sürümü 95 dokümantasyon sayfası içerir. 26 bağımsız örnek dosyası ve toplu örnek ZIP’i `static/downloads/` altında tutulur.

Derleme, eksik Markdown ve sayfa bağlantılarında hata verecek şekilde yapılandırılmıştır. Mermaid diyagramları ve Türkçe/İngilizce yerel arama siteye dahildir. Kaynaklar `main`, derlenmiş statik çıktı `gh-pages` dalında yönetilir; projeye özel bir Actions iş akışı bulunmaz.
