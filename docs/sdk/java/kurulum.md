---
title: "Java SDK: JDBC ile başlama ve kurulum"
slug: "/sdk/java/kurulum"
---

# Java SDK: JDBC ile başlama ve kurulum

> **Kapsam:** Java SDK 0.3.0, Java 17 ve wire v1 JDBC. Native SQL ayrı bir API olarak [Native SQL ve AI](native-sql-ai.md) bölümünde anlatılır. Kaynak kontrolü: 23 Kasım 2026.

StarDataParadise JDBC sürücüsü Java uygulamasının SQL komutlarını sunucuya göndermesini, parametre bağlamasını, sonuçları satır satır okumasını ve birden fazla değişikliği transaction içinde tamamlamasını sağlar. Uygulama JDBC'nin `Connection`, `PreparedStatement` ve `ResultSet` arayüzlerini kullanır. StarDataParadise'a özgü capability, History ve işlem sonucu sorguları için bağlantı `SdpConnection` arayüzüne açılır.

Bu katman bir ORM değildir. Tablo şemasını sizin yerinize tasarlamaz; nesnelerinizi otomatik kaydetmez. SQL'i uygulama açıkça oluşturur, değerleri parametre olarak bağlar ve dönen satırları kendi nesnelerine dönüştürür. Bu sayede sunucuya gönderilen sorguyu ve transaction sınırını takip etmek kolaylaşır.

## 1. Gereksinimleri hazırlayın

| Gereksinim | Kullanım amacı |
| --- | --- |
| Java 17 | Sürücünün hedef çalışma zamanı |
| SDK 0.3.0 JAR ve POM dosyaları | JDBC sağlayıcısı |
| Gson 2.13.2 | Sürücünün çalışma zamanı bağımlılığı |
| Çalışan wire v1 endpoint | TLS üzerinden SQL bağlantısı |
| Kullanıcı, parola, CA PEM dosyası ve TLS adı | Kimlik doğrulama ve sunucu doğrulaması |
| Laboratuvar tabloları | Bu rehberdeki `urunler`, `musteriler` ve `siparisler` örnekleri |

Sürücü bağımlılığını eklemek veritabanını kurmaz veya tabloları oluşturmaz. Önce Server ve laboratuvar şemasını hazırlayın. Örneklerde kullanıcıya ilgili tablolar için gerekli okuma veya yazma izinlerinin verilmiş olduğu kabul edilir.

## 2. Maven veya Gradle bağımlılığı ekleyin

Maven koordinatı aşağıdaki gibidir:

```xml
<dependency>
  <groupId>io.github.paradiseincdevelopers</groupId>
  <artifactId>stardataparadise-jdbc</artifactId>
  <version>0.3.0</version>
</dependency>
```

Kaynak README'si Maven Central yayınının tamamlanmasını beklediğini belirtir. Bu nedenle bu bildirimin tek başına internetten çözülmesini beklemeyin. Yetkili dağıtımdaki Maven deposunu veya kaynak derlemenin ürettiği `out/maven` dizinini bağımlılık kaynağı olarak tanımlayın. Örneğin kendi makinenizde bu dizine karşılık gelen bir dosya URI'siyle:

```xml
<repositories>
  <repository>
    <id>sdp-local</id>
    <url>file:///C:/SDP/StarDataParadise.SDK.Java/out/maven</url>
  </repository>
</repositories>
```

Gradle Kotlin DSL kullanan bir tüketici uygulamada eşdeğer tanım:

```kotlin
repositories {
    maven { url = uri("C:/SDP/StarDataParadise.SDK.Java/out/maven") }
    mavenCentral() // Gson gibi çalışma zamanı bağımlılıkları için.
}
dependencies {
    implementation("io.github.paradiseincdevelopers:stardataparadise-jdbc:0.3.0")
}
java {
    toolchain { languageVersion.set(JavaLanguageVersion.of(17)) }
}
```

Buradaki dizin sizin indirdiğiniz veya derlediğiniz paketin gerçek konumu olmalıdır. `out/maven` klasörü rastgele JAR dosyalarını değil, Maven'in beklediği koordinat dizilimini içerir.

## 3. Kaynaktan paket üretme

Kaynak erişiminiz varsa depo derleme akışı JDK 17, Gradle 9.3.1 ve doğrulanmış bağımlılık JAR'larını kullanır. Bağımlılık dizinindeki dosya adları ve SHA-256 değerleri kaynak `BUILD.md` dosyasında listelenir.

```powershell
pwsh -NoProfile -File .\ci.ps1 `
  -JavaHome 'C:/Program Files/Java/jdk-17' `
  -DependencyDir 'C:/sdk-dependencies' `
  -PublishLocal
```

Bu, SDK deposunun kökünde çalıştırılan bir paket üretme komutudur. Tüketici uygulamanın normal başlangıç komutu değildir. Derleme akışı sözleşme testlerini ve JAR'ın ayrı bir Java sürecinde yüklenmesini kapsar; gerçek sunucunuza bağlanma ve uygulama sorgularınızı doğrulama ayrı bir aşamadır.

## 4. Proje dosyalarını ayırın

Küçük bir uygulamada bağlantı oluşturmayı `SdpBaglantilari`, SQL sorgularını `UrunDeposu`, iş kurallarını servis sınıfında tutabilirsiniz. HTTP controller'ına doğrudan SQL ve parola yerleştirmeyin. Bu rehberdeki sınıf isimleri örnek uygulamaya aittir; SDK'nın kendi sınıfları değildir.

Sürümü açıkça sabitleyin. SDK sürümü, Server sürümü ve Workbench sürümü birbirinden bağımsızdır. Sürücünün yüklenebilmesi, sunucunun her özelliği sunduğunu göstermez; bağlandıktan sonra capability kontrolü yapılır.

Java paketi kaynak README'sinde **SDK Free-Use License 1.0** ile tanımlanır. Dağıtımınıza ekleyeceğiniz JAR'ın lisans ve bildirim dosyalarını birlikte inceleyin; Server'ın lisansını SDK için varsaymayın.

## Sonraki adım

[Bağlantı ve TLS](baglanti.md) bölümündeki ilk sorguyla endpoint, sertifika, kullanıcı ve tablo erişimini birlikte doğrulayın. Bu dokümandaki örnekler kaynak API'leriyle karşılaştırılmıştır; sizin ortamınızda çalıştırılmış test çıktısı olarak sunulmaz.

## Kaynaklar

- [Java SDK README](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/README.md)
- [Derleme ve dağıtım kılavuzu](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/BUILD.md)

