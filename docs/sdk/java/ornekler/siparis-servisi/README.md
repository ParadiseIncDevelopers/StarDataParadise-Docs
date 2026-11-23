---
title: "Çalıştırılabilir proje: Java sipariş servisi"
slug: "/sdk/java/ornekler/siparis-servisi/"
---

# Çalıştırılabilir proje: Java sipariş servisi

Bu klasör [Java sipariş servisi bölümündeki](../../uygulama-ornegi.md) kodu ayrı dosyalara çıkarır. Uygulama fiyatı okur, stoku düşürür, sipariş ve kalem ekler, hepsini tek JDBC transaction'ında commit eder. Kod eksik metot içeren pseudocode değildir; çalışması için aşağıdaki gerçek Server, şema ve paket önkoşulları gerekir.

## Önkoşullar

- JDK 17; `java` ve `javac` aynı JDK'dan çalışmalı.
- Gradle yolunu kullanacaksanız kurulu Gradle 9.3.1. Bu klasöre Gradle wrapper ikilisi eklenmedi.
- SDK'nın `-PublishLocal` derlemesiyle üretilmiş, JDBC 0.3.0 koordinatını içeren gerçek `out/maven` deposu. Java SDK'nın kendi [BUILD.md](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/BUILD.md) dosyası bu üretimi açıklar.
- Wire v1 orijinal engine laboratuvarı: `main.public` içindeki `musteriler`, `urunler`, `siparisler`, `siparis_kalemleri` ve rehberdeki seed verileri.
- İlgili SELECT/INSERT/UPDATE izinleri verilmiş kullanıcı, çalışan TLS endpoint ve CA PEM dosyası.

`SdpBaglantilari.java` örnekte `127.0.0.1:7443` ve `TLS Name=localhost` kullanır. Kurulumunuz farklıysa bu dosyadaki endpoint ve sertifika adını güncelleyin. Bu örnek `sdp_lab` native şemasına veya Classic portuna doğrudan bağlanmaz.

## Dosyalar

- `src/main/java/SdpBaglantilari.java`: ortam değişkenlerinden credential/CA alır, JDBC bağlantısını açar.
- `src/main/java/SiparisServisi.java`: tam sipariş transaction'ı ve komut satırı giriş noktası.
- `build.gradle`: Java 17 uygulaması ve sabit JDBC 0.3.0 bağımlılığı.
- `settings.gradle`: proje adı.

## Gradle ile çalıştırma

PowerShell'de bu klasöre geçip gerçek yerel yolları belirtin:

```powershell
$env:SDP_MAVEN_REPO = 'C:/SDP/StarDataParadise.SDK.Java/out/maven'
$env:SDP_CA = 'C:/SDP/certs/ca.pem'
$kimlik = Get-Credential -UserName 'lab_user'
$env:SDP_USER = $kimlik.UserName
$env:SDP_PASSWORD = $kimlik.GetNetworkCredential().Password

gradle run --args="2001 1 101 2"
```

Argüman sırası `siparis-id musteri-id urun-id adet` şeklindedir. Gradle, StarDataParadise paketini yalnız belirtilen yerel Maven deposundan çözümler. Gson 2.13.2 gibi transitif bağımlılıklar Maven Central'dan alınabilir; internet erişimi yoksa önceden hazırlanmış bağımlılık cache'i veya aşağıdaki JAR yolu kullanılır.

## Gradle kullanmadan yerel JAR'larla çalıştırma

JDBC 0.3.0 JAR ve doğrulanmış Gson 2.13.2 JAR dosyaları zaten varsa:

```powershell
$env:SDP_JDBC_JAR = 'C:/SDP/packages/stardataparadise-jdbc-0.3.0.jar'
$env:SDP_GSON_JAR = 'C:/SDP/packages/gson-2.13.2.jar'
New-Item -ItemType Directory -Force out | Out-Null

javac --release 17 -cp "$env:SDP_JDBC_JAR;$env:SDP_GSON_JAR" -d out `
  src/main/java/SdpBaglantilari.java src/main/java/SiparisServisi.java

java -cp "out;$env:SDP_JDBC_JAR;$env:SDP_GSON_JAR" SiparisServisi 2001 1 101 2
```

Bu ikinci yol Gradle bağımlılığı indirmez. Ortam değişkenlerindeki JAR yolları gerçek dosyaları göstermelidir. Unix ortamında classpath ayırıcısı `;` yerine `:` kullanılır; proje kabul kapsamının Windows x64 kaynak profiliyle ayrı değerlendirilmesi gerekir.

## Beklenen sonuç ve tekrar çalıştırma

Değiştirilmemiş laboratuvarda ürün 101'in fiyatı 750.00 ve stoku 20'dir. Tek başarılı çağrı toplam 1500.00 yazdırır, stoku 18'e düşürür, sipariş 2001'i ve kalemini ekler. Veritabanında kalıcı değişiklik yapar. Aynı sipariş ID'siyle yeniden çalıştırmak yeni bir sipariş oluşturma yöntemi değildir.

İşlem başarısızsa konsol çıktısındaki hata türünü inceleyin. `SdpException.isOutcomeUnknown()` durumunda [transaction bölümündeki](../../transaction.md) receipt akışını kullanın; aynı komutu körlemesine tekrar çalıştırmayın. Örnek kullanıcıya sorulmadan veritabanı sıfırlamaz, tabloları silmez ve otomatik retry yapmaz.

## Süreç çıkış kodları ve receipt kaydı

| Kod | Anlamı |
| --- | --- |
| `0` | Sipariş transaction'ı başarıyla tamamlandı. |
| `1` | İş kuralı, yapılandırma veya kesin SQL/bağlantı hatası. |
| `2` | Eksik/geçersiz komut satırı argümanı veya geçersiz adet. |
| `7` | Yazma/commit sonucu belirsiz; SQL otomatik tekrar gönderilmedi. |

Belirsiz sonuçta giriş noktası `stderr` üzerine `siparis_id`, `request_token`, hata kodu, SQLSTATE ve varsa correlation ID yazar. Varsayılan exception stack trace'inin token taşımasına güvenilmez. `request_token=<yok>` görünürse receipt sorgulanabilecek token yoktur; uygulama sipariş kimliği ve sunucu kayıtlarıyla durumu incelemelidir. Bu durum da otomatik yeniden gönderme izni değildir.

Token çıktısını kaybetmemek için yönlendirmeyi **ilk çalıştırmaya** ekleyin. Aşağıdaki komut önceki bir belirsiz siparişi yeniden denemek için verilmemiştir:

```powershell
java -cp "out;$env:SDP_JDBC_JAR;$env:SDP_GSON_JAR" SiparisServisi 2001 1 101 2 `
  2> .\siparis-2001-receipt.log
$sonuc = $LASTEXITCODE
if ($sonuc -eq 7) { Get-Content .\siparis-2001-receipt.log }
```

Bu örnek doğrudan Java sürecinin çıkış kodunu alır. `gradle run` alt programın başarısız çıkışını kendi görev hatası olarak sunabilir; otomasyonda Java'nın `7` kodunu ayırt etmek için doğrudan `java` akışını kullanın. Logdaki token'ı aynı kullanıcıyla açılan **yeni bağlantıda** `transactionOutcome(token)` sorgusuna verin. `COMMITTED` doğrulanırsa siparişi yeniden göndermeyin; `UNKNOWN` hâlâ çözülememiş durumdur. Log dosyasını sonuç kesinleşene kadar saklayın.

## Doğrulama durumu

Kaynak dosyalar dokümandaki tam örnekten çıkarıldı; kullanılan yöntemler SDK kaynaklarıyla karşılaştırıldı. Bu dokümantasyon ortamında JDK derleyicisi, SDK JAR'ı ve çalışan Server bulunmadığından proje burada derlenmedi veya canlı veritabanına karşı çalıştırılmadı. Paket ve bağlantı önkoşullarını sağladıktan sonra kendi test ortamınızda çalıştırın.

