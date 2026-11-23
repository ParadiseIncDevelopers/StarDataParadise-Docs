---
title: "UPDATE ve DELETE: mevcut veriyi değiştirmek"
slug: "/sql/update-delete"
---

# UPDATE ve DELETE: mevcut veriyi değiştirmek

**Kapsam:** original wire v1 SQL. Bu sayfadaki yazma denemelerini ayrı transaction'da çalıştırıp rollback yapın; diğer sayfaların beklenen sonuçları başlangıç verisini kullanır.

UPDATE var olan satırların belirli sütunlarını değiştirir. DELETE satırları kaldırır. Her iki komutta da WHERE koşulu işlemin kapsamını belirler. Koşul yazılmazsa komutun etkisi bütün tabloya yayılır.

## Önce hedefi görmek

Stok düzeltmesi yapmadan önce hangi kaydı değiştireceğinizi okuyun:

~~~sql
SELECT id, ad, stok
FROM public.urunler
WHERE id = 101;
~~~

Ardından hedef kimliği açıkça kullanın:

~~~sql
UPDATE public.urunler
SET stok = 25
WHERE id = 101;
~~~

Etkilenen satır sayısını kontrol edin. Beklediğiniz tek kayıt yerine sıfır gelirse kayıt silinmiş, kimlik yanlış veya ek bir koşul sağlanmamış olabilir. Çok sayıda satır etkilenmesi ise genellikle WHERE kapsamının beklenenden geniş olduğunu gösterir.

## Göreli güncelleme ve stok koşulu

Bir ürünün iki adet stoktan düşülmesi için:

~~~sql
UPDATE public.urunler
SET stok = stok - 2
WHERE id = 101 AND stok >= 2;
~~~

Başlangıçta stok 20 ise sonuç 18 olur. `stok >= 2` koşulu yetersiz stokta sıfır satır değiştirilmesini sağlar. İşlem sonucu bir satır değilse sipariş akışına devam etmeyin. Aynı transaction içinde sipariş ve kalemleri oluşturuyorsanız başarısız stok güncellemesi bütün işin rollback nedeni olmalıdır.

Ayrı SELECT ile stok okumak yararlıdır; ancak tek başına bir iş kuralı garantisi değildir. Yazma anında koşulu UPDATE içine de koymak, kararın veriyi değiştiren ifadeyle birlikte uygulanmasını sağlar. Tablo düzeyindeki `CHECK (stok >= 0)` ek bir bütünlük denetimidir.

## Beklenen önceki duruma göre geçiş

~~~sql
UPDATE public.siparisler
SET durum = 'tamamlandi'
WHERE id = 1001 AND durum = 'hazirlaniyor';
~~~

Bir satır değiştiğinde beklenen durum geçişi gerçekleşmiştir. Sıfır satır, “sipariş yok” ile “sipariş artık hazırlanmıyor” durumlarını tek başına ayıramaz; uygulama uygun ek okuma yapabilir. Ancak sonucu yanlışlıkla başarı diye sunmamalıdır.

Güncellemenin aynı request ile ikinci kez denenmesi de sıfır satır üretebilir. Bu durum, kayıp commit cevabının güvenli biçimde çözüldüğü anlamına gelmez. Önce [transaction outcome](transaction.md) akışını izleyin.

## İlişkili satırları silmek

`siparis_kalemleri` tablosu `siparisler` tablosuna bağlıdır. Siparişin kalemleri dururken başlığını silmeye çalışmak FK nedeniyle reddedilir. Original motorun doğrulanmış davranışında CASCADE yoktur; bağımlıları uygulama kontrollü biçimde siler:

~~~sql
DELETE FROM public.siparis_kalemleri
WHERE siparis_id = 1004;

DELETE FROM public.siparisler
WHERE id = 1004;
~~~

Bu iki ifade aynı transaction içinde yürütülmelidir. Aksi halde ilk adım kalıcılaşır, ikinci adım hata verirse eksik bir iş durumu oluşabilir. Silme sırası, oluşturmanın tersidir: önce çocuk, sonra ebeveyn.

İş kayıtlarını fiziksel olarak silmek yerine `durum = 'iptal'` gibi bir durum geçişi kullanmak bazı ürün akışlarına daha uygundur. Bu bir ürün tasarımıdır; History veya backup varlığı, uygulamanın denetim ve raporlama gereksinimlerinin yerine otomatik olarak geçmez.

## DELETE, TRUNCATE ve DROP

| Komut | Etki | Ne zaman düşünülür? |
| --- | --- | --- |
| DELETE ... WHERE | Seçili satırları kaldırır | İş kurallı kayıt silme |
| DELETE (koşulsuz) | Bütün satırları kaldırır | Kontrollü veri temizliği |
| TRUNCATE TABLE | Tablonun verisini topluca boşaltır | Test/bakım amaçlı boşaltma |
| DROP TABLE | Tablo nesnesini kaldırır | Şemadan nesne çıkarma |

TRUNCATE/DROP original motorda DDL History yolunu kullanır; normal DML satır trigger'larının her satır için çalışacağı varsayılmaz. FK, view ve diğer bağımlılıklar ayrıca değerlendirilir.

## Alıştırma

CLI'da `\begin` ile transaction başlatın, ürün 102'nin stokunu 5 azaltın, aynı transaction'da 45 değerini okuyun, `\rollback` çalıştırın ve yeniden okuyun. Son değer 50 olmalıdır. Böylece doğru SQL ile kalıcı değişiklik arasındaki farkı doğrudan gözlemlersiniz.

**Kaynaklar:** [SQL uyumluluğu ve FK davranışı](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_COMPATIBILITY.md), [PL/SQL trigger davranışı](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/PLSQL_LANGUAGE.md), [CLI transaction komutları](https://github.com/ParadiseIncDevelopers/StarDataParadiseCli/blob/95f07c6046662bfc3a49dc2ccced36898b0db07b/CLI.md).
