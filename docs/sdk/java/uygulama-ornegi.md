---
title: "Java SDK: tek ürünlü sipariş servisi"
slug: "/sdk/java/uygulama-ornegi"
---

# Java SDK: tek ürünlü sipariş servisi

> **Kapsam:** JDBC 0.3.0 wire v1; `main.public` laboratuvarı. Bu sınıf dokümantasyon için yazılmış uygulama örneğidir. Sunucuda çalıştırılmış kabul testi değildir.

Bu örnek, önceki bölümlerdeki sorgu, parametre, kesin decimal ve transaction konularını bir iş akışında birleştirir. İşlem bir müşteriye bir ürün için sipariş açar; fiyatı veritabanından okur, yeterli stok varsa düşürür, sipariş başlığını ve kalemini aynı transaction içinde ekler.

Örnek, laboratuvar tablolarının `id` anahtarlarını uygulamanın verdiği modeli kullanır. Çağıran servis sipariş ID'sini üretir; örnek çalıştırma komutunda 2001 seçilir. Mevcut bir kimliği yeni bir sipariş için tekrar kullanmayın. Gerçek uygulamada iş isteği kimliği, kullanıcı yetkisi ve tekrarlanan HTTP isteğinin davranışı servis tasarımının parçasıdır.

Tam kaynak dosyaları ve çalıştırma adımları [ayrı örnek proje klasöründe](ornekler/siparis-servisi/README.md) bulunur.

## Uygulama kodu

[Bağlantı bölümündeki](baglanti.md) `SdpBaglantilari` sınıfıyla birlikte derlenebilecek servis:

```java
import com.stardataparadise.sdk.SdpException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.SQLException;

public final class SiparisServisi {
    public static BigDecimal olustur(long siparisId, long musteriId,
                                     long urunId, long adet) throws SQLException {
        if (adet <= 0) throw new IllegalArgumentException("Adet pozitif olmalı");
        try (var db = SdpBaglantilari.ac()) {
            db.setAutoCommit(false);
            try {
                BigDecimal fiyat;
                try (var q = db.prepareStatement(
                        "SELECT fiyat FROM urunler WHERE id = ?")) {
                    q.setLong(1, urunId);
                    try (var r = q.executeQuery()) {
                        if (!r.next()) throw new IllegalStateException("Ürün bulunamadı");
                        fiyat = r.getBigDecimal("fiyat");
                    }
                }

                try (var q = db.prepareStatement(
                        "UPDATE urunler SET stok = stok - ? " +
                        "WHERE id = ? AND stok >= ?")) {
                    q.setLong(1, adet);
                    q.setLong(2, urunId);
                    q.setLong(3, adet);
                    tekSatir(q.executeUpdate());
                }

                BigDecimal toplam = fiyat.multiply(BigDecimal.valueOf(adet));
                try (var q = db.prepareStatement(
                        "INSERT INTO siparisler (id, musteri_id, durum, toplam) " +
                        "VALUES (?, ?, ?, ?)")) {
                    q.setLong(1, siparisId);
                    q.setLong(2, musteriId);
                    q.setString(3, "hazirlaniyor");
                    q.setBigDecimal(4, toplam);
                    tekSatir(q.executeUpdate());
                }

                try (var q = db.prepareStatement(
                        "INSERT INTO siparis_kalemleri " +
                        "(siparis_id, urun_id, adet, birim_fiyat) VALUES (?, ?, ?, ?)")) {
                    q.setLong(1, siparisId);
                    q.setLong(2, urunId);
                    q.setLong(3, adet);
                    q.setBigDecimal(4, fiyat);
                    tekSatir(q.executeUpdate());
                }

                db.commit();
                return toplam;
            } catch (SQLException | RuntimeException hata) {
                boolean belirsiz = hata instanceof SdpException s
                    && s.isOutcomeUnknown();
                if (!belirsiz && !db.isClosed()) {
                    try { db.rollback(); }
                    catch (SQLException ek) { hata.addSuppressed(ek); }
                }
                throw hata;
            }
        }
    }

    private static void tekSatir(int sayi) {
        if (sayi != 1)
            throw new IllegalStateException("Beklenen kayıt değişmedi; stok yetersiz olabilir");
    }

    public static void main(String[] args) {
        int cikis = calistir(args);
        System.err.flush();
        if (cikis != 0) System.exit(cikis);
    }

    private static int calistir(String[] args) {
        if (args.length != 4) {
            System.err.println(
                "Kullanım: SiparisServisi <siparis-id> <musteri-id> <urun-id> <adet>");
            return 2;
        }
        long siparisId, musteriId, urunId, adet;
        try {
            siparisId = Long.parseLong(args[0]);
            musteriId = Long.parseLong(args[1]);
            urunId = Long.parseLong(args[2]);
            adet = Long.parseLong(args[3]);
        } catch (NumberFormatException hata) {
            System.err.println("Argümanların tamamı signed 64 bit tamsayı olmalı.");
            return 2;
        }
        try {
            System.out.println(olustur(siparisId, musteriId, urunId, adet));
            return 0;
        } catch (SdpException hata) {
            System.err.printf(
                "status=%s siparis_id=%d request_token=%s code=%d sqlstate=%s correlation_id=%s%n",
                hata.isOutcomeUnknown() ? "unknown_outcome" : "failed", siparisId,
                alan(hata.requestToken()), hata.getErrorCode(),
                alan(hata.getSQLState()), alan(hata.correlationId()));
            if (hata.isOutcomeUnknown()) {
                System.err.println("SQL yeniden gönderilmedi. Token ile yeni oturumdan sonucu sorgulayın.");
                return 7;
            }
            System.err.println("reason=" + alan(hata.getMessage()));
            return 1;
        } catch (SQLException hata) {
            System.err.printf("status=failed siparis_id=%d code=%d sqlstate=%s%n",
                siparisId, hata.getErrorCode(), alan(hata.getSQLState()));
            return 1;
        } catch (IllegalArgumentException hata) {
            System.err.println("status=invalid_input reason=" + alan(hata.getMessage()));
            return 2;
        } catch (RuntimeException hata) {
            System.err.printf("status=failed siparis_id=%d reason=%s%n",
                siparisId, alan(hata.getMessage()));
            return 1;
        }
    }

    private static String alan(String deger) {
        return deger == null ? "<yok>" : deger.replace('\r', ' ').replace('\n', ' ');
    }
}
```

Giriş noktası sipariş ID'si, müşteri ID'si, ürün ID'si ve adedi komut satırından alır. Belirsiz sonuçta receipt token'ı, sipariş ID'sini, hata kodunu, SQLSTATE ve correlation ID'yi `stderr` üzerine yazar ve `7` koduyla çıkar. Diğer hatalar `1`, geçersiz giriş `2`, başarı `0` kodudur. SQL yeniden çalıştırılmaz. Receipt bilgisini kaybetmemek için [örnek proje README'sindeki stderr kaydını](ornekler/siparis-servisi/README.md) ilk çalıştırmada kullanın.

## Beklenen değişiklik

Başlangıç laboratuvar verisi değiştirilmemişse ürün 101'in birim fiyatı 750.00 ve stoku 20'dir. Tek başarılı çağrıdan sonra toplam 1500.00 döner, stok 18 olur, 2001 numaralı sipariş ve ona bağlı bir kalem oluşur. `musteriId=1` mevcut müşteriyi kullanır. Bu değerler örneğin matematiksel beklentisidir; uygulamanızda sorgulayarak doğrulayın.

Sonucu kontrol etmek için ayrı sorguları kullanın: `SELECT stok FROM urunler WHERE id = 101`, `SELECT id, musteri_id, durum, toplam FROM siparisler WHERE id = 2001` ve `SELECT siparis_id, urun_id, adet, birim_fiyat FROM siparis_kalemleri WHERE siparis_id = 2001`. SDK'da bu değerleri yine parametre olarak bağlayın.

## İş akışının neden böyle kurulduğu

Fiyat ve stok aynı transaction içinde okunur/değiştirilir. Sorgu sonucu güncellemeden önce kapanır; bu, bağlantının tek açık sonuç kuralını karşılar. Koşullu UPDATE stok yetersizliğini etkilenen satır sayısından gösterir. Sipariş kaleminde birim fiyat ayrıca tutulur; ürünün fiyatı sonradan değiştiğinde eski siparişin fiyatı korunur.

Gerçek sistemde müşterinin bu hesabı kullanma yetkisi yalnızca foreign key ile belirlenmez. Kimlik doğrulaması ve sipariş sahibinin denetimi servis katmanında, tablo bütünlüğü ise veritabanında uygulanır. Örnek ödeme tahsil etmez, e-posta göndermez veya stok rezervasyon zaman aşımını yönetmez; bu işlevler eklendiğinde transaction ve dış yan etki sınırlarını ayrıca tasarlayın.

## Hata senaryoları

Yetersiz stok, olmayan ürün veya geçersiz müşteriyle işlem başarısız olmalıdır. Sipariş kalemi eklenemezse stok ve sipariş başlığı birlikte geri alınmalıdır. Aynı ID'nin ikinci kez kullanılması anahtar ihlali oluşturabilir; bunu uygulama yeni sipariş olarak otomatik tekrar denememelidir. Commit yanıtı kaybolursa [belirsiz sonuç akışını](transaction.md) uygulayın.

Örnekte iş sınıfı SQL hatasını yukarı taşır. Bir web uygulaması bunu kullanıcıya ham SQL veya bağlantı ayrıntıları döndürmeden anlamlı durumlara eşler. Loglarda sipariş ID'si, correlation ID ve varsa request token tutulabilir; parola ve müşteri prompt'u gibi veriler kayda eklenmez.

## Kaynaklar

- [JDBC parametre ve transaction API'leri](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/BUILD.md)
- [Oturum transaction davranışı](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/src/main/java/com/stardataparadise/sdk/JdbcSession.java)

