---
title: "Veritabanı, schema, tablo ve oturum"
slug: "/veritabani/"
---

# Veritabanı, schema, tablo ve oturum

**Kapsam:** StarDataParadise original wire v1 motoru. Classic/native ad alanı farklılıkları [ayrı sayfada](classic-farklari.md) açıklanır.

Bir veritabanı bağlantısını yalnız “bir dosyayı açmak” gibi düşünmeyin. Sunucu verinin sahibi olan süreçtir; istemci onunla kimliği doğrulanmış bir oturum kurar. Aynı Server birden çok veritabanı ve schema nesnesi barındırabilir. Kullanıcı hangi nesneleri görebileceğini ve değiştirebileceğini yetkileri üzerinden kazanır.

## Nesne hiyerarşisi

| Kavram | Görevi | Laboratuvar örneği |
| --- | --- | --- |
| Server instance | Ayrı yapılandırma, veri ve çalışma süreçleri | Test Server'ı |
| Database | Üst düzey katalog alanı | main |
| Schema | Database içindeki adlandırma alanı | public |
| Table | Aynı sütun yapısına sahip kayıtlar | urunler |
| Column | Her kaydın tipli alanı | fiyat |
| Row | Bir varlığa veya ilişkiye ait kayıt | 101 numaralı ürün |
| Connection/session | Kullanıcı kimliği ve çalışma durumu | SDK bağlantısı |
| Transaction | Birlikte sonuçlanacak değişiklik sınırı | Sipariş oluşturma |

Tam bir tablo adı `main.public.urunler` biçimindedir. Varsayılan çalışma bağlamında `urunler`, `main.public.urunler` olarak çözülür. İki parçalı `public.urunler` adı ise `main.public.urunler` anlamına gelir. İki parçalı adın ilk kısmı burada database değil schema'dır.

Bu ayrım özellikle başka veritabanından gelen geliştiriciler için önemlidir. `satis.urunler` yazdığınızda `satis` adlı bir database'e otomatik geçildiğini varsaymayın.

## Yeni bir database ve schema

Ayrı bir örnek alan oluşturmak için:

~~~sql
CREATE DATABASE rapor;
CREATE SCHEMA rapor.satis;

CREATE TABLE rapor.satis.aylik_ozet (
    yil BIGINT NOT NULL,
    ay BIGINT NOT NULL,
    tutar DECIMAL(18,2) NOT NULL,
    PRIMARY KEY (yil, ay)
);
~~~

Bir başka schema oluşturmak isterseniz yine tam ad kullanın. Original SQL oturumunda `USE rapor` komutu belgelenmiş gramerin parçası değildir. CLI istemindeki `main.public` bağlamını değiştireceğinizi varsaymak yerine sorgulara tam nesne adını yazın.

~~~sql
INSERT INTO rapor.satis.aylik_ozet (yil, ay, tutar)
VALUES (2026, 11, 7600.00);

SELECT yil, ay, tutar
FROM rapor.satis.aylik_ozet;
~~~

DDL işlemleri original motorda caller transaction'ına dahildir; manuel modda commit gerekir. Yetki ve parola yönetiminin kendi autocommit kuralları ayrıca vardır.

## Katalog ile veri farkı

Tablo adı, sütun tipi, constraint ve view tanımı katalog bilgisidir. Müşterinin adı ve ürünün fiyatı veri satırlarıdır. `ALTER TABLE` katalog ve gerektiğinde satır düzenini değiştirir; `UPDATE` mevcut satır değerlerini değiştirir.

Katalog nesnelerinin stable kimlikleri ve schema sürümleri vardır. Bir adı değiştirmek veya rutin tanımını yenilemek, bağımlı hazırlanan ifadelerin ve rutinlerin yeniden doğrulanmasını gerektirebilir. Şema değişikliğini yalnız veritabanı tarafında bir metin düzenlemesi olarak görmeyin; onu kullanan SDK kodu da sözleşmenin bir parçasıdır.

## Nesneleri incelemek

CLI komutları:

~~~text
\databases
\tables
\describe main.public.urunler
~~~

Bunlar SQL değildir. Yetkilerinize göre görünür katalog nesnelerini gösterirler. Bir nesnenin listelenmemesi her zaman nesnenin bulunmadığı anlamına gelmez; oturum o nesneyi görmeye yetkili olmayabilir.

Sunucu kapalıyken bakım amacıyla kullanılan `--catalog-info` ayrı bir yerel inceleme yoludur. Çalışan instance'ın veri dizinine ikinci süreçle gelişigüzel erişmeyin; bakım komutları dizin kilidi ve kendi çalışma kurallarına sahiptir.

## Silme ve bağımlılıklar

Boş kullanıcı schema/database alanları kaldırılabilir. Tabloya bağlı view, FK veya rutin varsa önce bağımlılıkları değerlendirin. Yerleşik `main.public` ad alanı korumalıdır. Uygulama veri ayrımı için farklı database oluşturmak, kendi başına ayrı kullanıcı yetkisi veya ayrı fiziksel sunucu izolasyonu sağlamaz; erişimi ayrıca tanımlayın.

**Kaynaklar:** [ad çözümleme ve katalog](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_COMPATIBILITY.md), [database/schema kaynak testi](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/tests/sql_smoke.cpp), [oturum bağlamı](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_SECURITY.md).
