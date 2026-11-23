---
title: "Alt sorgular, CTE ve UNION"
slug: "/sql/alt-sorgu-cte"
---

# Alt sorgular, CTE ve UNION

**Kapsam:** original wire v1 SQL; bağımsız alt sorgular, recursive olmayan CTE ve UNION.

Bir sorgunun sonucunu başka bir sorgunun parçası olarak kullanmak, karmaşık bir soruyu daha küçük sorulara ayırmayı sağlar. Bu bölümdeki destek sınırı önemlidir: incelenen motor bağımsız, yani dış sorgunun satırına başvurmayan alt sorguları destekler. Genel SQL eğitimlerinde görülen bütün correlated subquery biçimlerini bu profile taşımayın.

## Tek değer döndüren alt sorgu

En yüksek fiyatlı ürünü bulalım:

~~~sql
SELECT id, ad, fiyat
FROM public.urunler
WHERE fiyat = (SELECT MAX(fiyat) FROM public.urunler)
ORDER BY id;
~~~

Başlangıçta Monitör gelir. Aynı en yüksek fiyatta iki ürün olsa ikisi de döner. Bu, “en pahalı bir ürünü rastgele seç” davranışı değil, maksimum değere eşit olan bütün ürünleri bulma davranışıdır.

Skaler alt sorgu tek sütun ve en fazla bir satır üretmelidir. Birden çok satır değer yerine kullanılamaz; sıfır satır NULL sonucuna yol açabilir. MAX gibi bir aggregate bu örnekte tek değer üretmek için uygundur.

## EXISTS

~~~sql
SELECT id, ad
FROM public.musteriler
WHERE EXISTS (
    SELECT id
    FROM public.siparisler
    WHERE durum = 'hazirlaniyor'
)
ORDER BY id;
~~~

Bu alt sorgu dış müşteri satırına bağlı değildir. Hazırlanan herhangi bir sipariş varsa bütün müşteriler seçilir. Başlangıçta dört müşteri gelir.

Bu örnek özellikle bir yanılgıyı gösterir: sorgu “hazırlanan siparişi olan müşteriler” dememektedir. O soruyu yanıtlamak için JOIN ve gerektiğinde DISTINCT kullanın:

~~~sql
SELECT DISTINCT m.id, m.ad
FROM public.musteriler AS m
JOIN public.siparisler AS s ON s.musteri_id = m.id
WHERE s.durum = 'hazirlaniyor'
ORDER BY m.id;
~~~

Sonuç yalnız müşteri 1'dir.

## CTE ile ara sonucu adlandırmak

CTE, WITH ifadesinde tanımlanan sorgu kapsamındaki ara sonuçtur:

~~~sql
WITH tamamlanan AS (
    SELECT id, musteri_id, toplam
    FROM public.siparisler
    WHERE durum = 'tamamlandi'
)
SELECT musteri_id, SUM(toplam)
FROM tamamlanan
GROUP BY musteri_id
ORDER BY musteri_id;
~~~

CTE bir tabloyu kalıcı olarak oluşturmaz. İfade bittikten sonra `tamamlanan` adı ayrı bir sorguda kullanılamaz. Adlandırma sorgunun niyetini açıklar; otomatik performans kazancı garantilemez.

İncelenen gramer recursive CTE ve `WITH x(a,b) AS ...` biçimindeki açık CTE sütun listelerini kabul etmez. Örnekte bu nedenle sütun adları iç SELECT'ten alınır. Sorgu başına sekiz CTE ve on iki iç içe sorgu seviyesi sınırı belirtilmiştir. Bu sınırları hedefleyerek karmaşıklığı büyütmek yerine okunabilir sorgular tasarlayın.

## UNION ve UNION ALL

~~~sql
SELECT musteri_id
FROM public.siparisler
WHERE durum = 'hazirlaniyor'
UNION
SELECT musteri_id
FROM public.siparisler
WHERE durum = 'tamamlandi'
ORDER BY musteri_id;
~~~

UNION aynı sonuç satırlarını tekilleştirir; burada müşteri 1 ve 2 döner. UNION ALL yazıldığında tekrarlar korunur ve müşteri 1 iki kez görünür.

Birleşen sorgular aynı sayıda ve uyumlu tiplerde sütun üretmelidir. İkinci sorguya müşteri adını eklemek, ilk sorgunun yalnız kimlik üretmesiyle uyumlu değildir. ORDER BY birleşik sonuca uygulanır; her parça için ayrı bir sayfalama davranışı varsaymayın.

## Ne zaman hangisini seçmeli?

JOIN ilişkili kayıtlardan sütunlar getirirken, bağımsız skaler alt sorgu tek karşılaştırma değeri sağlar. CTE uzun bir sorguyu isimlendirilmiş adımlara ayırır. UNION ayrı sonuç kümelerini aynı kolon yapısı altında birleştirir. Sorunuzu bu ayrımla ifade etmek, SQL'i daha okunur kılar ve yanlış satır çoğalmasını azaltır.

**Alıştırma:** İptal siparişi bulunan müşteri kimlikleri ile e-postası olmayan müşteri kimliklerini UNION ile birleştirin. Başlangıçta 3 ve 4 döner; 3'ün iki kaynaktan gelmesi tek satır olarak görünmesini engellemez.

**Kaynaklar:** [advanced SELECT kapsamı](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_COMPATIBILITY.md), [CTE/alt sorgu ayrıştırıcısı](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/sql/syntax.cpp), [sorgu testleri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/tests/query_smoke.cpp).
