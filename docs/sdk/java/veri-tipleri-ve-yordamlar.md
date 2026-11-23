---
title: "Java SDK: veri tipleri, NULL ve yordamlar"
slug: "/sdk/java/veri-tipleri-ve-yordamlar"
---

# Java SDK: veri tipleri, NULL ve yordamlar

> **Kapsam:** JDBC 0.3.0 wire değerleri. Native JSON, unsigned BIGINT ve native temporal temsilleri [ayrı bölümde](native-sql-ai.md) ele alınır.

Uygulamadaki bir değerin Java tipi, SQL parametresinin tipi ve tablodaki sütunun tipi birbiriyle uyumlu olmalıdır. Özellikle para, büyük tamsayı ve zaman değerlerini önce metne veya `double` tipine çevirip sonra tekrar dönüştürmek gereksiz hassasiyet kaybına neden olabilir. SDK'nın tipli bağlama yöntemleri bu dönüşüm zincirini önler.

## Temel eşleme

| SQL / wire tipi | Java kullanımı | Dikkat edilecek nokta |
| --- | --- | --- |
| BIGINT | `long`, `Long`, `setLong`, `getLong` | Signed 64 bit sınırları |
| DECIMAL | `BigDecimal`, `setBigDecimal`, `getBigDecimal` | Para için metinden oluşturun; örneğin `new BigDecimal("19.90")` |
| BOOLEAN | `boolean`, `Boolean` | NULL ile false farklıdır |
| TEXT | `String`, `setString`, `getString` | Boş metin ile NULL farklıdır |
| BLOB | `byte[]`, `setBytes`, `getBytes` | Metin kodlamasına dönüştürmeden aktarın |
| DATE | `LocalDate` veya `java.sql.Date` | Takvim günü; saat dilimi eklemeyin |
| TIME | `LocalTime` veya `java.sql.Time` | Wire tarafında gün içi saat |
| TIMESTAMP WITH TIME ZONE | `OffsetDateTime`, `SdpValues.Timestamp` | Saniye, nanosaniye ve offset korunur |
| RECORD | `SdpValues.RecordValue` | PL/SQL kaydının isimli alanları |
| COLLECTION | `SdpValues.CollectionValue` | PL/SQL değer listesi |

Orijinal wire decimal sözleşmesi 38 basamağa kadardır. Native katmanın 65 basamaklı decimal davranışını JDBC wire parametresine taşımayın. Uygulama sütunu `DECIMAL(12,2)` ise toplam 12 basamağın ikisi virgülden sonradır; daha geniş Java nesnesi kullanmak sütunun kapasitesini artırmaz.

## NULL bağlama ve okuma

NULL gönderirken türü açıkça belirtin:

```java
try (var q = db.prepareStatement(
        "UPDATE musteriler SET eposta = ? WHERE id = ?")) {
    q.setNull(1, java.sql.Types.VARCHAR);
    q.setLong(2, 1L);
    q.executeUpdate();
}
```

Metin sütununda `getString` NULL için `null` döndürür. Sayısal getter'larda JDBC'nin primitive dönüşümüyle gerçek sıfırı ayırmak için getter'dan hemen sonra `wasNull()` çağrısını kullanın:

```java
long deger = rows.getLong("istege_bagli_sayi");
Long istegeBagli = rows.wasNull() ? null : deger;
```

Bu son parça nullable bir BIGINT sütununun okunmasını gösterir; laboratuvar şemasına böyle bir sütun eklemez. `wasNull()` en son okunan sütunla ilgilidir. Araya başka bir getter koyarsanız farklı alanı kontrol edersiniz.

## Kesin decimal ile çalışma

```java
var birimFiyat = new java.math.BigDecimal("149.90");
var toplam = birimFiyat.multiply(java.math.BigDecimal.valueOf(3));
toplam = toplam.setScale(2, java.math.RoundingMode.UNNECESSARY);
```

`UNNECESSARY` burada iki basamağa kayıpsız sığmayan değerde hata verir. İşiniz yuvarlama gerektiriyorsa kullanılacak kuralı ürünün fiyatlandırma politikasında açıkça belirleyin. Küsuratı sessizce kesen dönüşümü genel çözüm olarak kullanmayın. JSON yanıtı üretirken büyük ID ve kesin decimal alanlarının tüketici uygulamada da hassasiyetini koruduğunu kontrol edin.

## PL/SQL yordamı çağırma

JDBC `CallableStatement` kullanabilir. Aşağıdaki kod sunucuda önceden tanımlanmış `public.stok_ozeti(IN p_id BIGINT, OUT p_stok BIGINT)` imzasına sahip bir yordam olduğunu varsayan çağırma örneğidir. Yordamı SDK oluşturmaz; bu isim laboratuvar kurulumunda hazır gelmez.

```java
try (var call = db.prepareCall("{call public.stok_ozeti(?, ?)}")) {
    call.setLong(1, 101L);
    call.registerOutParameter(2, java.sql.Types.BIGINT);
    call.execute();
    long stok = call.getLong(2);
    Long sonuc = call.wasNull() ? null : stok;
    System.out.println(sonuc);
}
```

Saf OUT parametresine bağımsız bir giriş değeri atamayın; yalnızca `registerOutParameter` kullanın. IN OUT parametresinde hem başlangıç değerini bağlayın hem OUT kaydını yapın. OUT ve IN OUT kayıtlarını yordam bildirim sırasına uygun kurun.

Yordam birden fazla sonuç kümesi açıyorsa `getMoreResults()` sonraki kümeye geçer. Bağlantının tek açık sunucu sonucu kuralı burada da geçerlidir. Sonuç kapanmasının transaction tamamlamasına etkisi olabileceğinden, veri değiştiren yordamı uygulamanın açıkça yönettiği transaction içinde çağırmak iş biriminin sınırını anlaşılır kılar. Yordam çağrısını erken terk etmek otomatik olarak işin geri alındığı sonucunu vermez; açık transaction için rollback veya oturum sonlandırma akışını belirleyin.

## Tip hatasını nerede aramalı?

Önce parametre sırası ve bağlı değeri, sonra SQL sütununun nullability/precision bilgisini, ardından kullanılan endpoint'i kontrol edin. JDBC wire SQL ile native SQL sonuçlarının aynı Java sınıflarını döndürmesi beklenmez. Satır dönüştürme kodunu endpoint değiştirdiğinizde yeniden inceleyin.

## Kaynaklar

- [Wire tip kodlayıcısı](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/src/main/java/com/stardataparadise/sdk/ValueCodec.java)
- [Kesin değer kapsayıcıları](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/src/main/java/com/stardataparadise/sdk/SdpValues.java)
- [JDBC yordam sözleşmesi](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/BUILD.md)
