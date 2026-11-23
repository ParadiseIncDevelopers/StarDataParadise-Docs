-- YALNIZ Classic/native sdp_lab; once 04_classic_sema.sql.
-- SDK native.begin ile transaction acin; INSERT'leri tek tek gonderin.
-- Tum INSERT'ler basariliysa native.commit; hatada rollback ve durma.
-- Dosyanin tamamini tek native.execute cagrisi olarak GONDERMEYIN.
-- Tekrar calistirma PK ihlali verir; otomatik replace/upsert yoktur.
INSERT INTO sdp_lab.musteriler (id, ad, eposta) VALUES
    (1, 'Ayşe Kaya', 'ayse@example.test'),
    (2, 'Mehmet Demir', 'mehmet@example.test'),
    (3, 'Zeynep Çelik', NULL),
    (4, 'Deniz Aydın', NULL);

INSERT INTO sdp_lab.urunler (id, ad, fiyat, stok) VALUES
    (101, 'Klavye', 750.00, 20),
    (102, 'Fare', 350.00, 50),
    (103, 'Monitör', 6500.00, 8),
    (104, 'USB Hub', 900.00, 0);

INSERT INTO sdp_lab.siparisler (id, musteri_id, durum, toplam) VALUES
    (1001, 1, 'hazirlaniyor', 1450.00),
    (1002, 2, 'tamamlandi', 6500.00),
    (1003, 1, 'tamamlandi', 1100.00),
    (1004, 3, 'iptal', 900.00);

INSERT INTO sdp_lab.siparis_kalemleri
    (siparis_id, urun_id, adet, birim_fiyat) VALUES
    (1001, 101, 1, 750.00),
    (1001, 102, 2, 350.00),
    (1002, 103, 1, 6500.00),
    (1003, 101, 1, 750.00),
    (1003, 102, 1, 350.00),
    (1004, 104, 1, 900.00);
