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
