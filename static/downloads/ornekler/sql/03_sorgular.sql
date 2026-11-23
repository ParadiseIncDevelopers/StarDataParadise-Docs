-- Salt okunur baslangic kontrolu. Beklenen degerler yorumlarda.
SELECT COUNT(*) FROM public.musteriler;
-- 4
SELECT COUNT(*) FROM public.urunler;
-- 4
SELECT COUNT(*) FROM public.siparisler;
-- 4
SELECT COUNT(*) FROM public.siparis_kalemleri;
-- 6
SELECT id, ad, fiyat, stok FROM public.urunler ORDER BY id;
SELECT COUNT(*), SUM(toplam) FROM public.siparisler;
-- 4, 9950.00
SELECT COUNT(*), SUM(toplam) FROM public.siparisler
WHERE durum = 'tamamlandi';
-- 2, 7600.00
SELECT m.id, m.ad, COUNT(s.id)
FROM public.musteriler AS m
LEFT JOIN public.siparisler AS s ON s.musteri_id = m.id
GROUP BY m.id, m.ad ORDER BY m.id;
-- 1/Ayse/2; 2/Mehmet/1; 3/Zeynep/1; 4/Deniz/0
SELECT siparis_id, SUM(adet * birim_fiyat)
FROM public.siparis_kalemleri GROUP BY siparis_id ORDER BY siparis_id;
-- 1001:1450.00, 1002:6500.00, 1003:1100.00, 1004:900.00
