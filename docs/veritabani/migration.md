---
title: "Şema değişiklikleri ve migration düzeni"
slug: "/veritabani/migration"
---

# Şema değişiklikleri ve migration düzeni

**Kapsam:** original wire v1 SQL. Transactional DDL, şema sürümleri ve doğrulanmış ALTER TABLE uygulaması.

Migration, uygulamanın veri yapısındaki kontrollü değişikliktir. Yeni bir sütun eklemek yalnız SQL komutundan ibaret değildir: mevcut satırlar, çalışan uygulamanın eski sürümü, index'ler, view'lar ve rutinler de bu değişiklikle uyumlu olmalıdır.

## Yeni sütunu aşamalı eklemek

Müşteriler için tercih edilen dil alanı eklediğimizi düşünelim. Mevcut satırların hiçbiri bu bilgiyi taşımıyor. İlk adım nullable sütun eklemektir:

~~~sql
ALTER TABLE public.musteriler
ADD COLUMN tercih_dili TEXT;
~~~

Sonra mevcut kayıtların değerini iş kuralına göre doldurun:

~~~sql
UPDATE public.musteriler
SET tercih_dili = 'tr'
WHERE tercih_dili IS NULL;
~~~

Buradaki `'tr'` bir örnek varsayımdır. Gerçek müşteri dili bilinmiyorsa otomatik Türkçe kabul etmek doğru veri politikası olmayabilir; nullable bırakmak daha dürüst bir modeldir.

İş kuralı bütün müşteriler için zorunlu dil gerektiriyorsa önce kalan eksik kayıtları kontrol edin:

~~~sql
SELECT COUNT(*) FROM public.musteriler
WHERE tercih_dili IS NULL;
~~~

Sıfır sonucundan sonra:

~~~sql
ALTER TABLE public.musteriler
ALTER COLUMN tercih_dili SET NOT NULL;
~~~

İncelenen implementation NOT NULL, DEFAULT, sütun adı/tipi ve constraint değişikliklerini destekleyen ALTER dalları içerir. Bu davranış, erken etap açıklamasında yalnız ADD COLUMN yazıyor diye yok sayılmamalıdır; yine de kurulu binary'nin capabilities ve sürüm uyumunu doğrulayın.

## Default geçmiş veriyi açıklamaz

Yeni INSERT'ler için varsayılan:

~~~sql
ALTER TABLE public.musteriler
ALTER COLUMN tercih_dili SET DEFAULT 'tr';
~~~

DEFAULT bir iş kuralıdır. Değeri atlanan yeni yazmalar için kullanılır; mevcut kayıtların ne ifade ettiğini tek başına düzeltmez. Backfill adımını ve varsayılanın gerekçesini migration notunda ayrı yazın.

## Uygulamayla uyum

Bir dağıtım sırasında eski ve yeni uygulama sürümleri aynı anda çalışabilir. Önce yeni nullable sütunu eklemek, uygulamayı onu kullanacak biçimde güncellemek, veriyi doldurmak ve en son zorunluluk eklemek bu geçişi yönetmeyi kolaylaştırır.

Yeni NOT NULL sütunu eski uygulama hiç göndermiyorsa eski yazmalar bozulabilir. DEFAULT bunu belirli durumlarda çözebilir; fakat yanlış veriyi sessizce oluşturma pahasına yapılmamalıdır. Uyum planında hem yeni hem eski yazma yollarını düşünün.

## Ad değiştirme ve silme

~~~sql
ALTER TABLE public.musteriler
RENAME COLUMN tercih_dili TO iletisim_dili;
~~~

Bu komutun ardından eski sütun adını kullanan SQL, SDK kodu veya rutin kaynağı güncellenmelidir. Bir sütunun adı değişince bütün sorguların kendiliğinden yeni adı keşfedeceğini varsaymayın.

DROP COLUMN veya tip değiştirme, bağlı index ve FK nedeniyle reddedilebilir. Daralan bir tipe dönüşüm mevcut verilerle uyumsuz olabilir. Rutinler bağımlı şema sürümü değiştiğinde yeniden derleme isteyebilir; `CREATE OR REPLACE` ile güncel şemaya bağlanmaları gerekir.

## Transaction ve kaynak bütçesi

Original DDL caller transaction'ına dahil olabilir. Küçük migration'ı tek transaction içinde yapmak, kısmi değişikliklerin kalıcılaşmasını önleyebilir. Büyük tablo yeniden yazımı ise transaction'ın satır/byte sınırlarını aşabilir. “Tek transaction her boyutta daha güvenlidir” genellemesi doğru değildir; gerçek veri hacmiyle uygun bakım planı gerekir.

Migration dosyalarına sıra numarası ve açıklayıcı ad verin. Örneğin `001_ilk_sema.sql`, `002_musteri_dili.sql`. Çalıştırılmış dosyayı yerinde değiştirmek yerine yeni migration oluşturun. Hangi dosyanın hangi sürümde uygulandığını uygulamanın dağıtım kaydında tutun.

## Geri dönüş

Sütun eklemek çoğu zaman geri alınabilir; sütun silmek veri kaybı yaratabilir. Uygulama rollback'i ile database rollback'i aynı işlem değildir. Yedekten geri dönmek, yedek sonrasındaki yeni yazmaları da etkileyebilir. Bu nedenle geri dönüş yöntemini değişikliğin türüne göre tasarlayın, test hedefinde restore yapın ve şema ile uygulama sürümünü birlikte doğrulayın.

**Kaynaklar:** [ALTER TABLE grameri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/sql/SQL.ebnf), [ALTER TABLE uygulaması ve bağımlılık kontrolleri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/sql/relational.cpp), [rutin bağımlılıkları](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/PLSQL_LANGUAGE.md).
