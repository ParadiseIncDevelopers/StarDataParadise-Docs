---
title: "SQL çalışma seti ve çözümler"
slug: "/sql/alistirmalar"
---

# SQL çalışma seti ve çözümler

**Kapsam:** original wire v1 motoru, başlangıç laboratuvarı. Sonuçlar örnek veri üzerinden hesaplanmıştır; bu dokümantasyon hazırlanırken çalışan bir Server'a karşı yürütülmüş test çıktıları değildir.

Bu sayfayı iki geçişte kullanın. İlk geçişte yalnız soruyu okuyup sorguyu yazın. İkinci geçişte çözümle karşılaştırın ve özellikle satır sayısının neden o şekilde oluştuğunu açıklayın. Farklı ama aynı anlamı koruyan bir sorgu da doğru olabilir.

## 1. Satılabilir ürünler

**Soru:** Stoku olan ürünlerin kimlik ve adını listeleyin.

~~~sql
SELECT id, ad FROM public.urunler
WHERE stok > 0 ORDER BY id;
~~~

**Beklenen:** 101 Klavye, 102 Fare, 103 Monitör. Fiyat şartı yoktur; en pahalı ürünün de gelmesi doğrudur.

## 2. Fiyat aralığı

**Soru:** Fiyatı 500 dahil, 1000 hariç olan ürünler hangileridir?

~~~sql
SELECT id, ad, fiyat FROM public.urunler
WHERE fiyat >= 500.00 AND fiyat < 1000.00 ORDER BY id;
~~~

**Beklenen:** 101 ve 104. Bu sorgu stok kontrolü yapmadığından stok dışı USB Hub dahil olur.

## 3. E-posta bilgisi eksik müşteriler

~~~sql
SELECT id, ad FROM public.musteriler
WHERE eposta IS NULL ORDER BY id;
~~~

**Beklenen:** 3 Zeynep Çelik ve 4 Deniz Aydın. `= NULL` aynı sorgu değildir.

## 4. Müşteri siparişleri

**Soru:** Ayşe'nin siparişlerini adı ve tutarıyla gösterin. Kimlik olarak müşteri 1'i kullanın.

~~~sql
SELECT m.ad, s.id, s.toplam
FROM public.musteriler AS m
JOIN public.siparisler AS s ON s.musteri_id = m.id
WHERE m.id = 1 ORDER BY s.id;
~~~

**Beklenen:** 1001 için 1450.00, 1003 için 1100.00. Adı iki defa göstermek JOIN çoğalmasının doğru sonucudur.

## 5. Sipariş vermeyenler

~~~sql
SELECT m.id, m.ad
FROM public.musteriler AS m
LEFT JOIN public.siparisler AS s ON s.musteri_id = m.id
WHERE s.id IS NULL ORDER BY m.id;
~~~

**Beklenen:** Deniz Aydın. Üç müşterinin siparişi olması, müşterilerin yalnız üç satırda saklandığı anlamına gelmez.

## 6. Müşteri başına sipariş sayısı

~~~sql
SELECT m.id, COUNT(s.id)
FROM public.musteriler AS m
LEFT JOIN public.siparisler AS s ON s.musteri_id = m.id
GROUP BY m.id ORDER BY m.id;
~~~

**Beklenen:** (1,2), (2,1), (3,1), (4,0). COUNT(*) kullanıldığında son satırın neden 1 olacağını açıklayın.

## 7. Tamamlanan sipariş tutarı

~~~sql
SELECT SUM(toplam)
FROM public.siparisler
WHERE durum = 'tamamlandi';
~~~

**Beklenen:** 7600.00. İptal sipariş ve hazırlanan sipariş bu tanıma dahil değildir.

## 8. Kalemlerin toplamı

~~~sql
SELECT siparis_id, SUM(adet * birim_fiyat)
FROM public.siparis_kalemleri
GROUP BY siparis_id ORDER BY siparis_id;
~~~

**Beklenen:** 1001→1450.00; 1002→6500.00; 1003→1100.00; 1004→900.00. Bu sonuç, başlık toplamı ile kalem toplamını uzlaştırmak için kullanılabilir.

## 9. En yüksek fiyat

~~~sql
SELECT id, ad FROM public.urunler
WHERE fiyat = (SELECT MAX(fiyat) FROM public.urunler)
ORDER BY id;
~~~

**Beklenen:** 103 Monitör. İki ürün aynı maksimum fiyata sahip olursa iki satır bekleyin.

## 10. İptal siparişi veya eksik e-postası olan müşteri

~~~sql
SELECT musteri_id FROM public.siparisler WHERE durum = 'iptal'
UNION
SELECT id FROM public.musteriler WHERE eposta IS NULL;
~~~

**Beklenen küme:** 3 ve 4; ORDER BY bulunmadığı için bu iki satırın sırasına güvenmeyin. UNION ALL kullanılırsa 3 tekrarlanır. Birleşik sonucun iki kolunda da aynı sayıda ve uyumlu tipte sütun bulunur.

## 11. Rollback deneyi

Etkileşimli CLI:

~~~text
\begin
UPDATE public.urunler SET stok = stok - 5 WHERE id = 102;
SELECT stok FROM public.urunler WHERE id = 102;
\rollback
SELECT stok FROM public.urunler WHERE id = 102;
~~~

**Beklenen:** Transaction içindeki okuma 45, rollback sonrası okuma 50. Bu deneyi `--transaction single` içine yerleştirmeyin; terminal transaction komutlarıyla o modu birleştirmek doğru değildir.

## 12. Yanlış ilişki deneyi

Ayrı bir deneme transaction'ında mevcut olmayan müşteriyle sipariş ekleyin:

~~~sql
INSERT INTO public.siparisler (id, musteri_id, durum, toplam)
VALUES (2999, 999, 'hazirlaniyor', 10.00);
~~~

**Beklenen:** FK ihlali. Uygulama buna karşı müşteriyi gizlice oluşturmak veya ilişkiyi NULL yapmak yerine iş kuralına uygun hata üretmelidir. Denemeyi rollback ile bitirin.

## Çalışma sonrası değerlendirme

Her sorgu için üç soruyu yanıtlayın: Beklenen satır sayısı nedir? NULL veya ilişki yokluğu sonucu nasıl değiştirir? Veri aynı anda değişirse uygulama nasıl davranmalı? İyi SQL bilgisi, doğru komutu yazmanın yanında bu soruları da kapsar.

**Kaynaklar:** [laboratuvar kurulumu](../veritabani/laboratuvar.md), [SQL grameri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/sql/SQL.ebnf), [sorgu davranışı testleri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/tests/query_smoke.cpp).
