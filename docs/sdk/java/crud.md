---
title: "Java SDK: parametreli CRUD ve sonuç okuma"
slug: "/sdk/java/crud"
---

# Java SDK: parametreli CRUD ve sonuç okuma

> **Kapsam:** JDBC 0.3.0, wire v1; orijinal engine laboratuvarındaki `main.public.urunler`. Önkoşul: tablo ve izinler hazırlanmış, [SdpBaglantilari](baglanti.md) yardımcı sınıfı eklenmiş olmalı.

CRUD, kayıt oluşturma, okuma, güncelleme ve silme işlemlerinin ortak adıdır. SQL cümlesini `PreparedStatement` ile hazırlayın; kullanıcıdan gelen değerleri `?` yerlerine türleriyle bağlayın. Java JDBC parametrelerinin sırası **1'den başlar**. Tablo veya sütun isimleri değer parametresi değildir: kullanıcıya göre sıralama sütunu seçilecekse uygulamanız önceden belirlediği isimler arasından seçim yapmalıdır.

Örnek laboratuvar tablosu `id BIGINT`, `ad TEXT`, `fiyat DECIMAL(12,2)` ve `stok BIGINT` sütunlarını içerir. Aşağıdaki metotlar bunu kullanır; tabloyu kendileri oluşturmaz. `9001` gibi örnek kimlikler kullanılacaksa bunların önceden boş olduğundan emin olun.

## Ekleme

```java
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.SQLException;

public final class UrunIslemleri {
    private UrunIslemleri() {}

    public static int ekle(Connection db, long id, String ad,
                           BigDecimal fiyat, long stok) throws SQLException {
        if (fiyat.signum() < 0 || stok < 0)
            throw new IllegalArgumentException("Fiyat ve stok negatif olamaz");
        try (var q = db.prepareStatement(
                "INSERT INTO urunler (id, ad, fiyat, stok) VALUES (?, ?, ?, ?)")) {
            q.setLong(1, id);
            q.setString(2, ad);
            q.setBigDecimal(3, fiyat);
            q.setLong(4, stok);
            return q.executeUpdate();
        }
    }
}
```

Kullanımı: `UrunIslemleri.ekle(db, 9001L, "Deneme ürünü", new BigDecimal("149.90"), 12L)`. `executeUpdate()` etkilenen satır sayısını döndürür. Yeni kaydın kimliğini örnekte uygulama belirler. Bu sürümde JDBC generated keys desteği varsayılmadığından `getGeneratedKeys()` akışı kullanılmaz.

## Okuma ve nesneye dönüştürme

```java
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

record Urun(long id, String ad, BigDecimal fiyat, long stok) {}

final class UrunListesi {
    static List<Urun> stoktakiler(Connection db, long ilkId) throws SQLException {
        var sonuc = new ArrayList<Urun>();
        try (var q = db.prepareStatement(
                "SELECT id, ad, fiyat, stok FROM urunler " +
                "WHERE id >= ? AND stok > 0 ORDER BY id")) {
            q.setLong(1, ilkId);
            q.setMaxRows(100);
            q.setFetchSize(32);
            q.setQueryTimeout(15); // JDBC'de saniye.
            try (var rows = q.executeQuery()) {
                while (rows.next()) {
                    sonuc.add(new Urun(rows.getLong("id"),
                        rows.getString("ad"), rows.getBigDecimal("fiyat"),
                        rows.getLong("stok")));
                }
            }
        }
        return List.copyOf(sonuc);
    }
}
```

`setMaxRows(100)` sürücünün sonuç için istediği toplam satır sınırını belirler. Orijinal engine örneğine SQL `LIMIT` eklenmez. `setFetchSize(32)` ağdan tek seferde istenen satır sayısını ayarlar; toplam sonuç sınırı değildir. Çok büyük raporları tek listeye toplamak yerine her satırı işlemeyi tercih edebilirsiniz. Böyle bir işlem sürerken aynı bağlantıyı başka bir sorguya ayırmayın.

## Güncelleme ve koşullu değiştirme

Stok düşerken önce değeri okuyup sonra koşulsuz yazmak eşzamanlı istekler arasında yarış oluşturabilir. Basit bir stok düşümü SQL koşuluyla yapılabilir:

```java
try (var q = db.prepareStatement(
        "UPDATE urunler SET stok = stok - ? WHERE id = ? AND stok >= ?")) {
    q.setLong(1, 2L);
    q.setLong(2, 9001L);
    q.setLong(3, 2L);
    int degisen = q.executeUpdate();
    if (degisen != 1)
        throw new IllegalStateException("Ürün bulunamadı veya stok yetersiz");
}
```

Bu blokta `db` açık bağlantıdır. Aynı SQL değerinin iki defa geçtiği yer için her iki `?` ayrı bağlanır. Sıfır satır etkilenmesi her zaman veritabanı hatası değildir; `WHERE` koşulunun hiçbir kayıtla eşleşmediğini gösterir. Stok değişikliğiyle sipariş ekleme birlikte tamamlanacaksa ikisini [aynı transaction](transaction.md) içinde çalıştırın.

## Silme

```java
try (var q = db.prepareStatement("DELETE FROM urunler WHERE id = ?")) {
    q.setLong(1, 9001L);
    int silinen = q.executeUpdate();
    System.out.println("Silinen kayıt: " + silinen);
}
```

Örnekteki ürün başka tablolardan referans alıyorsa foreign key kuralı silmeyi engelleyebilir. Bu sonuç doğru bir bütünlük korumasıdır; ilişkili kayıtların yaşam döngüsünü uygulamanın iş kuralı belirlemelidir. Kullanıcı ekranında bir ürünü görünmez yapmak, ilişkili sipariş geçmişini fiziksel olarak silmekle aynı işlem değildir.

Bir yazma komutunda bağlantı kesilirse aynı INSERT veya stok azaltmayı otomatik tekrarlamayın. Sürücünün belirsiz sonuç alanlarını inceleyin; kesinlik sağlanmadan ikinci kez gönderilen değişiklik iki kez uygulanabilir.

## Kaynaklar

- [Statement çalıştırma, parametre ve sonuç API'si](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/src/main/java/com/stardataparadise/sdk/JdbcStatement.java)
- [JDBC kullanım ve sonuç kısıtları](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/BUILD.md)

