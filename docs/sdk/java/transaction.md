---
title: "Java SDK: transaction, savepoint ve belirsiz sonuçlar"
slug: "/sdk/java/transaction"
---

# Java SDK: transaction, savepoint ve belirsiz sonuçlar

> **Kapsam:** JDBC 0.3.0 wire v1. JDBC varsayılanı autocommit açıktır. Sunucu işlemleri ve receipt sorguları endpoint capability'lerine bağlıdır.

Bir sipariş oluştururken stok azaltma, sipariş kaydı ve sipariş kalemi birlikte kalıcı olmalıdır. İlk adım başarılı, sonraki adım başarısız olduğunda yalnızca ilk değişikliğin kaydedilmesi veri tutarlılığını bozar. Transaction bu değişikliklerin tamamını bir iş birimi olarak ele alır. Uygulama işlem bitene kadar tek bağlantıyı kullanır, başarıda commit, kesin başarısızlıkta rollback yapar.

## İşlem sınırını uygulama belirlesin

JDBC'de `setAutoCommit(false)` manuel transaction yönetimini etkinleştirir. StarDataParadise sürücüsü gereken transaction'ı SQL çalıştırma akışında başlatır. Sonuç okuyucuları kapatıldıktan sonra `commit()` veya `rollback()` çağırın. SQL metnine `BEGIN; ... COMMIT;` ekleyerek birden fazla ifadeyi tek komut yapmayın.

Örnek iki ürünün stoklarını aynı transaction içinde azaltır. Ürünlerden biri yoksa veya miktarı yetersizse hiçbiri kalıcı değişmez. Laboratuvarın başlangıç verisinde ürün 101'in stoku 20, ürün 102'nin stoku 50'dir; başarılı tek çalıştırmadan sonra 19 ve 48 olur.

```java
import com.stardataparadise.sdk.SdpException;
import java.sql.Connection;
import java.sql.SQLException;

public final class StokAyirma {
    public static void main(String[] args) throws Exception {
        try (var db = SdpBaglantilari.ac()) {
            db.setAutoCommit(false);
            try {
                azalt(db, 101L, 1L);
                azalt(db, 102L, 2L);
                db.commit();
                System.out.println("İki stok değişikliği kaydedildi.");
            } catch (SQLException | RuntimeException hata) {
                boolean belirsiz = hata instanceof SdpException s
                    && s.isOutcomeUnknown();
                if (!belirsiz && !db.isClosed()) {
                    try { db.rollback(); }
                    catch (SQLException geriAlma) { hata.addSuppressed(geriAlma); }
                }
                throw hata;
            }
        }
    }

    private static void azalt(Connection db, long id, long adet)
            throws SQLException {
        if (adet <= 0) throw new IllegalArgumentException("Adet pozitif olmalı");
        try (var q = db.prepareStatement(
                "UPDATE urunler SET stok = stok - ? WHERE id = ? AND stok >= ?")) {
            q.setLong(1, adet);
            q.setLong(2, id);
            q.setLong(3, adet);
            if (q.executeUpdate() != 1)
                throw new IllegalStateException("Ürün yok veya stok yetersiz: " + id);
        }
    }
}
```

Kodda bekleme, e-posta gönderme veya dış servis çağrısı transaction içine yerleştirilmez. Bu işlemler veritabanı kilitlerini gereksiz süre açık tutabilir. Uygulamanın servis sınırında gerekli veriyi önceden doğrulayın, veritabanı işini tamamlayın ve sonuç kesinleştikten sonra sonraki adımlara geçin.

## Savepoint

Savepoint transaction içinde bir ara noktadır. Tamamlanmış transaction'ın geçmişine dönüş sağlamaz. Aynı bağlantıda, açık sonuç bulunmadığında oluşturulur:

```java
var araNokta = db.setSavepoint("ek_kalem_oncesi");
// İsteğe bağlı işlemleri burada çalıştırın.
db.rollback(araNokta);   // Yalnızca bu noktadan sonraki değişiklikleri geri alır.
db.releaseSavepoint(araNokta);
```

Bu örnek `db.setAutoCommit(false)` yapılmış açık bir bağlantı içinde kullanılır. Geri alınan ek kalem işin zorunlu parçasıysa transaction'ın kalanını yine de commit etmek doğru değildir; uygulamanın kısmi başarı politikası açık olmalıdır. Sürücünün wire transaction izolasyonu serializable olarak sunulur; farklı izolasyon seviyesini genel JDBC API'si var diye destekleniyor kabul etmeyin.

## Commit yanıtı kaybolursa

Ağ kesintisi sunucu değişikliği kaydettikten, istemci onayı almadan önce oluşabilir. Böyle bir durumda hata almak, işlemin geri alındığını kanıtlamaz. `SdpException.isOutcomeUnknown()` bu ayrımı görünür kılar. Wire receipt varsa `requestToken()` ile aynı kullanıcı hesabından yeni bağlantı açarak sorgulayın:

```java
import com.stardataparadise.sdk.SdpConnection;

// token, yakalanan SdpException.requestToken() değeridir.
try (var kontrol = SdpBaglantilari.ac()) {
    var sdp = kontrol.unwrap(SdpConnection.class);
    var sonuc = sdp.transactionOutcome(token);
    if (sonuc.status() == SdpConnection.OutcomeStatus.COMMITTED) {
        System.out.println("Commit doğrulandı; LSN=" + sonuc.lsn());
    } else {
        throw new IllegalStateException("İşlem sonucu hâlâ belirsiz");
    }
}
```

Token yoksa bu receipt yolunu kullanamazsınız. `UNKNOWN` sonucu "işlem yapılmadı" demek değildir. Özellikle stok düşümü veya ödeme kaydı gibi değişiklikleri bunun üzerine otomatik tekrar göndermeyin. Uygulama, kendi sipariş/işlem kimliğini saklayarak durum uzlaştırması yapmalıdır. SDK otomatik yazma tekrarı yapmaz; bunun uygulama veya HTTP yeniden deneme katmanında yanlışlıkla eklenmemesi de gerekir.

Native AI'nin `requestKey` ve `runId` alanları bu JDBC receipt protokolüyle aynı değildir. Native hataların yorumunu [native bölümünde](native-sql-ai.md) kullanın.

## Kaynaklar

- [JDBC transaction ve savepoint uygulaması](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/src/main/java/com/stardataparadise/sdk/JdbcSession.java)
- [Outcome API ve durumları](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/src/main/java/com/stardataparadise/sdk/SdpConnection.java)
- [SdpException alanları](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/src/main/java/com/stardataparadise/sdk/SdpException.java)

