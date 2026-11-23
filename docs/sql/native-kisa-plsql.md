---
title: "Native PL/SQL: LET, kısa gövde ve satır cursor'ı"
slug: "/sql/native-kisa-plsql"
---

# Native PL/SQL: LET, kısa gövde ve satır cursor'ı

**Kapsam:** StarDataParadise native kısa SQL/PLSQL dil ailesi. [Original PL/SQL](plsql.md) sayfasındaki motor ve sözdizimiyle aynı profil olarak okunmamalıdır.

Bu native özellikler yerleşik stored procedure derleyicisinin tip, scope, cursor ve dönüşüm mekanizmalarını kullanır. Yeni bir COMPACT komutu açılmaz; ilgili Server desteği bulunduğunda dil biçimleri doğrudan derlenir. SQL metnini istemci tarafında regex ile uzun forma dönüştürmeniz gerekmez.

Örnek nesneleri [native laboratuvarındaki](../veritabani/native-laboratuvar.md) `sdp_lab` database'inde oluşturun. Native SDK'ya her CREATE gövdesini içindeki noktalı virgüllerle birlikte **tek SQL ifadesi** olarak gönderin. SDK metnine `DELIMITER` eklenmez; bu, bazı etkileşimli istemcilerin ayırıcı komutudur.

## AS RETURN ile tek ifadeli fonksiyon

~~~sql
CREATE FUNCTION sdp_lab.kdvli_tutar(p_tutar DECIMAL(12,2))
RETURNS DECIMAL(14,2)
DETERMINISTIC NO SQL
AS RETURN p_tutar * 1.20;
~~~

~~~sql
SELECT sdp_lab.kdvli_tutar(750.00);
~~~

Beklenen sayısal sonuç 900.00'dır. Yüzde 20 burada yalnız aritmetik öğretim örneğidir; uygulamanın gerçek vergi oranı veya mali kuralı olarak kabul edilmemelidir. Fonksiyon native return tipi dönüşümünü kullanır. NULL girdisi, çarpma ifadesinin NULL davranışını korur.

## LET ve WHEN DO

~~~sql
CREATE PROCEDURE sdp_lab.stok_ozeti(p_esik BIGINT)
AS
    LET sayi = (
        SELECT COUNT(*) FROM sdp_lab.urunler WHERE stok < :p_esik
    );
    LET uyari BIGINT = 0;
    WHEN sayi > 0 DO SET uyari = 1;
    SELECT :sayi, :uyari;
END;
~~~

~~~sql
CALL sdp_lab.stok_ozeti(10);
~~~

Başlangıç verisinde Monitör ve USB Hub eşik altındadır. Sonuçta sayı 2, uyarı 1 beklenir.

LET, yürütme o bildirime ulaştığında initializer'ı çalıştırır. Tip, initializer değerini sonradan tahmin ederek değil native ifade metadata'sını hazırlama aşamasında değerlendirerek belirlenir. Slotun tipi çağrı boyunca sabit kalır. Sonraki SET işlemi normal dönüşüm/taşma denetimine tabidir.

NULL tek başına yeterli tip bilgisi vermediği için:

~~~sql
LET secim BIGINT = NULL;
~~~

gibi açık tip kullanın. DECIMAL ölçeği ve çıkarılan metin uzunluğu korunur; kısa bir metinden çıkarılmış slota sonradan çok uzun metin atamanın otomatik sınırsız büyüme sağlayacağını varsaymayın. ENUM, SET, GEOMETRY ve VECTOR ifadelerinde açık tip gereksinimi belgelenmiştir.

## Yerel isim ve SQL sütunu

Kısa gövdelerde ve kısa local biçimlerinde embedded SQL içindeki yerel değerler `:ad` şeklinde yazılır. Prosedür hesabında `sayi > 0` gibi yalın local adı kullanılabilir; SELECT ve WHERE içinde `:sayi`, `:p_esik` biçimi hangi değerin parametre olduğunu açıklar.

Bu iki nokta üst üste işareti, native SDK'nın positional `?` parametresiyle karıştırılmamalıdır. `?` dış istemcinin statement'a bağladığı değerdir. `:p_esik` derlenmiş routine içindeki local/parametre çözümlemesidir. Bir dış native.execute sorgusuna gelişigüzel `:id` koymak bu özelliği kullanmak sayılmaz.

Aynı scope içinde aynı isimle ikinci LET hatadır. İç scope dış değişkeni gölgeleyebilir; iç blok bitince dış değer yeniden görünür. Değişken initializer'ının hazırlanması tamamlanmadan yeni isim görünür hale gelmez.

## FOR ile tipli satır gezmek

~~~sql
CREATE PROCEDURE sdp_lab.toplam_stok()
AS
    LET toplam BIGINT = 0;
    FOR satir IN
        SELECT id, stok FROM sdp_lab.urunler ORDER BY id
    DO
        SET toplam = toplam + :satir.stok;
    END FOR;
    SELECT :toplam;
END;
~~~

~~~sql
CALL sdp_lab.toplam_stok();
~~~

Beklenen sonuç 78'dir. Aynı hesap tek SELECT SUM(stok) ile daha yalın yapılabilir; örnek cursor scope'unu öğretir. Satır alanları readonly'dir, yalnız döngü scope'unda bulunur ve sorgu çıktı adları benzersiz olmalıdır.

Boş sorguda gövde çalışmaz. `LEAVE satir` döngüyü sonlandırır; `ITERATE satir` sonraki tura geçer. RETURN veya hata ile scope'tan çıkışta native cursor temizliği uygulanır. Bu yapı her sonucu sınırsız biçimde belleğe alan bir dizi değildir; native cursor'un mevcut materialize/spill davranışı ve cached bir satır kullanımı geçerlidir.

## SHOW EXPANDED ile inceleme

~~~sql
SHOW EXPANDED PROCEDURE sdp_lab.stok_ozeti;
~~~

~~~sql
SHOW EXPANDED
SELECT * EXCLUDE(stok) FROM sdp_lab.urunler;
~~~

Sorgu formu prepare/bind bilgisi ve output metadata sağlar; sorguyu optimize edip yürütmüş gibi bir performans ölçümü değildir. Routine çıktısı executable SQL değil `compiler_ir` olarak etiketlenen derlenmiş talimat gösterimidir. Parametre değerleri yerine placeholder'lar korunur; routine incelemesi native kaynak inceleme yetkisine tabidir.

**Doğrulama notu:** Yukarıdaki kullanım kaynak fixture'larıyla karşılaştırılmıştır. Kaynakta kayıtlı PASS sonuçları geliştirici kabul kayıtlarıdır; bu dokümantasyonun hazırlanması sırasında yeniden çalıştırılmış testler değildir.

**Kaynaklar:** [native LET/scope/cursor kuralları](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/compatibility/upstream/sql-short-native.md), [kısa prosedür ve fonksiyon kabul örnekleri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/compatibility/tests/sql_short_native_acceptance.py), [native SQL tek ifade ve oturum sözleşmesi](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/contracts/sql/native-sql-v1.md).
