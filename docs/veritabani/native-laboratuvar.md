---
title: "Classic/native laboratuvarını kurmak"
slug: "/veritabani/native-laboratuvar"
---

# Classic/native laboratuvarını kurmak

**Kapsam:** StarDataParadise Classic engine ve onu kullanan `native_sql_v1` yolu. Bu kurulum original motorun `main.public` laboratuvarından ayrıdır.

SDK native örnekleri veya read-only Knowledge sayfası `sdp_lab.siparisler` nesnesini kullanıyorsa önce bu laboratuvarı oluşturun. Original laboratuvarı kurmuş olmak, Classic tarafta aynı verinin bulunduğu anlamına gelmez. İki profil aynı müşteri ve ürün hikâyesini kullanır, fakat ayrı database ve ayrı bağlantı yolunda çalışır.

## Hangi dosyalar kullanılacak?

| Sıra | Dosya | Görev |
| --- | --- | --- |
| 1 | [04_classic_sema.sql](pathname:///StarDataParadise-Docs/downloads/ornekler/sql/04_classic_sema.sql) | sdp_lab database'i ve InnoDB tabloları |
| 2 | [05_classic_ornek_veri.sql](pathname:///StarDataParadise-Docs/downloads/ornekler/sql/05_classic_ornek_veri.sql) | 4 müşteri, 4 ürün, 4 sipariş, 6 kalem |
| 3 | [06_classic_sorgular.sql](pathname:///StarDataParadise-Docs/downloads/ornekler/sql/06_classic_sorgular.sql) | Başlangıç değerlerini okumak |

Bu dosyalar original `StarDataParadiseCLI.exe` wire-basic SQL akışına gönderilmez. Kurulu Classic bağlantısını kullanan Workbench/Shell veya ayrı native SDK bağlantısı üzerinden çalıştırılır. Uç nokta ve kullanıcı, Classic/native kurulumunuza ait olmalıdır; varsayılan 7443 veya başka bir portu tahmin etmeyin.

## Önce şema, sonra veri

Schema dosyasındaki ilk ifade yeni bir `sdp_lab` database'i oluşturur. `IF NOT EXISTS` kullanılmaz: aynı adlı database zaten varsa işlem durur. Var olan alanı “uygundur” kabul edip üzerine seed veri eklemeyin.

MySQL tabanlı Classic yolda CREATE DATABASE ve CREATE TABLE gibi DDL işlemleri implicit commit yapabilir. Original motordaki transactional DDL anlatımını buraya taşımayın. Beş CREATE ifadesini sırayla, her adımın sonucunu kontrol ederek yürütün. Bir adım hata verirse hangi nesnelerin oluştuğunu inceleyin; kurulumun tamamının geri alındığını varsaymayın.

Native SDK tek çağrıda tek SQL ifadesi kabul eder. Dosyanın bütününü `execute` çağrısına vermeyin. Bu basit kurulumda her CREATE ve her INSERT ayrı bir ifadedir. Genel amaçlı SQL ayırıcıyı `split(';')` ile yazmak da prosedür gövdeleri veya metin içindeki noktalı virgüller için doğru değildir.

Schema tamamlanınca seed için SDK'nın native begin işlemiyle transaction açın. Dört INSERT'i ayrı çağrılarla sırayla yürütün. Hepsi başarılıysa native commit yapın; herhangi bir hata olursa rollback ve durma yolunu izleyin. Dosya özellikle kendi START TRANSACTION/COMMIT ifadelerini içermez; transaction'ı istemci yönetir.

## Tiplerin bilinçli farkları

Ad alanları `VARCHAR(200)`, e-posta `VARCHAR(254)` olarak tanımlanmıştır. E-posta üzerinde UNIQUE bulunduğundan bu seçim Classic'in index gereksinimleriyle uyumludur. Uygulama girişinde uzunluk ve kodlama kurallarını bu sınırlarla eşleştirin.

Knowledge örneğinin sonuç tipleriyle eşleşmesi için sipariş tablosunda:

~~~sql
id BIGINT NOT NULL,
durum TEXT NOT NULL,
toplam DECIMAL(12,2) NOT NULL
~~~

kullanılır. Kimlik signed BIGINT'tir; bunu örnekte UNSIGNED parametreye veya farklı precision'a sessizce çevirmeyin. Database `utf8mb4` kullanır. Original TEXT karşılaştırma kurallarıyla Classic collation davranışının her ayrıntıda özdeş olduğu varsayılmaz.

## Kontrol sonuçları

~~~sql
SELECT id, durum, toplam
FROM sdp_lab.siparisler
WHERE id = 1001;
~~~

Başlangıçta `1001, hazirlaniyor, 1450.00` gelir. Tamamlanan siparişlerin toplamı 7600.00, bütün siparişlerin toplamı 9950.00'dır. Native sonuç değerlerini SDK'nın exact decimal ve metin tiplerinden okuyun.

## Knowledge ve action kapsamı

Bu model PK/FK ilişkileri olan normal CRUD verisidir ve read-only Knowledge örneklerine temel olur. AI action/tool procedure uygunluğu ayrı kurallarla denetlenir. FK'li bu laboratuvarı bir action örneğinin tüm gereksinimlerini sağlıyor kabul etmeyin; ilgili action sayfasındaki bağımsız schema, onay ve transaction şartlarını izleyin.

**Doğrulama düzeyi:** SQL, Server native sözleşmesi ve temel MySQL DDL referansıyla karşılaştırılmıştır. Bu doküman hazırlanırken canlı Classic Server üzerinde çalıştırılmamıştır.

**Kaynaklar:** [StarDataParadise native SQL sözleşmesi](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/contracts/sql/native-sql-v1.md), [MySQL CREATE DATABASE](https://dev.mysql.com/doc/refman/8.4/en/create-database.html), [MySQL CREATE TABLE](https://dev.mysql.com/doc/refman/8.4/en/create-table.html), [implicit commit](https://dev.mysql.com/doc/refman/8.4/en/implicit-commit.html).
