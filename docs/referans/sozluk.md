---
title: "Terimler sözlüğü"
slug: "/referans/sozluk"
---

# Terimler sözlüğü

Bu sözlük kitap boyunca kullanılan kavramları birbiriyle ilişkilendirir. Terim bir API adıysa ilgili SDK sayfasındaki gerçek imzayı esas alın.

| Terim | Anlamı ve bu kitaptaki karşılığı |
| --- | --- |
| Instance | Kendi yapılandırması, portu ve veri dizini olan çalışan Server örneği |
| Database | Veritabanı kataloğu; özgün adlandırmada `main` gibi üst bağlam |
| Schema | Nesneleri gruplayan ad alanı; özgün motorda `public` gibi |
| Table | Belirli sütun yapısına uyan satırların saklandığı nesne |
| Row | Bir kaydın sütun değerleri |
| Column | Tipi ve kuralları tanımlanmış veri alanı |
| Primary key | Bir satırı benzersiz tanımlayan anahtar; bileşik olabilir |
| Foreign key | Başka bir tablodaki anahtara bağlı veri bütünlüğü kuralı |
| Constraint | NOT NULL, UNIQUE, CHECK veya anahtar gibi geçerli veri koşulu |
| Index | Uygun sorgu erişimini hızlandırabilen ayrı veri yapısı |
| View | Saklanmış sorgu tanımı üzerinden sunulan görünüm |
| Sequence / identity | Desteklenen profilde sıralı kimlik üretimiyle ilgili nesne/alan davranışı |
| DDL | Tablo ve benzeri nesneleri oluşturan/değiştiren SQL ailesi |
| DML | INSERT, UPDATE, DELETE gibi veri değiştiren SQL ailesi |
| Projection | SELECT'in çıktı olarak seçtiği sütun/ifadeler |
| Predicate | WHERE veya JOIN ON içinde doğru/yanlış/UNKNOWN olabilen koşul |
| NULL | Bir SQL değerinin bilinmediğini veya mevcut olmadığını temsil eden özel durum |
| JOIN | İlişkili satırları bir sonuçta birleştirme |
| Aggregate | COUNT/SUM gibi bir grup satırdan sonuç üretme |
| CTE | WITH ile adlandırılan sorgu ifadesi |
| Transaction | Birlikte commit/rollback edilen iş birimi |
| Autocommit | Bağımsız yazmanın açık transaction olmadan kendi işleminde tamamlanması |
| Commit | Transaction'ın kalıcı sonucunu oluşturma isteği |
| Rollback | Henüz kalıcılaşmamış transaction değişikliklerini geri alma |
| Savepoint | Açık transaction içinde kısmi geri dönüş noktası |
| WAL | Kurtarma için kullanılan yazma öncesi günlük ailesi |
| LSN | Belirli bir günlük/sonuç sözleşmesinin sıralama konumu; farklı backend'lerde aynı fiziksel anlamı varsaymayın |
| Prepared statement | SQL kaynağı ve parametreleri ayrı hazırlanmış ifade |
| Bind / parameter | SQL metnine eklenmeden türüyle iletilen değer |
| Cursor / result reader | Sonuç satırlarını tüketen oturum kaynağı |
| Batch / fetch | Sonuçların sınırlı parçalarda alınması |
| Exact decimal | Ondalık değeri kayan nokta yuvarlamasına zorlamadan taşıyan tür |
| SQLSTATE | Hatanın standartlaşmış sınıflandırma alanı |
| Capability | Bağlı sunucunun gerçekten sunduğunu bildirdiği özellik |
| Wire v1 | StarDataParadise'ın tipli istemci/sunucu aktarım sözleşmesi |
| Classic | Kaynakta tanımlanan Classic tabanlı motor/protokol yolu |
| Native SQL | Ayrı native oturumda backend SQL'ini ve etkin uzantıları yürütme yolu |
| C ABI | C ile uyumlu binary çağrı ve bellek sözleşmesi |
| RAII | C++ kaynağının nesne yaşam süresiyle yönetilmesi |
| Request token | Wire yazma/commit isteğinin kalıcı sonucunu sorgulamaya yarayan kimlik |
| Unknown outcome | İsteğin kalıcı sonucunun eldeki kanıtla çözülememesi |
| Knowledge | Native ortamda tipli, parametreli, yetkili salt okunur kaynak |
| Conversation | AI modeli, bellek ve araç politikasını bağlayan konuşma nesnesi |
| Run | Kaydedilmiş AI yürütmesinin kimlik/durum kaydı |
| Worker | Kuyruğa alınmış işi yürüten ayrı süreç |
| Action | Onay politikası ve snapshot ile bağlanan araç eylemi |
| Stale snapshot | Hazırlama/onay sırasında görülen koşulların artık güncel olmaması |
| Migration | Şema ve gerekli veri dönüşümünü sürümlü olarak uygulama adımı |
| Idempotency | Aynı iş isteğinin tekrarının yeni bir dış etki oluşturmamasını sağlayan tasarım özelliği |

## Sık karışan üç ayrım

**Veritabanı ile instance:** Bir instance bir sunucu sürecinin işletim sınırıdır; SQL'deki database/schema nesnesi veri kataloğunun parçasıdır. Yeni database oluşturmak otomatik olarak yeni port ve Windows hizmeti açmaz.

**Primary key ile index:** Birincil anahtar veri bütünlüğü kuralıdır. Özgün motor kaynak testleri, sorgu erişim indeksi için ayrı CREATE INDEX etkisini gösterir. Başka bir veritabanından bildiğiniz fiziksel indeks varsayımını bu profile doğrudan taşımayın.

**AI turu ile araç transaction'ı:** Konuşma/run kaydının commit'i ile veri değiştiren aracın kendi commit'i ayrı olabilir. İkisinin hata ve başarı durumunu tek bir boolean alana sıkıştırmak teşhisi ve doğru kullanıcı mesajını zorlaştırır.

## Kaynaklar

- [StarDataParadiseServer / SQL_COMPATIBILITY.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_COMPATIBILITY.md)
- [StarDataParadiseServer / tests/relations_smoke.cpp](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/tests/relations_smoke.cpp)
- [StarDataParadiseServer / contracts/sql/native-sql-v1.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/contracts/sql/native-sql-v1.md)
- [StarDataParadiseDLLler / ABI.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseDLLler/blob/3199235c9641733332e9b8c82f9e875170c4eedb/ABI.md)
