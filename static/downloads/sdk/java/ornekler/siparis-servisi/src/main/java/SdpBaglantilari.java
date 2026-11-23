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
