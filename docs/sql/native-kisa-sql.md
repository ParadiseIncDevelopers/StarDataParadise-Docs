---
title: "Native SQL: kısa projeksiyonlar ve ilişkisel akışlar"
slug: "/sql/native-kisa-sql"
---

# Native SQL: kısa projeksiyonlar ve ilişkisel akışlar

**Kapsam:** StarDataParadise native SQL derleyicisindeki `sql_short` dil ailesi. Original wire SQL öğreticisinin sözdizimi değildir. Örnekler [Classic/native laboratuvarını](../veritabani/native-laboratuvar.md) kullanır.

Server kaynak belgesi kısa SQL/PLSQL ailesinin native derleyici ve runtime içinde uygulandığını ve stable kabul kapılarından geçtiğini kaydeder. Bu özellikler istemcide metin yeniden yazımıyla sağlanan bir COMPACT modu değildir. `HIST` ve yeni public SQL JOB'un ertelenmiş olması, bu kısa SQL özelliklerinin de ertelendiği anlamına gelmez. Kurulu Server ve Workbench'in ilgili dil capability'sini bildirdiğini kontrol edin; eski/uyumsuz engine'de yalnızca görünür editör tamamlamasına güvenmeyin.

Bu sayfanın örnekleri kaynak sözleşmesi ve kabul fixture'larından uyarlanmıştır. Bu doküman hazırlanırken canlı Server testleri çalıştırılmamıştır.

## EXCLUDE ve REPLACE

Bütün sütunları alıp stok alanını çıkarmak ve fiyatın gösterim değerini değiştirmek:

~~~sql
SELECT * EXCLUDE(stok) REPLACE(fiyat * 1.20 AS fiyat)
FROM sdp_lab.urunler
ORDER BY id;
~~~

Çıktı `id, ad, fiyat` sırasını korur. Klavye için hesaplanan fiyat sayısal olarak 900.00'dır. Bu SELECT tablo fiyatını güncellemez.

EXCLUDE hedefinin mevcut ve tek anlamlı olması gerekir. Aynı alanı iki kez dışlamak, bütün alanları kaldırmak veya dışlanan alanı REPLACE içinde yeniden hedeflemek hatadır. REPLACE çıktı adını ve konumunu korur; yan yana yazılan değişim ifadeleri birbirinin yeni sonucunu değil özgün giriş sütunlarını okur.

Bir alanı EXCLUDE etmek o alanın yetki kontrolünü atlatmaz. Star genişletmesinde mevcut column ACL kuralları geçerlidir. Hassas alanı okumaya yetkisi olmayan hesabın `SELECT * EXCLUDE(hassas_alan)` kullanması, açık sütun seçimiyle aynı izin davranışını sağlayacak diye varsaymayın.

## QUALIFY: window sonucunu filtrelemek

Müşteri başına en büyük kimlikli sipariş:

~~~sql
SELECT id, musteri_id, durum, toplam
FROM sdp_lab.siparisler
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY musteri_id ORDER BY id DESC
) = 1
ORDER BY musteri_id;
~~~

Başlangıç verisinde siparişler 1003, 1002 ve 1004 seçilir. Kimlik sırası bu laboratuvarın seçim kuralıdır; gerçek uygulamada “en yeni” kavramını tarih/zaman alanıyla tanımlamak gerekebilir.

QUALIFY son window aşamasından sonra; DISTINCT, son sıralama ve LIMIT'ten önce değerlendirilir. Window sonucu üzerinde filtreyi WHERE'e taşıyamazsınız. Belgelenmiş kapsam window içermeyen QUALIFY kullanımını reddeder. SELECT alias'ı ile aynı adlı kaynak sütunu çakışırsa kaynak sütunu önceliklidir; alias adlarını buna göre seçin.

## INSERT BY NAME

Bu biçim hedef sütunları SELECT çıktısının adına göre eşler. Örnek için ayrı bir tablo oluşturun; iki ifadeyi native SDK'da iki ayrı çağrı olarak gönderin:

~~~sql
CREATE TABLE sdp_lab.urun_ozeti (
    id BIGINT PRIMARY KEY,
    etiket VARCHAR(200) NOT NULL,
    fiyat DECIMAL(12,2) NOT NULL,
    stok BIGINT NOT NULL DEFAULT 0
) ENGINE=InnoDB;
~~~

~~~sql
INSERT INTO sdp_lab.urun_ozeti BY NAME
SELECT fiyat AS fiyat, ad AS etiket, id AS id
FROM sdp_lab.urunler;
~~~

SELECT sırası hedef tanımından farklıdır; isimler doğru sütuna bağlanır. Stok çıktıda olmadığından DEFAULT 0 kullanılır. Kaynakta olmayan hedef sütunlar için normal default/NULL kuralları; constraint, trigger ve ACL kontrolleri uygulanır.

BY NAME otomatik upsert değildir. Aynı INSERT'i ikinci kez çalıştırmak PK ihlali üretebilir. ON DUPLICATE KEY UPDATE isteniyorsa ayrıca ve açıkça yazılmalıdır. Bilinmeyen/tekrarlanan çıktı isimleri veya generated sütuna uygunsuz yazma hata olarak değerlendirilir.

## FROM pipeline

~~~sql
FROM sdp_lab.siparis_kalemleri
|> WHERE adet > 0
|> EXTEND adet * birim_fiyat AS satir_toplami
|> AGGREGATE SUM(satir_toplami) AS toplam GROUP BY siparis_id
|> WHERE toplam >= 1000.00
|> ORDER BY toplam DESC, siparis_id;
~~~

Sonuç sırasıyla 1002→6500.00, 1001→1450.00, 1003→1100.00'dır. Her aşama önceki aşamanın çıktı şemasını alır. AGGREGATE sonrasında yalnız grup anahtarları ve aggregate sonuçları bulunur; eski `adet` alanı artık görünür değildir.

Aynı EXTEND aşamasındaki kardeş ifadeler birbirinin yeni alias'ını göremez. Önceki hesaplamayı kullanmak için ikinci EXTEND ekleyin. Aşama sınırında eski tablo alias'ları sona erer; gelen sütunlar `input` stage alias'ıyla erişilebilir.

Sınırlar materialize edilir; WHERE koşulları keyfi biçimde önceki aşamaya taşınmaz. `ORDER BY ... |> LIMIT 2` ile `LIMIT 2 |> ORDER BY ...` aynı anlamı taşımaz. DISTINCT, AGGREGATE ve JOIN eski sıralama taşıyıcısını bırakır; gerekli son sırayı tekrar açıkça belirleyin.

## FULL OUTER JOIN'in sınırı

Native kaynak iki base tablo veya güvenilir tipli Knowledge kaynağı arasında explicit FULL OUTER JOIN kabulünü belgeler:

~~~sql
SELECT m.id, m.ad, s.id
FROM sdp_lab.musteriler AS m
FULL OUTER JOIN sdp_lab.siparisler AS s ON s.musteri_id = m.id
ORDER BY m.id, s.id;
~~~

Deniz'in sipariş tarafı NULL kalır. Destek dilimi sınırlıdır: arbitrary derived/CTE/view operand'ları, multijoin/lateral şekiller, grouping/window/DISTINCT/subquery ve locking read kombinasyonları kabul edilmiş kapsam sayılmaz. Bu örneği genişletmeden önce kaynak sınırlarını kontrol edin.

**Kaynaklar:** [native kısa SQL uygulaması ve final kabul kapsamı](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/compatibility/upstream/sql-short-native.md), [projeksiyon kabul fixture'ı](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/compatibility/tests/sql_short_native_acceptance.py), [QUALIFY/BY NAME/pipeline fixture'ı](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/compatibility/tests/sql_short_relational_acceptance.py), [tarihli bütünleşme kaydı](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/docs/coordination/SQL_SHORT_NATIVE_2026_11_20.md).
