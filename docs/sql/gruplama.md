---
title: "GROUP BY, toplulaştırma ve HAVING"
slug: "/sql/gruplama"
---

# GROUP BY, toplulaştırma ve HAVING

**Kapsam:** original wire v1 SQL. COUNT, SUM, AVG, MIN, MAX, GROUP BY ve HAVING desteklenen kapsam içindedir.

Ayrıntı sorguları her kayıt için bir satır gösterir. Toplulaştırma ise birden çok kaydı tek ölçüme dönüştürür: sipariş sayısı, satış tutarı, en yüksek fiyat veya müşteri başına toplam gibi. Doğru rapor için ölçümün hangi satır düzeyine ait olduğunu belirlemek gerekir.

## Bütün tablo üzerinde hesaplama

~~~sql
SELECT COUNT(*), SUM(toplam), MIN(toplam), MAX(toplam)
FROM public.siparisler;
~~~

Başlangıç verisinin mantıksal sonucu sırasıyla 4, 9950.00, 900.00 ve 6500.00'dır. Bu toplam iptal durumundaki siparişi de içerir; bir finansal raporun toplamı olarak kullanılmadan önce iş kuralı belirlenmelidir.

~~~sql
SELECT COUNT(*), SUM(toplam)
FROM public.siparisler
WHERE durum = 'tamamlandi';
~~~

Bu sorgu iki tamamlanmış sipariş ve 7600.00 toplam üretir. “Toplam sipariş tutarı” ifadesinin taslak, iptal veya yalnız tamamlanmış siparişlerden hangisini kapsadığı rapor tanımında açık olmalıdır.

SUM ve AVG, original motorda exact decimal sonuç üretir. SDK'nın bunu yaklaşık kayan nokta sayıya dönüştürmesi hassasiyet kaybettirebilir; para sonucunu uygun decimal türünde taşıyın.

## Müşteriye göre gruplamak

~~~sql
SELECT musteri_id, COUNT(*), SUM(toplam)
FROM public.siparisler
GROUP BY musteri_id
ORDER BY musteri_id;
~~~

| musteri_id | sipariş sayısı | toplam |
| ---: | ---: | ---: |
| 1 | 2 | 2550.00 |
| 2 | 1 | 6500.00 |
| 3 | 1 | 900.00 |

Bu tabloda müşteri 4 görünmez; sorgunun kaynağı sipariş tablosudur ve bu müşterinin sipariş satırı yoktur. Bütün müşterilerin görülmesi için LEFT JOIN gerekir.

## COUNT(*) ile COUNT(sütun)

~~~sql
SELECT m.id, m.ad, COUNT(s.id)
FROM public.musteriler AS m
LEFT JOIN public.siparisler AS s ON s.musteri_id = m.id
GROUP BY m.id, m.ad
ORDER BY m.id;
~~~

Deniz için sayı 0 olur. `COUNT(*)` yazılsaydı LEFT JOIN'in ürettiği “sipariş sütunları NULL” satırı da sayılır ve 1 elde edilirdi. `COUNT(s.id)` yalnız NULL olmayan sipariş kimliklerini sayar.

Benzer biçimde e-posta doluluk oranının ham sayılarını görmek için:

~~~sql
SELECT COUNT(*), COUNT(eposta)
FROM public.musteriler;
~~~

Sonuç dört müşteri ve iki dolu e-posta değeridir. NULL ile boş metni farklı kabul ettiğimiz için `''` e-posta değeri NULL olmayan bir kayıt olarak sayılır. Doluluk ve geçerli adres doğrulaması ayrı kontrollerdir.

## WHERE ve HAVING farkı

WHERE gruba girecek satırları seçer. HAVING gruplama tamamlandıktan sonra grubu filtreler:

~~~sql
SELECT musteri_id, SUM(toplam)
FROM public.siparisler
WHERE durum <> 'iptal'
GROUP BY musteri_id
HAVING SUM(toplam) > 2000.00
ORDER BY musteri_id;
~~~

Müşteri 1 için 2550.00, müşteri 2 için 6500.00 gelir. `SUM(toplam) > 2000` koşulunu WHERE içine taşımayın; SUM henüz grup düzeyinde hesaplanmış değildir.

## Çifte sayımı önlemek

Sipariş başlığı kalemle JOIN edildiğinde başlık her kalem için tekrar eder. Bu nedenle kalem tablosundan satış tutarı hesaplıyorsanız ölçüm `adet * birim_fiyat` olmalıdır:

~~~sql
SELECT k.siparis_id, SUM(k.adet * k.birim_fiyat)
FROM public.siparis_kalemleri AS k
GROUP BY k.siparis_id
ORDER BY k.siparis_id;
~~~

Başlangıçta bu sonuçlar `siparisler.toplam` değerleriyle eşleşir. Uygulamada başlık toplamını ayrıca depoluyorsanız, kalem değişiklikleriyle tutarlı güncellemek sizin transaction tasarımınızın parçasıdır; FK bunu kendiliğinden sağlamaz.

**Alıştırma:** En az iki siparişi olan müşterileri bulun. `GROUP BY musteri_id HAVING COUNT(*) >= 2` kullanın. Başlangıç verisinde yalnız müşteri 1 döner.

**Kaynaklar:** [aggregate davranışı](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_COMPATIBILITY.md), [gruplama ve LEFT JOIN örnek testleri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/tests/query_smoke.cpp).
