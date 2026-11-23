---
title: "İlk bağlantı ve ilk sorgu"
slug: "/baslangic/ilk-sorgu"
---

# İlk bağlantı ve ilk sorgu

**Kapsam:** Özgün wire v1 motoru ve `StarDataParadiseCLI.exe`.

Bu bölümde küçük bir deneme tablosu oluşturarak SQL komutuyla terminal komutunun farkını ve commit davranışını göreceksiniz. Tam müşteri/sipariş veri kümesi sonraki SQL laboratuvarında hazırlanır. Buradaki `ilk_adim` tablosu o tabloların verisini değiştirmez.

## Bağlanın ve ortamı tanıyın

```powershell
.\StarDataParadiseCLI.exe --host localhost --port 7443 --user local-admin --ca C:\SDP\lab\ca.pem
```

Terminal açıldıktan sonra:

```text
\status
\capabilities
\databases
\tables
```

Bunlar SQL değildir; CLI'ın yerel komutlarıdır. Bir SDK'nın `execute` metoduna `\tables` göndermeyin. SDK üzerinden katalog bilgisi için sürücünün ilgili metadata API'sini kullanın. Terminal isteminde bağlamı ve transaction durumunu gözlemleyin.

## Küçük bir tablo oluşturun

```sql
CREATE TABLE main.public.ilk_adim (
    id BIGINT PRIMARY KEY,
    not_metni TEXT NOT NULL
);
```

`id`, satırı ayırt eden anahtardır. `not_metni` boş SQL değeri olan `NULL` alamaz. Bu komut bir nesne oluşturur; veri eklemez. Aynı komutu yeniden çalıştırırsanız zaten mevcut nesne hatası almanız beklenebilir. Bir tabloya daha önce sahip olup olmadığınızı `\tables` veya `\describe main.public.ilk_adim` ile görün.

## Veri ekleyin ve okuyun

```sql
INSERT INTO main.public.ilk_adim (id, not_metni)
VALUES (1, 'StarDataParadise ile ilk kaydım');

SELECT id, not_metni
FROM main.public.ilk_adim
WHERE id = 1;
```

Beklenen satır:

| id | not_metni |
| ---: | --- |
| 1 | StarDataParadise ile ilk kaydım |

Bu beklenen sonuç verilen başlangıç durumundan türetilmiştir. Terminalde gördüğünüz sütun genişliği veya tipli JSON gösterimi seçtiğiniz çıktı biçimine göre değişebilir. Satır dönmezse yanlış bağlamı, farklı bağlantıyı veya henüz commit edilmemiş yazmayı inceleyin.

## Rollback'in etkisini görün

Aşağıdaki blok CLI komutları ve SQL'i birlikte gösterdiği için `text` olarak işaretlidir:

```text
\begin
UPDATE main.public.ilk_adim SET not_metni = 'Geçici değişiklik' WHERE id = 1;
SELECT id, not_metni FROM main.public.ilk_adim WHERE id = 1;
\rollback
SELECT id, not_metni FROM main.public.ilk_adim WHERE id = 1;
```

Transaction içindeki SELECT kendi değişikliğinizi görür. Rollback sonrası son SELECT ilk metni gösterir. Kalıcı değişiklik istediğinizde ayrı bir transaction'da UPDATE yapıp `\commit` kullanırsınız. Özgün motorun bu CLI akışındaki `\begin` komutunu native SQL'deki `START TRANSACTION` ile aynı metin sanmayın.

## Bir satırı güncellemenin tamamlandığını nasıl anlarsınız?

Uygulama kodunda yalnız exception gelmemesine bakmak yeterli değildir. Beklenen satırın hedeflendiğini, etkilenen satır sayısını ve transaction sonucunu birlikte değerlendirin. `WHERE id = 999` ile güncelleme yaparsanız sıfır satır değişmesi geçerli bir sonuç olabilir; uygulamanın “kayıt bulunamadı” durumunu kendisi ele alması gerekir.

Çok satırlı bir güncellemeden önce aynı WHERE koşuluyla SELECT yapmak hedefi anlamanıza yardım eder. Ancak bu önizleme eşzamanlı değişikliklere karşı kilit veya transaction garantisi sağlamaz. Gerçek iş kuralı yazma koşulunda ve transaction sınırında da korunmalıdır.

## Sonraki çalışma

Şimdi [SQL derslerine](../sql/README.md) geçerek ortak müşteri/ürün/sipariş veri kümesini kurun. İlk tabloyu temizlemek isterseniz yalnız bu denemeye ait olduğundan emin olduktan sonra `DROP TABLE main.public.ilk_adim;` çalıştırabilirsiniz. Asıl uygulama tablolarını aynı şekilde deneme amaçlı silmeyin; şema değişikliği planını veritabanı bölümünde ele alacağız.

## Kaynaklar

- [StarDataParadiseServer / SQL_COMPATIBILITY.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_COMPATIBILITY.md)
- [StarDataParadiseCli / CLI.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseCli/blob/95f07c6046662bfc3a49dc2ccced36898b0db07b/CLI.md)
