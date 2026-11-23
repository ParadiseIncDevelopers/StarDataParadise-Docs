-- StarDataParadise original wire v1 SQL laboratuvari.
-- Bos/ayri bir test instance'inda, main.public baglaminda kullanin.
-- CLI --transaction single --stop-on-error ile calistirin.
-- Bu dosya veri silmez; nesneler zaten varsa hata vermesi beklenir.

CREATE TABLE public.musteriler (
    id BIGINT PRIMARY KEY,
    ad TEXT NOT NULL,
    eposta TEXT,
    CONSTRAINT uq_musteriler_eposta UNIQUE (eposta)
);

CREATE TABLE public.urunler (
    id BIGINT PRIMARY KEY,
    ad TEXT NOT NULL,
    fiyat DECIMAL(12,2) NOT NULL,
    stok BIGINT NOT NULL,
    CONSTRAINT ck_urunler_fiyat CHECK (fiyat >= 0.00),
    CONSTRAINT ck_urunler_stok CHECK (stok >= 0)
);

CREATE TABLE public.siparisler (
    id BIGINT PRIMARY KEY,
    musteri_id BIGINT NOT NULL,
    durum TEXT NOT NULL,
    toplam DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_siparisler_musteri FOREIGN KEY (musteri_id)
        REFERENCES public.musteriler (id) ON DELETE RESTRICT,
    CONSTRAINT ck_siparisler_toplam CHECK (toplam >= 0.00),
    CONSTRAINT ck_siparisler_durum CHECK (
        durum = 'hazirlaniyor' OR durum = 'tamamlandi' OR durum = 'iptal'
    )
);

CREATE TABLE public.siparis_kalemleri (
    siparis_id BIGINT NOT NULL,
    urun_id BIGINT NOT NULL,
    adet BIGINT NOT NULL,
    birim_fiyat DECIMAL(12,2) NOT NULL,
    CONSTRAINT pk_siparis_kalemleri PRIMARY KEY (siparis_id, urun_id),
    CONSTRAINT fk_kalem_siparis FOREIGN KEY (siparis_id)
        REFERENCES public.siparisler (id) ON DELETE RESTRICT,
    CONSTRAINT fk_kalem_urun FOREIGN KEY (urun_id)
        REFERENCES public.urunler (id) ON DELETE RESTRICT,
    CONSTRAINT ck_kalem_adet CHECK (adet > 0),
    CONSTRAINT ck_kalem_fiyat CHECK (birim_fiyat >= 0.00)
);

CREATE INDEX public.idx_siparisler_musteri
    ON public.siparisler (musteri_id);
