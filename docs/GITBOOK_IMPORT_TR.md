---
title: "GitBook'a aktarma: isteğe bağlı arşiv rehberi"
slug: "/referans/gitbook-aktarim"
---

# GitBook'a aktarma: isteğe bağlı arşiv rehberi

> Bu sayfa önceki GitBook paketinin isteğe bağlı aktarım bilgisini korur. Bu deponun ana yayın yöntemi Docusaurus + GitHub Pages'tir. Güncel adımlar için [yayın rehberine](referans/yayinlama.md) bakın.

Bu paket Türkçe Markdown sayfaları, sıralı `SUMMARY.md`, `.gitbook.yaml`, kaynak kayıtları ve örnek kod dosyaları içerir. Başlangıç sayfası `README.md` dosyasıdır. Kod örneklerini ve sayfa yapısını birlikte taşımak için paketin iç dizinlerini koruyun.

## ZIP ile içe aktarma

GitBook'ın Import akışı çok sayfalı Markdown içeriği için ZIP kabul eder. Yeni bir space oluştururken içe aktarma seçeneğini veya mevcut space'te **Add new → Import pages** akışını kullanıp `StarDataParadise-GitBook.zip` dosyasını seçebilirsiniz. Aktarım sonrasında sayfa sırasını, alt başlıkları ve örnek dosya bağlantılarını inceleyin. GitBook, içe aktarılan biçimleri kendi bloklarına dönüştürebildiği için görünümün kaynakla eşleşmesini ayrıca gözden geçirin. [Resmî içe aktarma rehberi](https://gitbook.com/docs/getting-started/import).

## Git Sync ile düzenli güncelleme

Bu büyüklükteki dokümantasyonu sürekli geliştirecekseniz Git Sync, sayfa dosyaları ve kod örneklerini birlikte yönetmek için uygundur. Paketin içeriğini seçtiğiniz dokümantasyon deposu veya alt dizinine yerleştirin. GitBook'ta **Set up Git Sync** üzerinden doğru depo, dal ve içerik dizinini seçin. İlk eşitlemenin yönü, hazırlanmış bu dosyaları içe almak için **GitHub → GitBook** olmalıdır. Sonraki eşitlemelerin iki yönlü davranışını ekip sürecinizde hesaba katın. [Resmî Git Sync aktarım rehberi](https://gitbook.com/docs/guides/editing-and-publishing-documentation/import-or-migrate-your-content-to-gitbook-with-git-sync).

Kök yapılandırma:

```yaml
root: ./
structure:
  readme: README.md
  summary: SUMMARY.md
```

Bu yapı, paket kökü içerik kökü olarak seçildiğinde kullanılır. Başka bir depo alt dizinine yerleştiriyorsanız Git Sync'in seçtiği dizin ile root ayarının aynı içerik kökünü göstermesini sağlayın.

## Aktarım sonrasında gözden geçirme

Önce açılış sayfasını ve ürün → SQL → veritabanı → SDK sırasını kontrol edin. Her SDK'nın alt sayfalarını, Mermaid diyagramlarını ve kod dil etiketlerini açın. SQL ve proje dosyalarına verilen indirme/kaynak bağlantılarının erişilebilir olduğunu görün. Kaynak GitHub bağlantılarının bir kısmı depo izni gerektirebilir; bu, kendi dokümanınızın erişim ayarından ayrıdır.

Paketi GitBook'a almak ile siteyi yayımlamak ayrı işlemlerdir. Bu teslim dosyaları hazırlar; canlı GitBook space/site oluşturulduğu veya yayımlandığı anlamına gelmez. Yayımlamadan önce space'in hedef kitlesini, navigasyonunu ve örnek dosyaların sunuluşunu GitBook'ta kontrol edin.

## Güncelleme düzeni

Yeni sayfa eklediğinizde dosyayı ve `SUMMARY.md` kaydını birlikte güncelleyin. Dosya adı değişirse ona bağlanan sayfaları da düzeltin. Ürün/SDK sürümü değiştiğinde bağlantı, transaction, veri tipi ve hata örneklerini kaynakla yeniden karşılaştırın. Tek dosyalık okuma sürümü paket sayfalarından üretilmiş bir kolaylıktır; GitBook importu için çok sayfalı ZIP ana teslimdir.
