---
title: "PL/SQL: fonksiyon, prosedür ve sunucu mantığı"
slug: "/sql/plsql"
---

# PL/SQL: fonksiyon, prosedür ve sunucu mantığı

**Kapsam:** original wire v1 motorunun belgelenmiş PL/SQL alt kümesi. Oracle PL/SQL veya MySQL stored procedure sözdiziminin tamamı olarak okunmamalıdır.

SQL tek bir veri işlemini tanımlar. PL/SQL, SQL ile tipli değişkenleri, koşulları ve denetimli akışları bir araya getirir. Tekrarlanan bir hesabı fonksiyonda tutabilir veya birden çok kontrollü işlemi prosedür içinde ifade edebilirsiniz. Bu, uygulamanın bütün iş akışını sunucuya taşıma zorunluluğu getirmez.

## Basit fonksiyon

~~~sql
CREATE FUNCTION public.stok_getir(p_urun_id IN BIGINT)
RETURN BIGINT AS
BEGIN
    RETURN (
        SELECT stok
        FROM public.urunler AS u
        WHERE u.id = :p_urun_id
    );
END;
~~~

Çağrı:

~~~sql
SELECT public.stok_getir(101);
~~~

Başlangıç laboratuvarında 20 döner. Fonksiyon içindeki SQL'de `:p_urun_id` yerel parametreyi bağlar. `u.id` ise tablonun sütunudur. Bu ayrım aynı adlı parametre ve sütunun yanlış çözülmesini önler.

Skaler alt sorgu sıfır satır döndürürse NULL oluşabilir; birden fazla satır hata üretir. Bu örnekte PK ile filtreleme en fazla bir satırı sağlar. “Ürün bulunamadı” davranışını uygulamanın iş kuralına göre ele alın.

## Prosedür ve OUT parametre

~~~sql
CREATE PROCEDURE public.siparis_tutar_getir(
    p_siparis_id IN BIGINT,
    p_toplam OUT DECIMAL(12,2)
) AS
BEGIN
    SELECT toplam INTO p_toplam
    FROM public.siparisler
    WHERE id = :p_siparis_id;
END;
~~~

~~~sql
CALL public.siparis_tutar_getir(1001, NULL);
~~~

OUT değeri 1450.00 olarak, tanım sırasına göre tipli sonuçta döner. SELECT INTO tam olarak bir satır bekler: kayıt yoksa `no_data_found`, birden fazla varsa `too_many_rows` hatası oluşur. Fonksiyon içindeki skaler sorgu ile SELECT INTO'nun “kayıt yok” davranışı aynı değildir.

## Değişken ve koşul

~~~sql
CREATE FUNCTION public.adet_gecerli(p_adet IN BIGINT)
RETURN BOOLEAN AS
BEGIN
    IF p_adet > 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
~~~

Bu fonksiyon kararın yeniden kullanılabilir bir parçasını gösterir. Bir tablo alanının her yazmada pozitif olmasını garanti etmek için ayrıca CHECK tanımlamak daha doğrudan olabilir. Fonksiyon, uygulamanın hiç çağırmadığı bir yazmayı kendiliğinden denetlemez.

Desteklenen akış yapıları IF/ELSIF/ELSE, searched CASE, FOR, WHILE, LOOP, EXIT, CONTINUE, RETURN, RAISE ve EXCEPTION handler'larını içerir. Koleksiyon, RECORD ve cursor değerleri de belgelenmiştir; sıradan SQL sütunları ise skaler kalır.

## Cursor ve birden çok sonuç

Prosedür SELECT INTO ile tek satır okuyabilir veya REFCURSOR üzerinden birden çok satır döndürebilir. OUT REFCURSOR adlandırılmış sonuç kümesi üretir. Scalar OUT/IN OUT değerleri önce `out` kümesinde, EMIT sonuçları ardından, OUT cursor sonuçları da bildirim sırasıyla gelir.

SDK kodunda yalnız ilk sonucu okuyup çağrıyı tamamlanmış saymayın. Seçtiğiniz dilin `nextSet` / sonraki sonuç API'siyle kalan sonuçları ele alın veya kapatın. RECORD/COLLECTION değerleri tipli ve boyut sınırlıdır; genel bir JSON belge deposu varsayılmaz.

## Yetki ve transaction

Rutinler çağıranın yetkileriyle çalışır; sunucu yöneticisinin yetkisini kendiliğinden ödünç almaz. İç SQL aynı transaction'ı kullanır. Prosedürün başarıyla dönmesi, çağıran bağlantının commit yaptığı anlamına gelmez.

Yazma yapan bir prosedürü autocommit'te çalıştırırken token gereksinimi doğabilir. SDK hata/sonuç modelini kullanın; birden fazla sonuç veren CALL akışını sıradan tek satırlı SELECT gibi işlemeyin.

## Sürüm ve çalışma sınırları

`CREATE OR REPLACE` rutin kimliğini koruyarak revizyonu ilerletir. Bağımlı tablo veya rutin sürümü değişirse yeniden bağlama gerekir. Şema migration'ının ardından ilgili rutinleri aynı kaynakla yeniden oluşturarak bağımlılıklarını güncel şemaya bağlayın.

Belgelenmiş yürütme sınırları 100.000 adım, 32 çağrı derinliği, 1 MiB frame belleği ve çağrı ağacı başına iki saniyedir. Bunlar genel amaçlı uzun çalışan arka plan işi yazmak için uygun bir ortam olmadığını gösterir. Büyük iş parçalarını kısa veritabanı işlemlerine bölün.

**Alıştırma:** `stok_getir(999)` ile `siparis_tutar_getir(999, NULL)` çağrılarının neden farklı davranabileceğini açıklayın. Birincisi skaler sorgudan NULL üretebilir; ikincisi SELECT INTO'nun tek satır koşulunu ihlal eder.

**Kaynaklar:** [PL/SQL dil belgesi](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/PLSQL_LANGUAGE.md), [resmî hızlı başlangıç rutinleri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/docs/coordination/S50_QUICKSTART.md), [PL/SQL grameri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/sql/SQL.ebnf).
