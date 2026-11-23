---
title: "Java SDK: native SQL ve AI oturumları"
slug: "/sdk/java/native-sql-ai"
---

# Java SDK: native SQL ve AI oturumları

> **Kapsam:** SDK 0.3.0 içindeki `SdpNativeConnection`; `native_sql_v1` capability'si sunan Server endpoint'i. Bu bölüm JDBC wire CRUD oturumundan ayrıdır.

Native bağlantı SQL metnini ve positional parametreleri native sunucu derleyicisine iletir. Sunucu tarafındaki MySQL tabanlı SQL, Knowledge ve AI özelliklerine erişmek için kullanılır. Aynı ağ listener'ı kullanılabilse bile JDBC bağlantısı ile native bağlantı bağımsız oturumlardır. Birinin transaction'ını diğerinde commit edemezsiniz.

## Oturum açma ve ilk sonuç

```java
import com.stardataparadise.sdk.SdpNativeConnection;
import java.nio.file.Path;

public final class NativeIlkSorgu {
    public static void main(String[] args) throws Exception {
        try (var db = SdpNativeConnection.open(
                "127.0.0.1", 7443, "localhost",
                Path.of(System.getenv("SDP_CA")),
                System.getenv("SDP_USER"), System.getenv("SDP_PASSWORD"),
                75000, true)) {
            var sonuc = db.execute(
                "SELECT CAST(? AS UNSIGNED), CAST(? AS JSON)",
                new java.math.BigInteger("18446744073709551615"),
                new SdpNativeConnection.Json("{\"id\":9007199254740993}"));
            var satir = sonuc.sets().get(0).rows().get(0);
            System.out.println(satir.get(0));
            System.out.println(((SdpNativeConnection.Json) satir.get(1)).text());
        }
    }
}
```

`open` çağrısının son argümanı autocommit tercihidir; burada `true` verilmiştir. Timeout milisaniye cinsindedir ve native API 1.000–300.000 ms aralığını kabul eder. Bağlantı açılırken sunucunun `native_sql_v1` ilanı doğrulanır. Bu özelliğin bulunması AI modelinin tanımlı, worker'ın hazır ve kullanıcının AI izinlerine sahip olduğunu tek başına göstermez.

## Sonuç yapısı ve tipler

Native sonuç bir JDBC `ResultSet` değildir. `Result.sets()` tüm sonuç kümelerini, her kümenin `columns()` ve `rows()` alanları kolonları ve satırları taşır. `affectedRows()` ve `lastInsertId()` metadata'sı ilgili kümede bulunur. `inTransaction()` ve `autocommit()` son başarılı yanıtın durumudur.

| Native değer | Java karşılığı |
| --- | --- |
| Signed tamsayı | `Long` |
| Unsigned 64 bit tamsayı | `BigInteger` |
| DECIMAL | `BigDecimal` |
| Binary | `byte[]` |
| SQL NULL | `null` |
| JSON | `SdpNativeConnection.Json` |
| Tarih/saat | `SdpNativeConnection.Temporal` |

JSON'da büyük sayıları korumak için `Json.text()` kullanılabilir. Native TIME, negatif ve 24 saati aşan süreler taşıyabilir; bunu Java `LocalTime` olarak yorumlamak anlam kaybettirebilir. `Temporal.sqlType()` ve `text()` değerlerini birlikte değerlendirin.

Native `execute(sql, parameters, maxRows)` biçiminde sonuç sınırını açıkça seçebilirsiniz. Parametresiz veya varargs kısa biçim varsayılan 1.000 satır sınırını kullanır; izin verilen `maxRows` aralığı 1–10.000'dir. Her çağrı tek SQL ifadesidir. Yordam gövdesi bütün bir ifade olarak gönderilir; istemciye özgü `DELIMITER` komutu SDK'ya gönderilmez.

## AI konuşmasını çalıştırma

Aşağıdaki akış, sunucuda önceden tanımlanmış ve erişim izni verilmiş `sdp_lab.assistant` konuşmasını kullanır. Konuşma, model tanımı ve worker kurulumu ayrıca hazırlanmalıdır. API anahtarı SQL parametresi olarak gönderilmez.

```java
try (var db = SdpNativeConnection.open(
        "127.0.0.1", 7443, "localhost",
        java.nio.file.Path.of(System.getenv("SDP_CA")),
        System.getenv("SDP_USER"), System.getenv("SDP_PASSWORD"),
        75000, true)) {
    db.execute("START AI CONVERSATION sdp_lab.assistant");
    db.execute("APPEND PROMPT ?", "Onaylanmış sipariş bağlamını özetle.");
    db.execute("APPEND RESPONSE INTO @answer AS JSON RETURNING METADATA INTO @meta");
    db.commit(false, null, 20000);
    var satir = db.execute("SELECT @answer, @meta")
        .sets().get(0).rows().get(0);
    System.out.println(((SdpNativeConnection.Json) satir.get(0)).text());
}
```

AI turn için `commit(false, null, 20000)` en fazla belirlenen bekleme süresiyle senkron beklemeyi ister. Asenkron iş akışında `commit(true, requestKey, null)` run belgesi döndürür. Yanıttaki run kimliği uygulamada saklanır; `fetchResponse(runId)` veya `cancelRun(runId)` ile aynı run izlenir. `requestKey` seçiliyorsa biçimi 32 küçük harfli hex karakterdir ve native AI deduplication kapsamına aittir.

## Hata sonrasında doğru ayrım

`SdpException` üzerindeki `nativeErrno()`, `phase()`, `commitState()`, `runState()` ve `runId()` alanlarını birlikte inceleyin. `commitState=committed` ile gelen bekleme hatası, kullanıcı SQL'inin geri alındığı anlamına gelmez. Run devam ediyor olabilir; aynı turn'ü yeni bir komut gibi başlatmak yerine mevcut run durumunu izleyin.

Native transport belirsizliği genel JDBC CRUD receipt token'ı üretmez. `transactionOutcome()` çağrısını native oturum için evrensel çözüm gibi kullanmayın. SDK native statement'ı otomatik yeniden çalıştırmaz. İşlem ve AI aracı sonuçları ayrıca değişebildiğinden hata detayını yalnızca mesaj metnine indirgemeyin.

Bu sürümde yeni SQL `HIST`/SQLgit ve SQL `JOB` komutları ertelenmiştir. Bunları Java'dan metin olarak gönderebilmek sunucuda çalışacakları anlamına gelmez. Mevcut wire History/job API'leri ayrı capability'lerle korunur.

## Kaynaklar

- [Native Java API](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/src/main/java/com/stardataparadise/sdk/SdpNativeConnection.java)
- [Native kullanım ve hata sözleşmesi](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/BUILD.md)
- [Server native SQL sözleşmesi](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/contracts/sql/native-sql-v1.md)

