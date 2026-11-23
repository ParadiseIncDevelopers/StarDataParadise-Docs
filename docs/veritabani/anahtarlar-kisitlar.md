---
title: "Anahtarlar, ilişkiler ve veri bütünlüğü"
slug: "/veritabani/anahtarlar-kisitlar"
---

# Anahtarlar, ilişkiler ve veri bütünlüğü

**Kapsam:** original wire v1 SQL. PK, UNIQUE, FK, CHECK ve NOT NULL.

Uygulama doğrulaması kullanıcıya hızlı geri bildirim verir. Veritabanı kısıtları ise farklı istemciler, script'ler ve aynı anda çalışan işler üzerinden de aynı veri kurallarının uygulanmasını sağlar. İkisini birlikte kullanın: ekran doğrulaması kısıtın yerini almaz; kısıt hatası da tek başına iyi bir kullanıcı mesajı değildir.

## PRIMARY KEY

~~~sql
CREATE TABLE public.etiketler (
    id BIGINT PRIMARY KEY,
    ad TEXT NOT NULL
);
~~~

PK, satırın kimliğini tanımlar ve NULL kabul etmez. Bir tabloda seçilen anahtar sütunlarının kombinasyonu benzersiz olmalıdır. Laboratuvardaki `siparis_kalemleri` iki sütunlu anahtar kullanır:

~~~sql
PRIMARY KEY (siparis_id, urun_id)
~~~

Bu, aynı siparişte aynı ürün için ikinci satırı reddeder. Yalnız `urun_id` için benzersizlik getirmez; aynı ürün farklı siparişlerde bulunabilir.

PK kuralıyla sorgu erişim index'ini birbirine karıştırmayın. Original motorun kaynak testleri PK'li tabloda ayrı CREATE INDEX öncesi tarama, sonrası index erişimi gösterir. Performans için index ihtiyacını ayrıca inceleyin.

## UNIQUE ve NULL

Laboratuvarda e-posta:

~~~sql
CONSTRAINT uq_musteriler_eposta UNIQUE (eposta)
~~~

Aynı dolu e-posta ikinci kez kullanılamaz. Belgelenen kurala göre composite UNIQUE anahtarın herhangi bir bileşeni NULL ise tekrar mümkündür. Bu nedenle Zeynep ve Deniz'in e-posta alanlarının ikisinin de NULL olması geçerlidir.

E-postanın harf duyarlılığı veya normalizasyonu bu benzersizlik tanımıyla birlikte düşünülmelidir. Varsayılan binary karşılaştırmada farklı byte dizilerini aynı kişi olarak varsaymayın. Uygulama bir standartlaştırma yapıyorsa bunu bütün yazma yollarında tutarlı uygulayın.

## FOREIGN KEY

~~~sql
CONSTRAINT fk_siparisler_musteri
FOREIGN KEY (musteri_id)
REFERENCES public.musteriler (id)
ON DELETE RESTRICT
~~~

Siparişin müşteri kimliği mevcut bir PK/UNIQUE değere karşılık gelmelidir; sütun tipleri uyumlu olmalıdır. Child FK'nin herhangi bir bileşeni NULL ise parent zorunluluğu aranmaz. Laboratuvarda `musteri_id NOT NULL` tanımı bunu isteğe bağlı ilişki olmaktan çıkarır.

Original motorda NO ACTION ve RESTRICT immediate denetlenir. CASCADE veya deferred constraint desteği varsayılmamalıdır. Eklemede önce parent; silmede önce child sırası kullanılır. Birden çok adımı aynı iş olarak yapmak gerekiyorsa transaction açılır.

FK yalnız varlık ilişkisini doğrular. “Müşteri aktif olmalı”, “ürün stokta olmalı” veya “sipariş toplamı kalem toplamına eşit olmalı” gibi farklı iş kuralları için ayrıca mantık gerekir.

## CHECK ve UNKNOWN

~~~sql
CONSTRAINT ck_kalem_adet CHECK (adet > 0)
~~~

CHECK FALSE sonucunda yazmayı reddeder; UNKNOWN kabul edilir. Bu nedenle NULL'ı engellemek için `adet BIGINT NOT NULL` ifadesi de kullanılır. Adet 0 veya -1 geçmez, 2 geçer. Sütun NULL olabilseydi CHECK tek başına onu durdurmazdı.

Durum kümesini kısıtlamak için:

~~~sql
CHECK (
    durum = 'hazirlaniyor'
    OR durum = 'tamamlandi'
    OR durum = 'iptal'
)
~~~

Bu tanım izin verilen değerleri sınırlar; önceki durumdan yeni duruma geçişi açıklamaz. Bu ikinci kuralda OLD/NEW değerlerine bakan Decision veya UPDATE koşulu kullanılabilir.

## Hata sonrası davranış

Birden çok satırlı INSERT'in bir satırı CHECK'i ihlal ederse, kaynak testleri ifadenin kısmi veri bırakmadığını doğrular. Bununla birlikte o transaction'da daha önce başarıyla yapılmış başka ifadeleri hangi iş kuralıyla geri alacağınıza uygulama karar verir.

Kısıt hatasını “bağlantı problemi” gibi tekrar denemeyin. Aynı geçersiz veriyi tekrar göndermek sonucu değiştirmez. İlgili alanı ve iş kuralını düzeltin, veya transaction'ın tamamını rollback edin.

## Adlandırılmış kısıtlar

Kısıtlara anlamlı ad vermek migration ve hata incelemesini kolaylaştırır: `fk_kalem_urun`, `ck_urunler_stok` gibi. Şema değiştirirken bir sütuna bağlı FK, index, view ve rutinleri birlikte değerlendirin. Kısıtı geçici kaldırmak, o aralıkta tutarsız veri yazılmasına izin verebilir; bunun operasyonel planı olmadan yapılmamalıdır.

**Kaynaklar:** [integrity kuralları](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_COMPATIBILITY.md), [PK/UNIQUE/FK/statement rollback testleri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/tests/relations_smoke.cpp), [constraint grameri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/sql/SQL.ebnf).
