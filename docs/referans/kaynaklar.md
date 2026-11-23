---
title: "Kaynaklar ve doğrulama kaydı"
slug: "/referans/kaynaklar"
---

# Kaynaklar ve doğrulama kaydı

Bu dokümantasyon 23 Kasım 2026 tarihinde aşağıdaki proje kaynakları temel alınarak genişletildi. Bileşenlerin README ve public sözleşmelerinin yanında gerçek bağlantı, parametre, transaction, native SQL ve hata sınıfları incelendi. SQL için grammar, parser ve ilgili kabul testi kaynakları; C/C++ için ABI ve başlıklar karşılaştırıldı.

## İncelenen kaynak sürümleri

| Depo | Commit |
| --- | --- |
| StarDataParadiseServer | [f3cc7b2d3b3b](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/commit/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242) |
| StarDataParadise | [da02adde5ef1](https://github.com/ParadiseIncDevelopers/StarDataParadise/commit/da02adde5ef156ca702e4ed8e88a2d8d4deab6f5) |
| StarDataParadiseCli | [95f07c604666](https://github.com/ParadiseIncDevelopers/StarDataParadiseCli/commit/95f07c6046662bfc3a49dc2ccced36898b0db07b) |
| StarDataParadiseDLLler | [3199235c9641](https://github.com/ParadiseIncDevelopers/StarDataParadiseDLLler/commit/3199235c9641733332e9b8c82f9e875170c4eedb) |
| StarDataParadise.SDK.Node | [74a0d86416b8](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/commit/74a0d86416b89fdc6e9af395edee4576c745b5c0) |
| StarDataParadise.SDK.Python | [2bccf1306e40](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/commit/2bccf1306e401955304f5bd5f9c415250c6a55a4) |
| StarDataParadise.SDK.Java | [10b565b05f9f](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/commit/10b565b05f9f90d75b642ef8ed6aa11b712302d6) |
| StarDataParadise.SDK.NET | [979b3f9905be](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/commit/979b3f9905be3e08a6fac5d85198dd97aa180302) |

## Kanıtı nasıl kullanmalısınız?

Her sayfanın sonunda davranışı destekleyen kaynak bağlantıları vardır. [Kaynak envanteri](pathname:///StarDataParadise-Docs/downloads/SOURCE_MANIFEST.json) incelenen repo sürümlerini ve kaynak kayıtlarını tutar. Dokümantasyonun güncel Markdown dosyaları bu sitenin GitHub deposundadır. Bazı proje depoları erişim yetkisi gerektirebilir; okuyucunun erişememesi sayfanın içerdiği kod örneğini indirmesine engel değildir.

Bir kabul testinin kaynak dosyasını okumak, o testi bu ortamda çalıştırmakla aynı şey değildir. Dokümandaki beklenen sonuçlar ortak seed verisinden hesaplanmıştır. Bağımsız örneklerin yapılabilen sözdizimi kontrolleri ile canlı Server kabulü ayrı raporlanır. Tam kontrol özeti paket içindeki `DOGRULAMA.md` dosyasındadır.

## Örneklerin niteliği

SQL laboratuvarı yeni ve boş eğitim instance'ı içindir. SDK örnekleri gerçek API imzalarıyla hazırlanmış tüketici kodudur; paket binary'leri bu arşivde dağıtılmaz. Bağlantı ve kimlik bilgilerini kendi test ortamınızdan sağlarsınız. Önceden tanımlanmış yordam/model gerektiren kesitler ilgili sayfada önkoşul olarak işaretlenir. AI sağlayıcı çağrısı bu dokümanın üretiminde yapılmadı.

Ana yayın yöntemi Docusaurus ve GitHub Pages üzerinden statik yayındır. Markdown düzenleme, yerel derleme ve dal üzerinden yayın adımları [yayın rehberinde](yayinlama.md) anlatılır. GitBook aktarım rehberi arşiv amacıyla korunur.

## Harici birincil belgeler

- [GitBook — İçerik içe aktarma](https://gitbook.com/docs/getting-started/import)
- [GitBook — Git Sync ile geçiş](https://gitbook.com/docs/guides/editing-and-publishing-documentation/import-or-migrate-your-content-to-gitbook-with-git-sync)
- [OpenSSL 3.5 komut belgeleri](https://docs.openssl.org/3.5/man1/)

Bu kaynaklar GitBook aktarımı ve eğitim TLS hazırlığı içindir. StarDataParadise'a özgü davranışlar genel MySQL veya başka bir sürücünün davranışından çıkarılmamıştır.
