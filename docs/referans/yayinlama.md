---
title: "Docusaurus ve GitHub Pages yayın rehberi"
slug: /referans/yayinlama
---

# Dokümantasyonu düzenleme ve GitHub Pages’e yayımlama

Bu proje **Docusaurus 3.10.2** ile hazırlanır. Kaynak dosyalar `main` dalında tutulur; site yerel bilgisayarda derlenir ve oluşan statik dosyalar `gh-pages` dalından yayımlanır. Projeye özel bir GitHub Actions iş akışı eklenmez.

## Dosyaların görevleri

| Konum | İçerik ve düzenleme biçimi |
| --- | --- |
| `docs/` | Türkçe Markdown sayfaları; ürün, SQL, veritabanı, SDK ve işletim açıklamaları burada düzenlenir. |
| `sidebars.js` | Sol menünün bölüm ve sayfa sırası. Yeni sayfa eklerken bu kaydı da güncelleyin. |
| `static/downloads/` | Okuyucuların indirebildiği örnek SQL ve uygulama kaynakları. Dosya yolunu değiştirirseniz sayfadaki bağlantısını da değiştirin. |
| `static/.nojekyll` | Derlenmiş dosyaların GitHub Pages üzerinde Jekyll tarafından yeniden işlenmesini engeller. Derleme çıktısının köküne kopyalanır. |
| `docusaurus.config.js` | Site adresi, tema, arama ve yayımlama ayarları. |
| `package.json`, `package-lock.json` | Komutlar ve sabitlenmiş bağımlılıklar. İkisini birlikte sürüm kontrolünde tutun. |
| `build/` | Derleme çıktısı. İçindeki dosyaları elle düzenlemeyin; sonraki derleme bu değişiklikleri yeniler. |

Bir sayfadan diğerine bağlantı verirken mevcut göreli `.md` bağlantı düzenini kullanın. SDK sürümü veya örneği değişiyorsa ilgili açıklama, indirilebilir dosya ve kaynak atfını birlikte güncelleyin. Derlemenin başarılı olması, SQL/SDK örneklerinin canlı StarDataParadise üzerinde sınandığı anlamına gelmez.

## Yerel kurulum ve önizleme

**Node.js 22 veya üstü**, npm ve Git kullanın. Komutları deponun `main` dalındaki kök dizininde çalıştırın.

```bash
npm ci
npm run start
```

`npm ci`, bağımlılıkları kilit dosyasındaki sürümlerle kurar. Geliştirme önizlemesi Markdown değişikliklerini hızlıca görmek içindir. İlk bağımlılık kurulumu internet bağlantısı ister; site derlemek için GitHub ödeme bilgisi, StarDataParadise hesabı veya AI sağlayıcı anahtarı gerekmez.

Yayımlanacak sürümü kontrol etmek için geliştirme sunucusunu durdurup şu komutları sırayla çalıştırın:

```bash
npm run build
npm run serve
```

`npm run build` başarılı tamamlanmadan yayımlamayın. `npm run serve` ile terminalde verilen yerel adresi açın. Ana sayfayı, SDK menülerini, Mermaid şemalarını ve örnek indirme bağlantılarını inceleyin. Yerel aramanın indeksi üretim derlemesinde oluşur; aramayı bu önizlemede deneyin. Yalnızca `npm run start` sonucuna bakarak aramanın bozuk olduğuna karar vermeyin.

## GitHub Pages ayarı

Hedef depo: [ParadiseIncDevelopers/StarDataParadise-Docs](https://github.com/ParadiseIncDevelopers/StarDataParadise-Docs).

`gh-pages` dalı oluşturulup derleme çıktısı yüklendikten sonra **Settings → Pages** bölümünde şu değerleri seçin:

| Alan | Değer |
| --- | --- |
| Source | **Deploy from a branch** |
| Branch | **gh-pages** |
| Folder | **/(root)** |

**Save** ile kaydedin. `gh-pages` kökünde `index.html`, statik dosyalar ve `.nojekyll` bulunmalıdır; çıktıyı fazladan bir `build/` alt klasörüne koymayın. Kaynak `docs/` klasörü Pages’in yayımlama klasörü olarak seçilmez.

Yapılandırmadaki hedef değerleri şöyledir:

```js
url: 'https://paradiseincdevelopers.github.io',
baseUrl: '/StarDataParadise-Docs/',
organizationName: 'ParadiseIncDevelopers',
projectName: 'StarDataParadise-Docs',
deploymentBranch: 'gh-pages',
```

Bu ayarlarla hedef adres [https://paradiseincdevelopers.github.io/StarDataParadise-Docs/](https://paradiseincdevelopers.github.io/StarDataParadise-Docs/) olur. Sayfa yollarında ve indirme bağlantılarında repo adının büyük/küçük harflerini koruyun.

## Sonraki güncellemeleri elle yayımlama

Önce Markdown değişikliklerini `main` dalına commit edip gönderin. `main` dalına gönderim tek başına canlı siteyi güncellemez; yeni statik çıktının da `gh-pages` dalına gönderilmesi gerekir.

Bu projedeki `npm run deploy` komutu Docusaurus’un `docusaurus deploy` aracını çağırır. Araç siteyi yeniden derler ve çıktıyı ayarlanan yayımlama dalına gönderir. Komutu kaynak dosyaların bulunduğu `main` dalından çalıştırın. Bu gönderim için depoya yazabilen bir GitHub hesabının **önceden yapılandırılmış SSH erişimi** gerekir; SSH anahtarını veya başka bir parolayı dokümanlara eklemeyin.

**Bash / Git Bash:**

```bash
USE_SSH=true npm run deploy
```

**PowerShell:**

```powershell
$env:USE_SSH = 'true'
npm run deploy
Remove-Item Env:USE_SSH
```

Gönderimden sonra Pages bölümündeki yayımlama durumuna bakın ve canlı adreste değiştirdiğiniz bir sayfayı açın. Eski içerik görünürse yayımlamanın tamamlandığını kontrol edip tarayıcıyı yenileyin. Stil veya bağlantı hatası varsa `baseUrl` ile Pages dal/klasör ayarını karşılaştırın.

## Actions ekranında neden kayıt görünebilir?

Bu düzen `.github/workflows/` altında özel bir derleme veya yayımlama dosyası kullanmaz. Ancak GitHub, **daldan yayımlanan Pages sitelerini de kendi dahili dağıtım işlemiyle** sunar; bu nedenle Actions ekranında bir Pages kaydı görünebilir. GitHub’ın güncel belgesine göre Pages için standart çalıştırıcı kullanımı ücretsizdir. Public depolarda Pages, GitHub Free ile kullanılabilir; bu kurulum için ücretli bir Actions aboneliği gerekmez.

## Resmî başvuru belgeleri

- [Docusaurus 3.10.2 — Deployment](https://docusaurus.io/docs/3.10.2/deployment): yerel derleme, önizleme, `docusaurus deploy`, SSH seçeneği ve `.nojekyll`.
- [GitHub — Pages yayımlama kaynağı](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site): dal/klasör seçimi ve GitHub’ın dahili dağıtım işlemi.
- [GitHub — Actions faturalandırması](https://docs.github.com/en/billing/concepts/product-billing/github-actions): Pages için ücretsiz standart çalıştırıcı kapsamı.
