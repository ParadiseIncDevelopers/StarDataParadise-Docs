---
title: "Java SDK: uyumluluk, yönetim API'leri ve sorun giderme"
slug: "/sdk/java/uyumluluk"
---

# Java SDK: uyumluluk, yönetim API'leri ve sorun giderme

> **Kapsam:** Java SDK 0.3.0. Desteklenen API'ler ile bir uygulama çatısının beklentileri ayrı ayrı değerlendirilmelidir.

JDBC arayüzlerini sunmak, JDBC standardının her isteğe bağlı özelliğini uygulamak anlamına gelmez. Sürücü desteklenmeyen işlemler için `SQLFeatureNotSupportedException` üretir. Bu belirgin hata, sessizce eksik sonuç döndürülmesinden daha kolay yönetilir. Bir ORM, raporlama aracı veya bağlantı havuzu eklemeden önce onun çalıştırdığı başlangıç ve metadata çağrılarını gözlemleyin.

## Destek sınırları

| Alan | SDK davranışı |
| --- | --- |
| Sonuç kümesi | İleri yönlü, salt okunur |
| Açık sonuç | Bağlantı başına bir sunucu sonucu |
| Transaction | Manuel commit/rollback ve savepoint |
| Katalog/şema | JDBC oturumu `main` / `public`; başka değere geçiş desteklenmez |
| Parametre | JDBC'de sıralı `?`; indeks 1'den başlar |
| Batch ve generated keys | Desteklenmeyen JDBC özellikleri arasında |
| XA | Desteklenmez |
| Native SQL/AI | Ayrı `SdpNativeConnection` |
| Otomatik yazma tekrarı | Yapılmaz |

Örneğin bir ORM, bağlantı açılır açılmaz `setReadOnly(true)` veya farklı schema seçimi yapabilir. Doğrudan JDBC sorgusu başarılı olsa bile ORM başlangıcı bu adımda başarısız olabilir. Kullandığınız çatıyı yapılandırmadan önce temel bağlantı ve parametreli SELECT örneğini bağımsız çalıştırmak sorunun yerini daraltır.

## Sunucuya özgü API'ler

`connection.unwrap(SdpConnection.class)` ile aşağıdaki işlemlere ulaşılır. Bu yöntemlerin varlığı, sunucunun ve kullanıcının hepsine erişim verdiği anlamına gelmez.

| Metot | Amaç |
| --- | --- |
| `capabilities()` | Oturum için özellik haritası |
| `catalogObjects()` | Katalog nesneleri ve sütun metadata'sı |
| `transactionOutcome(token)` | Wire receipt üzerinden commit durumunu sorgulama |
| `resetSession()` | Havuz dönüşünden önce oturum sıfırlama |
| `predict(model, features)` | Sunucunun model tahmin API'si |
| `jobStatus(jobId)` | Mevcut wire job durumunu okuma |
| `historyRead(target, revision, rowId)` | Wire History içeriği |
| `explainDecision(table, event, rowId)` | Decision inceleme |
| `adminHealth()` | Yetkili yönetici sağlık bilgisi |
| `cancelQuery(sessionId, requestId)` | İzinli ayrı oturumdan istek iptalini hedefleme |

Capability kontrolünü özellik ekrana açılmadan veya iş kabul edilmeden önce yapabilirsiniz. İzin kontrolünü sunucu yine yapar; uygulama kontrolü sunucu denetiminin yerine geçmez. History/job metotlarını ertelenmiş yeni SQL `HIST` ve `JOB` özellikleriyle karıştırmayın.

## Sorunu katmanına göre inceleyin

| Belirti | Önce kontrol edilecekler |
| --- | --- |
| Paket bulunamıyor | 0.3.0 artefaktının yapılandırılmış Maven kaynağında bulunması; yalnızca Central'a güvenilmemesi |
| `No suitable driver` | JAR ve bağımlılıkların çalışma zamanı classpath'inde bulunması; URL'nin `jdbc:sdp://` ile başlaması |
| TLS doğrulama hatası | CA PEM yolu, zincir, sertifikadaki ad ve `tlsName` |
| Unsupported connection property | Başka sürücüye ait URL/property seçeneklerinin kaldırılması |
| A prepared parameter is unbound | Her `?` için değer veya saf OUT kaydının yapılması |
| Açık sonuçla ilgili hata | Önceki `ResultSet` ve statement'ın kapanması |
| SQL sözdizimi veya capability hatası | Orijinal engine/bridge/native ayrımı ve sunucunun ilanı |
| `SQLFeatureNotSupportedException` | ORM/araç çağrısının destek tablosuyla karşılaştırılması |
| Belirsiz yazma sonucu | Token'ın saklanması ve yeni oturumdan outcome sorgusu |

Parolanın doğru olduğunu test etmek için TLS doğrulamasını kaldırmaya çalışmayın. Kimlik doğrulama hatası ile sertifika hatası farklı katmanlardadır. Önce TLS kurulmalı, ardından kullanıcı hesabı doğrulanmalıdır.

## Timeout ve iptal

Connection property'leri milisaniye, `Statement.setQueryTimeout` saniye kullanır. Bu iki değeri aynı sayıyla kopyalamak bekleme politikasını değiştirebilir. `setFetchSize` veya toplam satır sınırı bir timeout ayarı değildir.

Kaynak kılavuza göre `Statement.cancel()` bekleyen isteği iptal edip bağlantıyı kapatır. İptal edilen bağlantıyı sıradaki işe dağıtmayın. Yazma sırasında iptal veya ağ kopması olduğunda işlem sonucunun belirsiz olabileceğini göz önünde bulundurun; "istemci beklemeyi bıraktı" ile "sunucu hiçbir şey yapmadı" aynı durum değildir.

## Kabul kontrolü

Uygulamayı devreye almadan önce gerçek hedef endpoint'te küçük bir SELECT, parametreli INSERT, rollback ile geri alınan değişiklik, başarılı commit, NULL/decimal dönüşümü ve kaynakların kapanması akışlarını doğrulayın. Bu kontroller sizin şemanız, hesabınız ve sunucu ayarlarınız için anlamlıdır. Kaynak deposundaki testlerin varlığı, sizin dağıtımınızın aynı koşullarda çalıştığını tek başına göstermez.

## Kaynaklar

- [Java BUILD: kapsam ve kısıtlar](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/BUILD.md)
- [JDBC oturum seçenekleri](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/src/main/java/com/stardataparadise/sdk/JdbcSession.java)
- [SdpConnection yönetim API'si](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/src/main/java/com/stardataparadise/sdk/SdpConnection.java)
