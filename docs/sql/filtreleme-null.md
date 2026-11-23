---
title: "WHERE, mantıksal koşullar ve NULL"
slug: "/sql/filtreleme-null"
---

# WHERE, mantıksal koşullar ve NULL

**Kapsam:** original wire v1 SQL.

WHERE, her aday satır için bir mantıksal ifade değerlendirir. Yalnızca sonucu TRUE olan satırlar seçilir. FALSE ve UNKNOWN olan satırlar sonuçta bulunmaz. NULL ile çalışırken bu üçüncü durum, sorgunun beklenenden farklı sonuç vermesinin en yaygın nedenidir.

## Karşılaştırma ve birleşik koşullar

Desteklenen karşılaştırma operatörleri `=`, `<>`, `!=`, `<`, `<=`, `>` ve `>=` biçimindedir. Koşullar AND, OR ve NOT ile birleşir:

~~~sql
SELECT id, ad, fiyat, stok
FROM public.urunler
WHERE fiyat >= 500.00
  AND fiyat <= 1000.00
  AND stok > 0
ORDER BY id;
~~~

Başlangıç verisinde yalnızca Klavye seçilir. USB Hub fiyat aralığında olsa da stok koşulunu geçemez.

İki durumu seçmek için:

~~~sql
SELECT id, durum
FROM public.siparisler
WHERE durum = 'hazirlaniyor' OR durum = 'tamamlandi'
ORDER BY id;
~~~

Sonuç 1001, 1002 ve 1003 olur. İncelenen original gramer IN ve BETWEEN içermediği için örnekler açık OR ve sınır karşılaştırmaları kullanır. Benzer şekilde LIKE ile desen arama bu profile ait doğrulanmış öğretici kapsamda değildir; genel SQL bilgisinden hareketle destek varmış gibi kullanmayın.

## Öncelik: parantez niyeti gösterir

~~~sql
SELECT id, musteri_id, durum
FROM public.siparisler
WHERE musteri_id = 1
  AND (durum = 'hazirlaniyor' OR durum = 'tamamlandi')
ORDER BY id;
~~~

Burada amaç, yalnızca müşteri 1'in iki uygun durumdaki siparişlerini seçmektir. Parantezi kaldırıp `musteri_id = 1 AND durum = ... OR durum = ...` yazmak, ikinci duruma sahip başka müşterilerin siparişlerini de kapsayabilir. AND, OR'dan önce değerlendirilir. İş kuralı iki cümle halinde okunabiliyorsa sorguda parantez kullanmak incelemeyi kolaylaştırır.

## NULL sıfır veya boş metin değildir

`NULL` değerin bilinmediğini ya da alanın henüz doldurulmadığını ifade eder. `''` bilinen boş bir metindir; `0` bilinen sayısal sıfırdır. Bu üç durumu tek değer gibi ele almak veri kalitesini bozabilir.

~~~sql
SELECT id, ad
FROM public.musteriler
WHERE eposta IS NULL
ORDER BY id;
~~~

Zeynep ve Deniz gelir. `eposta = NULL` yazmayın: olağan eşitlik karşılaştırması UNKNOWN üretir. E-posta bulunanları seçmek için `eposta IS NOT NULL` kullanın.

| İfade | Sonuç |
| --- | --- |
| `NULL = NULL` | UNKNOWN |
| `NULL IS NULL` | TRUE |
| `TRUE AND UNKNOWN` | UNKNOWN |
| `FALSE AND UNKNOWN` | FALSE |
| `TRUE OR UNKNOWN` | TRUE |

Bu mantık yalnız SELECT için değil UPDATE ve DELETE koşulları için de geçerlidir. Örneğin `WHERE durum <> 'iptal'` yazıldığında durumu NULL olan satır dahil olmaz. “İptal değil veya henüz durumu yok” kuralı gerekiyorsa bunu `durum <> 'iptal' OR durum IS NULL` biçiminde açıkça yazmalısınız.

## Parametreyle güvenli filtreleme

Uygulama sorgusu:

~~~sql
SELECT id, ad, stok
FROM public.urunler
WHERE id = :urun_id;
~~~

`urun_id` değeri ayrı tipli parametredir. Metnin sonuna kullanıcı girdisi eklemeyin. Sayısal bir alanın değeri hatalıysa uygulamada doğrulama yapın; SDK bağlama aşamasının da beklenen tip ile tutarlılığını koruyun.

Parametreyle NULL gönderirken yalnız “null” değerini iletmek yetersiz olabilir; SDK'ya SQL tipini bildirmeniz gerekebilir. Her SDK'nın tip eşleme bölümünde bunun karşılığı anlatılır.

## Alıştırma ve çözüm

Fiyatı 1000'den küçük, stoku olmayan veya en fazla 20 olan ürünleri bulun:

~~~sql
SELECT id, ad
FROM public.urunler
WHERE fiyat < 1000.00
  AND (stok = 0 OR stok <= 20)
ORDER BY id;
~~~

101 ve 104 gelir. Burada stok alanı NOT NULL ve negatif olmayan bir CHECK ile tanımlandığından `stok = 0 OR stok <= 20`, `stok <= 20` olarak sadeleştirilebilir. Bir koşulu sadeleştirmeden önce sütunun NULL ve geçerli değer kurallarını bilmek gerekir.

**Kaynaklar:** [veri tipi ve üç değerli mantık kuralları](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_COMPATIBILITY.md), [desteklenen ifadeler](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/sql/SQL.ebnf).
