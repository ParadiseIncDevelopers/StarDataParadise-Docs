---
title: "Sorgu performansı ve kaynak kullanımı"
slug: "/veritabani/performans"
---

# Sorgu performansı ve kaynak kullanımı

**Kapsam:** original wire v1 SQL. Aşağıdaki sayısal sınırlar kaynak belgelerinin tanımladığı profile aittir; Classic/native motorun limitleri yerine kullanılamaz.

Performans çalışmasına “hangi index eksik?” sorusuyla başlamayın. Önce hangi sorgunun ne kadar veri okuduğunu, hangi sonucu ürettiğini ve bağlantının ne kadar süre açık transaction tuttuğunu belirleyin. Küçük bir örnek tabloda hızlı görünen bir sorgu, gerçek iş hacminde aynı maliyeti göstermeyebilir.

## İhtiyacınız olan veriyi isteyin

Bir ayrıntı ekranı için bütün tablonun okunması gereksiz ağ ve bellek kullanımı yaratır:

~~~sql
SELECT id, ad, fiyat
FROM public.urunler
WHERE id = :id;
~~~

BLOB veya büyük TEXT sütunlarını ihtiyaç yokken projeksiyona almayın. Sayfalama yalnız istemci tarafında ilk N satırı göstermekten ibaretse Server daha fazla iş yapmış olabilir. SQL WHERE ile veriyi daraltmak ve sonucu küçük parçalar halinde çekmek farklı katmanlarda fayda sağlar.

## EXPLAIN ve EXPLAIN ANALYZE

~~~sql
EXPLAIN
SELECT id, musteri_id, toplam
FROM public.siparisler
WHERE musteri_id = 1;
~~~

EXPLAIN sorguyu yürütmeden operatör planını verir. Gerçek yürütmenin satır sayısı ve duvar saati süresi için:

~~~sql
EXPLAIN ANALYZE
SELECT id, musteri_id, toplam
FROM public.siparisler
WHERE musteri_id = 1;
~~~

EXPLAIN ANALYZE SELECT'i gerçekten çalıştırır. Büyük bir rapor üzerinde bunu “yalnız metadata okur” diye düşünmeyin. Plan çıktısında SQL metni ve parametre değerlerinin bulunmaması belgelenmiş davranıştır.

Bir planı yorumlarken hangi tabloya tarama yapıldığını, join öncesinde filtre uygulanıp uygulanmadığını ve sonuç büyüklüğünü inceleyin. Her iki planı aynı veri ve benzer çalışma yüküyle karşılaştırın; tek bir hızlı ölçümle genelleme yapmayın.

## İstatistikler ve index

~~~sql
ANALYZE public.siparisler;
~~~

ANALYZE satır tahminlerini günceller; planner bunları eşleşen schema sürümünde kullanır. Bu, verinin kendisini iş kuralı açısından analiz etmez. Toplu yükleme sonrası dağılım değişmişse plan incelemesinin bir parçası olabilir.

~~~sql
CREATE INDEX public.idx_urunler_stok
ON public.urunler (stok);
~~~

Bu komutu sırf örnekte gördüğünüz için eklemeyin. Dört satırda anlamlı fayda beklenmez. Stok koşulunun gerçek veride ne kadar seçici olduğunu ve yazma sıklığını değerlendirin. Her stok güncellemesi ilgili index yapısını da etkileyebilir.

## Join ve aggregate maliyeti

Yanlış ilişki koşulu, hem hatalı rapor hem büyük ara sonuç üretir. Özellikle CROSS JOIN veya birden çoğa ilişkide başlık satırlarının tekrarlanması kontrol edilmelidir. Önce raporun doğru satır düzeyini kurun; sonra hızlandırın.

Original motor uygun equijoin'de hash yolunu, diğer join koşullarında nested loop yolunu kullanabilir. “JOIN var, o halde her zaman index kullanır” varsayımı yapmayın. Çok sütunlu bir index'in oluşturulabilmesi de bütün birleşik koşullar için o index'in seçileceğini garanti etmez.

## Belgelenmiş kaynak sınırları

| Alan | Kaynakta belirtilen sınır |
| --- | --- |
| SQL metni | 64 KiB, 4096 token |
| Sorgudaki JOIN / UNION kolu / CTE | Her biri en çok 8 |
| İç içe sorgu seviyesi | 12 |
| Advanced operatör çalışma bütçesi | Sorgu başına 4 MiB |
| Advanced sonuçta temp kullanımı eşiği | 64 KiB üzeri |
| Advanced sonuç başına temp üst sınırı | 768 KiB |
| Aynı bağlantıda açık sonuç | En çok 1 |

Bu sınırlar “önerilen hedef” değildir. İhtiyaç daha büyük rapor veya uzun iş gerektiriyorsa iş parçasını ve okuma tasarımını değiştirin; başka profile ait bir limit artış seçeneğinin burada var olduğunu varsaymayın.

## Transaction süresi de performanstır

Original motorda exclusive serializable lease nedeniyle uzun transaction diğer oturumların beklemesini artırabilir. HTTP isteği, kullanıcı kararı veya dosya aktarımı sırasında transaction açık bırakmak SQL'in kendisi hızlı olsa bile sistem davranışını bozar.

Sonucu tüketin veya kapatın, transaction'ı bitirin, ardından dış işinizi yapın. Belirsiz commit'i otomatik tekrar denemek performans iyileştirmesi değildir; veri bütünlüğü riski doğurur.

**Kaynaklar:** [planner ve kaynak limitleri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_COMPATIBILITY.md), [sözdizimi sınırları](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/sql/SQL.ebnf), [transaction/sonuç sözleşmesi](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/contracts/sql/SQL_RPC_V1.md).
