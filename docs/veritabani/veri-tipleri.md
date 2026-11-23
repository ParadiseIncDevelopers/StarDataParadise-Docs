---
title: "Veri tiplerini doğru seçmek"
slug: "/veritabani/veri-tipleri"
---

# Veri tiplerini doğru seçmek

**Kapsam:** original wire v1 SQL motoru. Native/Classic veri tipleri ve değer sınırları birebir aynı değildir.

Veri tipi, bir alanın yalnız hangi değerleri saklayacağını değil karşılaştırma, aritmetik, NULL ve SDK dönüşüm davranışını da belirler. Her şeyi TEXT olarak saklamak ilk INSERT'i kolaylaştırabilir; fakat tarih sıralama, sayısal toplama ve veri doğrulama yükünü uygulamanın her noktasına taşır.

## Desteklenen temel tipler

| SQL tipi | Anlamı ve kullanım |
| --- | --- |
| BIGINT / INTEGER / INT | İşaretli 64 bit tam sayı; kimlik, adet, sayaç |
| DECIMAL(p,s) | Exact ondalık; fiyat, tutar, hassas ölçüm |
| BOOLEAN | TRUE/FALSE; nullable ise UNKNOWN mantığı |
| TEXT | Geçerli UTF-8 metin |
| BLOB | Metinden ayrı ikili veri |
| DATE | Takvim günü |
| TIME | Gün içindeki saat ve kesirli saniye |
| TIMESTAMP WITH TIME ZONE | UTC anı ve açık offset bilgisi |

`INTEGER` veya `INT` adına bakarak 32 bit sınır varsaymayın; bu motor bunları BIGINT ile aynı işaretli 64 bit kuralı altında belgeler. Sayı aralığı aşılırsa sessiz taşma yerine hata oluşur.

## Para için DECIMAL

~~~sql
CREATE TABLE public.odeme_ornegi (
    id BIGINT PRIMARY KEY,
    tutar DECIMAL(12,2) NOT NULL,
    onayli BOOLEAN NOT NULL
);
~~~

`DECIMAL(12,2)` toplam 12 basamak ve ondalık tarafta 2 basamak tanımlar. En büyük pozitif değer 9.999.999.999,99'dur. Precision 1–38 aralığındadır; scale precision'dan büyük olamaz. Ölçek dönüştürülürken yarım değerler sıfırdan uzağa yuvarlanır; yuvarlama sonrasında taşan değer reddedilir.

Bir JavaScript `Number`, Python float veya .NET double ile para değerini arada taşımak exact özelliğini kaybettirebilir. SDK'nın decimal türünü, Java BigDecimal veya .NET decimal gibi uygun karşılığını kullanın. .NET decimal'ın aralığı, SQL DECIMAL(38,s)'in bütün değerlerini kapsamayabilir; sınırdaki değerleri SDK'nın belgelenmiş exact gösterimiyle değerlendirin.

## Metin ve karşılaştırma

TEXT UTF-8 içerir; BLOB keyfi byte dizisidir. Bir PDF'yi önce metin gibi yorumlayıp sonra tekrar byte'a dönüştürmek yerine BLOB olarak taşıyın. Büyük dosyayı her ürün okumasında taşımak yerine, uygulama mimarinizde dosya saklama ve metadata bağlantısını ayrıca tasarlamak çoğu zaman daha kullanışlıdır.

Varsayılan metin sıralaması UTF-8 bayt düzenidir. `I`, `ı`, `İ` ve `i` için Türkçe sözlük sırası gerekiyorsa sorgu/index collation tercihini açıkça yapın. Kullanıcı adı eşitliği, arama normalizasyonu ve ekranda sıralama birbirinden farklı ihtiyaçlar olabilir.

## Tarih, saat ve zaman anı

~~~sql
CREATE TABLE public.teslimat_ornegi (
    id BIGINT PRIMARY KEY,
    teslim_gunu DATE,
    planlanan_saat TIME,
    kayit_ani TIMESTAMP WITH TIME ZONE
);

INSERT INTO public.teslimat_ornegi
    (id, teslim_gunu, planlanan_saat, kayit_ani)
VALUES (
    1,
    DATE '2026-11-24',
    TIME '14:30:00',
    TIMESTAMP WITH TIME ZONE '2026-11-23T10:15:00+03:00'
);
~~~

DATE bir takvim gününü, TIME gün içindeki saati, offset içeren timestamp bir anı temsil eder. Original TIME'ı native Classic'in işaretli ve 24 saati aşabilen süre gösterimiyle karıştırmayın.

DATE belgelenen aralıkta 0001–9999 yıllarını kullanır. TIME dokuz kesirli saniye basamağına kadar desteklenir ve leap second kabul etmez. Timestamp açık Z veya en fazla ±14:00 offset gerektirir; karşılaştırma UTC anına göre yapılır. `Europe/Istanbul` gibi bölge adı saklandığını varsaymayın; bölge kuralları uygulamanın ayrı ihtiyacı olabilir.

## NULL'ın tipi

NULL hiçbir alan için otomatik “boş string” değildir. SDK bir parametreyi NULL olarak gönderirken hedef SQL tipi bilinmelidir. Bu, özellikle `WHERE :deger IS NULL` gibi bağlamı yetersiz ifadelerde veya hazırlanan ifadelerde önem taşır.

NOT NULL, CHECK ve DEFAULT farklı sorulara cevap verir: değer eksik olabilir mi; sağlanan değer geçerli mi; değer sağlanmazsa ne kullanılsın? Örneğin `CHECK (stok >= 0)` NULL'ı tek başına reddetmez. Stok her zaman bilinmeli diyorsanız NOT NULL da gereklidir.

**Kaynaklar:** [SQL tip kuralları](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_COMPATIBILITY.md), [wire parametre tipleri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/contracts/sql/SQL_RPC_V1.md), [native SQL tip farkları](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/contracts/sql/native-sql-v1.md).
