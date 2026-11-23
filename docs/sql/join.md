---
title: "JOIN: tablolar arasındaki ilişkileri okumak"
slug: "/sql/join"
---

# JOIN: tablolar arasındaki ilişkileri okumak

**Kapsam:** original wire v1 SQL; INNER, LEFT ve CROSS JOIN.

Veriyi ilişkisel tasarladığınızda müşteri bilgisi müşteri tablosunda, sipariş bilgisi sipariş tablosunda tutulur. JOIN, bu kayıtları bir sorgu sonucunda bir araya getirir. Tabloları fiziksel olarak birleştirmez ve yeni kalıcı satır oluşturmaz.

## INNER JOIN

~~~sql
SELECT s.id, m.ad, s.durum, s.toplam
FROM public.siparisler AS s
JOIN public.musteriler AS m ON m.id = s.musteri_id
ORDER BY s.id;
~~~

Her sipariş için eşleşen müşteri bulunur. Başlangıç verisinde dört sipariş olduğundan dört satır döner. Ayşe'nin adı iki kez görülür; bu tekrar bir hata değildir, iki farklı siparişe karşılık gelir.

JOIN koşulunu kimlik ilişkisine göre kurun. Müşteri adları aynı olabilir; `m.ad = ...` üzerinden ilişki üretmek kimlik anlamını korumaz. PK/FK tasarımının sorguya yansıması `m.id = s.musteri_id` koşuludur.

## LEFT JOIN: eşleşmesi olmayanları korumak

~~~sql
SELECT m.id, m.ad, s.id
FROM public.musteriler AS m
LEFT JOIN public.siparisler AS s ON s.musteri_id = m.id
ORDER BY m.id, s.id;
~~~

Dört müşteri vardır; Ayşe iki sipariş nedeniyle iki satır üretir. Deniz'in siparişi olmadığından sipariş kimliği NULL gelir. Toplam beş sonuç satırı beklenir.

Sipariş vermeyen müşteriler:

~~~sql
SELECT m.id, m.ad
FROM public.musteriler AS m
LEFT JOIN public.siparisler AS s ON s.musteri_id = m.id
WHERE s.id IS NULL
ORDER BY m.id;
~~~

Sonuç `4, Deniz Aydın` olur. NULL kontrolü, sağ tablodaki NOT NULL/PK sütun üzerinde yapılır; böylece “eşleşme yok” durumu güvenilir biçimde ayırt edilir.

## Filtreyi ON veya WHERE içine koymak

Bütün müşterileri gösterip yalnız tamamlanan siparişlerini yanına eklemek için durum filtresi JOIN koşulunda olmalıdır:

~~~sql
SELECT m.id, m.ad, s.id
FROM public.musteriler AS m
LEFT JOIN public.siparisler AS s
  ON s.musteri_id = m.id AND s.durum = 'tamamlandi'
ORDER BY m.id, s.id;
~~~

`WHERE s.durum = 'tamamlandi'` yazarsanız eşleşmeyen satırların NULL değerleri WHERE'den geçmez. Böylece siparişi olmayan müşteriler kaybolur. LEFT JOIN'in amacını anlamak için “hangi tarafın her satırı korunacak?” sorusunu önce cevaplayın.

## Üç tabloyu okumak

~~~sql
SELECT s.id, u.ad, k.adet, k.birim_fiyat,
       k.adet * k.birim_fiyat
FROM public.siparisler AS s
JOIN public.siparis_kalemleri AS k ON k.siparis_id = s.id
JOIN public.urunler AS u ON u.id = k.urun_id
WHERE s.id = 1001
ORDER BY k.urun_id;
~~~

1001 numaralı sipariş için Klavye 1 × 750.00 ve Fare 2 × 350.00 satırları gelir. Hesaplanan değerler 750.00 ve 700.00'dır. Ürünün güncel fiyatı yerine kalemde saklanan `birim_fiyat` kullanılır; ürün fiyatının sonradan değişmesi eski sipariş tutarını değiştirmemelidir.

## Satır çoğalmasını anlamak

Bir siparişin iki kalemi varsa, sipariş başlığı kalemlerle JOIN edildiğinde iki kez görünür. Ardından `SUM(s.toplam)` almak başlık toplamını iki kez sayabilir. Önce hangi düzeyde rapor hazırladığınızı belirleyin: sipariş başlığı mı, kalem mi, müşteri mi? [Gruplama](gruplama.md) bölümünde bu fark hesaplama ile gösterilir.

CROSS JOIN her sol satırı her sağ satırla eşler. Dört müşteri ile dört ürün 16 satır üretir. Kombinasyon üretmek gerektiğinde anlamlıdır; unutulmuş bir ilişki koşulunu telafi etmez. Büyük tablolarda beklenmedik sonuç büyümesine neden olabilir.

**Alıştırma:** Müşteri 1'in bütün siparişlerinde yer alan ürünleri, sipariş kimliğiyle listeleyin. Sipariş, kalem ve ürün tablolarını birleştirin; filtreyi `s.musteri_id = 1` olarak ekleyin. Dört kalem satırı beklenir.

**Kaynaklar:** [JOIN desteği](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_COMPATIBILITY.md), [kaynak sorgu testleri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/tests/query_smoke.cpp), [gramer](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/sql/SQL.ebnf).
