---
title: "Kullanıcılar, roller ve tablo yetkileri"
slug: "/veritabani/kullanicilar-roller"
---

# Kullanıcılar, roller ve tablo yetkileri

**Kapsam:** original wire v1 `sql_security_v1`. Native AI onay rolleriyle aynı komut kümesi varsayılmamalıdır.

Bir veritabanı hesabı, uygulamanın veya insanın hangi işlemleri yapabileceğini tanımlar. Geliştirme sırasında yönetici hesabıyla her şeyin çalışması, üretim uygulamasının aynı yetkiye ihtiyaç duyduğu anlamına gelmez. Okuma ekranı ile şema değiştiren dağıtım işlemi farklı sorumluluklardır.

## Kullanıcı ile rol farkı

Kullanıcı kimliği doğrulanan hesaptır. Rol, bir yetki kümesini isimlendirir. Aynı işi yapan birkaç hesaba tek tek bütün yetkileri vermek yerine rolü atayabilirsiniz.

Aşağıdaki örnekleri yönetici oturumunda, açık kullanıcı transaction'ı dışında çalıştırın:

~~~sql
CREATE USER rapor_okuyucu;
CREATE ROLE satis_raporlama;

GRANT SELECT ON TABLE main.public.musteriler TO ROLE satis_raporlama;
GRANT SELECT ON TABLE main.public.siparisler TO ROLE satis_raporlama;
GRANT satis_raporlama TO USER rapor_okuyucu;
~~~

CREATE USER, parolası hazır ve etkin bir hesap yaratmaz; kaynak belgesine göre hesap başlangıçta devre dışıdır. Parola, kimliği doğrulanmış ayrı password_set işlemiyle belirlenir. CLI konsolunda:

~~~text
\password rapor_okuyucu
~~~

Yönetici başka kullanıcının parolasını sıfırlayabilir. Kullanıcı kendi parolasını değiştirirken eski parolayı doğrulaması gerekir. Parolayı CREATE USER SQL'ine eklemeyin; incelenen gramerde password clause yoktur.

## Yetkiyi ihtiyaç kadar vermek

Sipariş uygulaması müşterileri ve ürünleri okuyabilir, stok değiştirebilir, sipariş ve kalem ekleyebilir. Bu işin otomatik olarak DDL veya HISTORY yetkisine ihtiyacı yoktur.

~~~sql
CREATE ROLE siparis_yazari;
GRANT SELECT ON TABLE main.public.musteriler TO ROLE siparis_yazari;
GRANT SELECT, UPDATE ON TABLE main.public.urunler TO ROLE siparis_yazari;
GRANT SELECT, INSERT ON TABLE main.public.siparisler TO ROLE siparis_yazari;
GRANT SELECT, INSERT ON TABLE main.public.siparis_kalemleri TO ROLE siparis_yazari;
~~~

Bu rol örnek bir başlangıçtır. Sipariş iptali güncelleme gerektiriyorsa ilgili tablo UPDATE yetkisini bilinçli ekleyin. Fiziksel silme gerekmiyorsa DELETE vermeyin. Rol adları izin verilen iş akışını belgelemeye yardımcı olmalıdır.

Yetkiler global, database, schema veya nesne düzeyinde verilebilir. Daha geniş kapsam, gelecekte o kapsama eklenecek nesneler bakımından da değerlendirilmelidir. Bir uygulamaya bütün database üzerinde ALL vermek, bugünkü dört tablodan daha geniş bir yetki anlamı taşıyabilir.

## Güncel yetki kontrolü

Server yetkileri yalnız bağlantı açılırken kontrol etmez; prepare, execute, fetch ve korumalı yönetim çağrılarında güncel katalogdan değerlendirir. Rol veya yetki kaldırıldığında mevcut bağlantının eski hakları süresiz koruyacağını varsaymayın.

~~~sql
REVOKE SELECT ON TABLE main.public.siparisler
FROM ROLE satis_raporlama;
~~~

GRANT, REVOKE ve parola güncellemeleri autocommit işlemleridir. Bunları bir sipariş transaction'ının içine ekleyerek tek iş olarak geri alınabileceklerini varsaymayın. Kayıp yönetim commit cevabında actor'a bağlı outcome kuralları ayrıca önemlidir.

## View ve rutin yetkileri

Bir view'ın okunması temel tablonun yetkisini atlamaz; invoker davranışında alt nesne SELECT kontrolü bulunur. PL/SQL rutinleri de çağıranın yetkilerini kullanır. Rutin çalıştırma izni, rutinin içeride eriştiği her tabloya koşulsuz erişim sağlamak için tasarlanmış bir açık kapı değildir.

Katalog listeleri de filtrelenir. `\tables` sonucunda tablo görünmüyorsa nesne adı yanlış olabileceği gibi ilgili hesabın görünürlük yetkisi yetersiz olabilir. Tanı koyarken hesabı, hedef nesnenin tam adını ve gerekli işlemi birlikte kontrol edin.

## Bağlantı havuzu ve hesap sınırı

Oturum reset işlemi hazır ifadeleri, sonuçları ve bekleyen transaction durumunu temizler; TLS bağlantısına bağlı actor kimliğini başka kullanıcıya dönüştürmez. Çok kiracılı uygulamada tek bağlantıyı “şimdi başka kullanıcıymış gibi” kabul ederek dolaştırmayın. Tenant ayırımı ve uygulama erişim kontrolleri ayrıca tasarlanmalıdır.

**Kaynaklar:** [SQL security ve session kuralları](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_SECURITY.md), [GRANT/REVOKE grameri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/sql/SQL.ebnf), [CLI parola yönetimi](https://github.com/ParadiseIncDevelopers/StarDataParadiseCli/blob/95f07c6046662bfc3a49dc2ccced36898b0db07b/CLI.md).
