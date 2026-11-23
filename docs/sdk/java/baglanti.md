---
title: "Java SDK: bağlantı, TLS ve oturum yaşam döngüsü"
slug: "/sdk/java/baglanti"
---

# Java SDK: bağlantı, TLS ve oturum yaşam döngüsü

> **Kapsam:** JDBC 0.3.0, wire v1. Native SQL için bu bağlantı dönüştürülmez; ayrı native oturum açılır.

Bir bağlantıda dört farklı bilgi bulunur: ağ adresi, sunucunun sertifika adı, güvenilen sertifika zinciri ve veritabanı hesabı. `127.0.0.1` ağ adresiyken `localhost` sertifikadaki ad olabilir. `tlsName` bu iki kavramı ayırır. CA dosyasının doğru olması tek başına yeterli değildir; sertifika adı da eşleşmelidir.

## Bağlantı biçimi ve seçenekler

URL biçimi `jdbc:sdp://host[:port]` şeklindedir. Kullanıcı ve parola URL içine yazılmaz. Veritabanı adı, sorgu parametresi veya ek yol içeren bir URL bu sürücüde geçerli değildir; örneğin `jdbc:sdp://localhost:7443/main` kullanmayın.

| Özellik | Açıklama ve varsayılan |
| --- | --- |
| `user` | Zorunlu kullanıcı adı |
| `password` | Zorunlu parola |
| `caFile` | Zorunlu CA PEM dosyası |
| `tlsName` | Doğrulanacak sertifika adı; belirtilmezse host |
| `connectTimeoutMs` | Bağlantı süresi; normal varsayılan 5.000 ms, JDBC login timeout ayarlanmışsa ondan türetilir |
| `queryTimeoutMs` | Normal varsayılan 10.000 ms |

İki timeout özelliği 100–120.000 ms aralığındadır. Sürücü tanımadığı connection property'lerini reddeder. Başka JDBC sürücüsünden kopyalanmış `sslmode`, `databaseName` veya `trustServerCertificate` seçeneklerini eklemeyin. Bu JDBC bağlantısı TLS kullanır.

## Tek yerde bağlantı üretin

Aşağıdaki sınıf, sonraki Java örneklerinin kullanabileceği **uygulama yardımcı sınıfıdır**. Ortam değişkenlerini işletim sistemi, IDE veya uygulama çalıştırıcınızdan verin; Java bir `.env` dosyasını kendiliğinden okumaz.

```java
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public final class SdpBaglantilari {
    private SdpBaglantilari() {}

    public static Connection ac() throws SQLException {
        var ayarlar = new Properties();
        ayarlar.setProperty("user", zorunlu("SDP_USER"));
        ayarlar.setProperty("password", zorunlu("SDP_PASSWORD"));
        ayarlar.setProperty("caFile", zorunlu("SDP_CA"));
        ayarlar.setProperty("tlsName", "localhost");
        ayarlar.setProperty("connectTimeoutMs", "5000");
        ayarlar.setProperty("queryTimeoutMs", "15000");
        return DriverManager.getConnection(
            "jdbc:sdp://127.0.0.1:7443", ayarlar);
    }

    private static String zorunlu(String ad) {
        String deger = System.getenv(ad);
        if (deger == null || deger.isEmpty())
            throw new IllegalStateException("Eksik ayar: " + ad);
        return deger;
    }
}
```

CA yolunun uygulamanın çalıştığı makinede erişilebilir olması gerekir. Container kullanıyorsanız host'taki `C:/certs/...` yolu container içinde kendiliğinden oluşmaz; dosyayı uygun konuma bağlayın ve yolu buna göre ayarlayın.

## İlk sorgu ve capability kontrolü

```java
import com.stardataparadise.sdk.SdpConnection;

public final class IlkSorgu {
    public static void main(String[] args) throws Exception {
        try (var connection = SdpBaglantilari.ac()) {
            var sdp = connection.unwrap(SdpConnection.class);
            System.out.println("Oturum: " + sdp.sessionId());
            System.out.println("Yetenekler: " + sdp.capabilities());

            try (var query = connection.prepareStatement(
                    "SELECT id, ad FROM urunler WHERE id = ?")) {
                query.setLong(1, 101L);
                try (var rows = query.executeQuery()) {
                    while (rows.next()) {
                        System.out.printf("%d - %s%n",
                            rows.getLong("id"), rows.getString("ad"));
                    }
                }
            }
        }
    }
}
```

`unwrap` sürücünün ek yeteneklerine ulaşır; yeni bir ağ bağlantısı oluşturmaz. Bu bağlantıdaki capability haritası üzerinden özellikleri denetleyebilirsiniz. MySQL tabanlı bridge'in `wire_sql_basic_v1` özelliği autocommit okumaları, `wire_sql_transactions_v1` ise desteklenen CRUD ve işlemleri bildirir. Orijinal engine ile bridge aynı özellik kümesine sahip olmak zorunda değildir.

## Kaynakların sahipliği

Bağlantı, statement ve result ayrı ayrı kapatılır. `try-with-resources` bunları ters sırada kapatır: önce satırlar, sonra statement, son olarak bağlantı. Açık bir sunucu sonucu varken aynı bağlantıda ikinci sorgu başlatmayın. İkinci sorgu için önce sonucu tüketin/kapatın veya ayrı bağlantı kullanın.

JDBC bağlantısı varsayılan olarak **autocommit açık** başlar. İki değişikliğin tek iş birimi olması gerekiyorsa sorgulardan önce `setAutoCommit(false)` kullanın. Paylaşılan bağlantıyı farklı HTTP isteklerine aynı anda dağıtmak transaction sahipliğini belirsizleştirir. Başlangıçta her iş birimine ayrı bağlantı vermek anlaşılır bir uygulama modelidir.

Bir bağlantı havuzu daha sonra eklenecekse kaynak kılavuzundaki `resetSession()` davranışıyla uyumunu doğrulayın; reset başarısızsa bağlantıyı yeniden kullanmayın. Bu doküman belirli bir üçüncü taraf havuz veya ORM ile tam uyumluluk iddia etmez.

## Kaynaklar

- [JDBC URL ve özellik doğrulaması](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/src/main/java/com/stardataparadise/sdk/StarDataParadiseDriver.java)
- [Oturum ve varsayılan autocommit](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/src/main/java/com/stardataparadise/sdk/JdbcSession.java)
- [Ek SdpConnection API'leri](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/src/main/java/com/stardataparadise/sdk/SdpConnection.java)

