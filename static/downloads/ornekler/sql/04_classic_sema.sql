-- YALNIZ Classic/native SQL yolu icin sdp_lab kurulumu.
-- Original wire-basic execute ve main.public laboratuvari icin DEGILDIR.
-- Her CREATE ayri ifade olarak, ilk hatada durularak calistirilmalidir.
-- IF NOT EXISTS yoktur: var olan sdp_lab sessizce benimsenmez.
-- Classic DDL implicit commit yapabilir; tum kurulumun rollback olacagini varsaymayin.
-- Bu FK'li model normal CRUD ve read-only Knowledge ornegidir.
-- AI actions/tool procedure uygunluk semasi degildir.

CREATE DATABASE sdp_lab CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

CREATE TABLE sdp_lab.musteriler (
    id BIGINT NOT NULL,
    ad VARCHAR(200) NOT NULL,
    eposta VARCHAR(254) NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_musteriler_eposta UNIQUE (eposta)
) ENGINE=InnoDB;

CREATE TABLE sdp_lab.urunler (
    id BIGINT NOT NULL,
    ad VARCHAR(200) NOT NULL,
    fiyat DECIMAL(12,2) NOT NULL,
    stok BIGINT NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT ck_urunler_fiyat CHECK (fiyat >= 0.00),
    CONSTRAINT ck_urunler_stok CHECK (stok >= 0)
) ENGINE=InnoDB;

CREATE TABLE sdp_lab.siparisler (
    id BIGINT NOT NULL,
    musteri_id BIGINT NOT NULL,
    durum TEXT NOT NULL,
    toplam DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_siparisler_musteri FOREIGN KEY (musteri_id)
        REFERENCES sdp_lab.musteriler (id) ON DELETE RESTRICT,
    CONSTRAINT ck_siparisler_toplam CHECK (toplam >= 0.00),
    CONSTRAINT ck_siparisler_durum CHECK (
        durum = 'hazirlaniyor' OR durum = 'tamamlandi' OR durum = 'iptal'
    )
) ENGINE=InnoDB;

CREATE TABLE sdp_lab.siparis_kalemleri (
    siparis_id BIGINT NOT NULL,
    urun_id BIGINT NOT NULL,
    adet BIGINT NOT NULL,
    birim_fiyat DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (siparis_id, urun_id),
    CONSTRAINT fk_kalem_siparis FOREIGN KEY (siparis_id)
        REFERENCES sdp_lab.siparisler (id) ON DELETE RESTRICT,
    CONSTRAINT fk_kalem_urun FOREIGN KEY (urun_id)
        REFERENCES sdp_lab.urunler (id) ON DELETE RESTRICT,
    CONSTRAINT ck_kalem_adet CHECK (adet > 0),
    CONSTRAINT ck_kalem_fiyat CHECK (birim_fiyat >= 0.00)
) ENGINE=InnoDB;
