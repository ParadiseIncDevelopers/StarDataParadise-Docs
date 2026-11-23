# StarDataParadise Dokümantasyonu

StarDataParadise'ı tanımak, SQL öğrenmek, veritabanı ve tablolar tasarlamak ve SDK'larla uygulama geliştirmek için kapsamlı Türkçe dokümantasyon.

**Site adresi:** [paradiseincdevelopers.github.io/StarDataParadise-Docs](https://paradiseincdevelopers.github.io/StarDataParadise-Docs/)

## İçerik

- StarDataParadise mimarisi, bağlantı profilleri, kurulum, TLS, Workbench ve CLI.
- SQL temelleri, sorgular, veri değiştirme, JOIN, transaction ve PL/SQL.
- Veri modelleme, tablo tasarımı, anahtarlar, ilişkiler, indeksler, yetkiler ve migration.
- Node.js, Python, Java, .NET / .NET Framework ve C/C++ SDK rehberleri.
- 26 indirilebilir SQL, kaynak ve proje dosyası; sipariş ve stok uygulamaları.
- AI, Knowledge, işletim, sürüm uyumluluğu, hata yönetimi ve kaynak kayıtları.

## Yerel geliştirme

Node.js 22 veya üstü gerekir.

```bash
npm ci
npm run start
```

Üretim derlemesi ve yerel önizleme:

```bash
npm run build
npm run serve
```

Türkçe/İngilizce yerel arama indeksi üretim derlemesinde oluşturulur. Dış arama hizmeti veya API anahtarı gerekmez.

## Yayın düzeni

| Dal / konum | Görevi |
| --- | --- |
| `main` | Düzenlenebilir Markdown, yapılandırma, tema ve örnek dosyaları |
| `docs/` | Dokümantasyon sayfaları |
| `static/downloads/` | İndirilebilir örnekler ve kaynak envanteri |
| `gh-pages` | Yerel derlemede üretilen HTML, CSS, JavaScript ve statik dosyalar |

GitHub Pages kaynağı **Deploy from a branch → gh-pages → /(root)** olarak kullanılır. Depoda özel `.github/workflows` dosyası yoktur. `.nojekyll` dosyası, hazır site çıktısının yeniden Jekyll işleminden geçmesini engeller.

Güncellemeleri göndermek için, GitHub SSH erişimi yapılandırılmış bilgisayarda:

```bash
USE_SSH=true npm run deploy
```

PowerShell ve diğer ayrıntılar: [Yayın rehberi](docs/referans/yayinlama.md).

GitHub, dal üzerinden Pages yayınını kendi dağıtım işlemiyle yürüttüğü için Actions ekranında bir Pages kaydı gösterebilir. [GitHub'ın belgesine göre Pages için standart çalıştırıcı kullanımı ücretsizdir](https://docs.github.com/en/billing/concepts/product-billing/github-actions). Bu proje ücretli bir Actions aboneliği veya özel Actions derleme iş akışı gerektirmez.

## Doğrulama kapsamı

İçerik 23 Kasım 2026 tarihli ürün ve SDK kaynaklarına dayanır. Site derlemesi ve bağlantı kontrolü, örneklerin canlı StarDataParadise sunucusunda kabul testi yapıldığı anlamına gelmez. Kaynak sürümleri ve yapılan örnek kontrolleri [doğrulama kaydında](docs/DOGRULAMA.md) bulunur.

## Lisans

Dokümantasyon metinleri ve çevirileri [CC BY 4.0](licenses/CC-BY-4.0.txt),
özgün site kodu ve tüketici uygulama örnekleri [MIT](licenses/MIT.txt)
lisanslıdır. Dokümanları paylaşırken atıf ve lisans bilgisini koruyun,
değişikliklerinizi belirtin; örnek kodlarla MIT bildirimini birlikte taşıyın.

Logo ve marka hakları ile bağlantı verilen Server/SDK ürünlerinin ayrı
lisansları korunur. Kapsam ve atıf örneği:
[LICENSE](LICENSE) · [LICENSING.md](LICENSING.md).
