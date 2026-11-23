---
title: "SQL'e giriş ve çalışma biçimi"
slug: "/sql/"
---

# SQL'e giriş ve çalışma biçimi

SQL, veriyi nasıl saklayacağınızı ve hangi veriye ihtiyacınız olduğunu ifade ettiğiniz dildir. Bir müşteri ekranı için belirli müşteriyi okur, sipariş oluştururken birden çok tabloyu değiştirir, raporda satırları gruplarsınız. SQL'i öğrenirken yalnızca komut ezberlemek yeterli değildir: bir sorgunun hangi satırları etkilediğini, sonucun ne zaman kalıcı olduğunu ve uygulamanın hata durumunda ne yapacağını birlikte düşünmelisiniz.

Bu bölümün çalıştırılabilir örnekleri **StarDataParadise'ın original wire v1 SQL motoru** içindir. Server 0.5.2 kaynak ağacındaki SQL grameri ve sözleşmeleri temel alınmıştır. Classic/native SQL yolunda farklı bir ayrıştırıcı ve veri tipi kümesi bulunur. Sayfadaki bir komutu sırf SQL olduğu için diğer yolda aynı şekilde kullanmayın; [profil farkları](../veritabani/classic-farklari.md) geçiş tablosunu okuyun.

## Bir SQL işleminin yaşamı

İstemci SQL metnini sunucuya hazırlar; sunucu sözdizimini, nesneleri, parametre tiplerini ve yetkileri denetler. Ardından yürütme aşaması gelir. Bir SELECT sonuç kümesi üretir; INSERT, UPDATE ve DELETE etkilenen satır sayısı üretir. Açık transaction varsa değişikliklerin kalıcı hale gelmesi için istemcinin commit çağrısı gerekir. Okuma sonuçları tüketilmeli veya kapatılmalıdır; aynı bağlantı üzerinde yalnızca bir sonuç açık kalabilir.

Bu ayrım uygulama kodunda üç ayrı soruya karşılık gelir:

1. İfade doğru mu ve çalıştırmaya yetkim var mı?
2. Sonuçtaki satırları veya etkilenen satır sayısını okudum mu?
3. Yazmayı kalıcılaştırdım mı; commit cevabını kesin olarak aldım mı?

## Komut aileleri

| Aile | Amaç | Örnek |
| --- | --- | --- |
| Sorgulama | Satır seçmek ve hesaplamak | SELECT, JOIN, GROUP BY |
| Veri değiştirme | Satır eklemek, güncellemek, silmek | INSERT, UPDATE, DELETE |
| Yapı tanımlama | Veritabanı nesneleri oluşturmak | CREATE TABLE, ALTER TABLE |
| Yetki yönetimi | Kullanıcının erişimini belirlemek | GRANT, REVOKE |
| Yordamlar | Sunucuda kontrollü işlem yürütmek | CREATE FUNCTION, CALL |

Transaction kontrolünü ayrı bir SQL ailesi gibi düşünmek mümkündür; ancak original motorda bu kontrol protokol/SDK üzerinden yapılır. CLI içindeki `\begin` ve `\commit` terminal komutlarıdır. `BEGIN ... END` ise PL/SQL gövdesini ifade eder. Bu ikisini karıştırmayın.

## İlk sorgu

Önce [laboratuvarı](../veritabani/laboratuvar.md) kurun. İlk sorgumuz ürün kimliği, adı ve stok değerini okuyacak:

~~~sql
SELECT id, ad, stok
FROM public.urunler
WHERE stok > 0
ORDER BY id;
~~~

Başlangıç verisinde 101, 102 ve 103 kimlikli ürünler gelir. 104 numaralı ürünün stoku sıfırdır ve koşula uymaz. SQL, tabloyu değiştirmeden bu isteği yanıtlar.

`SELECT *` bütün sütunları seçer. Keşif sırasında faydalıdır; uygulamada ihtiyaç duyulan sütunları açıkça yazmak, bir tabloya yeni sütun eklendiğinde istemcinin beklediği sıra ve yapıyı korumaya yardımcı olur.

## Metin, ad ve parametre

SQL metni tek tırnak içinde yazılır: `'hazirlaniyor'`. Nesne adı tırnaksızsa ASCII harfleri küçük harfe katlanır. Çift tırnakla tanımlanmış bir ad, yazıldığı UTF-8 biçimini korur. Öğretici örneklerde taşınabilirlik ve rahat kullanım için `siparisler` gibi sade adlar kullanıyoruz.

Uygulama girdisi SQL metnine eklenmez. `WHERE id = :id` yazılır ve değer ayrıca bağlanır. İstemci API'si değerin BIGINT olduğunu bildirir. Parametreler tablo veya sütun adının yerine geçmez; dinamik sıralama gibi nesne seçimini uygulamada sabit bir izinli ad listesinden üretin.

## Önerilen öğrenme sırası

Önce SELECT ve filtreleme ile okuyun; ardından INSERT, UPDATE ve DELETE'i bir test transaction'ında deneyin. JOIN ve gruplama ile ilişkileri okuyun. Son olarak transaction, PL/SQL ve uygulama entegrasyonuna geçin. Her alıştırmanın beklenen sonucu başlangıç laboratuvarına göredir; veri değiştirilen denemeleri rollback ile bitirin veya ayrı test tablolarında yapın.

**Kaynaklar:** [SQL uyumluluğu](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_COMPATIBILITY.md), [SQL grameri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/sql/SQL.ebnf), [wire SQL sözleşmesi](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/contracts/sql/SQL_RPC_V1.md).
