---
title: "Doğru bağlantı profilini seçmek"
slug: "/baslangic/baglanti-profilleri"
---

# Doğru bağlantı profilini seçmek

**Kapsam:** Sunucu yolu, protokol ve capability seçimi.

Bağlantı profilini oluştururken önce hedef motoru, ardından o motora ulaşan protokolü seçin. “Port açık” kontrolü doğru SQL yolunda olduğunuzu göstermez. Aynı kullanıcı adı farklı sunucularda farklı bir hesaba karşılık gelebilir. Profil adlarında motoru ve ortamı görünür kılın: `lab-wire`, `lab-native`, `prod-native` gibi.

| Yol | Sunucu/ara katman | Örnek uç nokta | SQL ve API kapsamı |
| --- | --- | --- | --- |
| Özgün wire v1 | `StarDataParadiseServer.exe` | `127.0.0.1:7443`, TLS | Özgün SQL, tipli wire parametreleri, ilan edilen RPC'ler |
| Classic TCP | Classic `mysqld.exe` | Yapılandırılan Classic portu | Classic SQL ve etkin native uzantılar |
| Classic'e wire köprüsü | `compatibility/wire_v1/service.py` | `127.0.0.1:7401`, TLS örneği | `wire_sql_basic_v1`; özgün SQL'in tam eşdeğeri değildir |
| SDK native SQL bağlantısı | Native aktarımı açık wire servisi | Yönetici tarafından verilen TLS portu | Ayrı native oturum, sıralı `?` parametreleri |
| Paylaşılan yerel dinleyici | Açıkça yapılandırılmış loopback paylaşımı | `localhost:3197` örneği | Yerel Classic istemci ve desteklenen wire istemci yolu |

`3197` örneğinde .NET `TLS Mode=Disabled` yalnız yapılandırılmış yerel geliştirme yoluna aittir. Uzak sunucu bağlantısının varsayılanı olarak kopyalanmamalıdır. Örnek portları kendi gerçek dinleyici ayarınızla değiştirin.

## TLS alanları neden birbirinden ayrı?

**Host/address** ağda nereye bağlanılacağını söyler. **TLS name/server name** karşıdaki sertifikanın hangi ad için geçerli olması gerektiğini söyler. **CA dosyası** hangi sertifika otoritesine güvenileceğini belirler. Örneğin bağlantı adresi `127.0.0.1`, sertifika adı `localhost` ise SDK'nın ayrı TLS name alanı bu farkı açıkça belirtir. Sertifikanın SAN alanında beklenen ad bulunmalıdır.

Kullanıcı adı ve parola, sertifika denetimiyle aynı işlem değildir. Doğru parola yanlış sunucuya gönderilmemelidir. Bağlantı hatasında CA dosyasını, sertifika adını, saati ve gerçek portu kontrol edin; doğrulamayı kapatmak isim uyuşmazlığını çözmüş sayılmaz.

## Capability yanıtını yorumlamak

| Capability | Pratik anlamı |
| --- | --- |
| `sql_crud_v1` | Özgün, kapsamlı wire SQL sözleşmesi için işaret |
| `wire_sql_basic_v1` | Classic köprüsünün sınırlı temel SQL aktarımı |
| `wire_sql_transactions_v1` | Köprüde kalıcı sonuç kaydıyla transaction desteği |
| `native_sql_v1` | Ayrı native oturum/SQL aktarımı mevcut |
| `sql_security_v1` | Özgün SQL kullanıcı/rol ve güvenlik kataloğu |
| `jobs_v1` | Özgün iş RPC ailesi; yeni public SQL JOB anlamına gelmez |

Bir bayrağın bulunmaması, kullanıcının gerekli izne sahip olmaması ve modülün kapalı olması farklı durumlar olabilir. Yöneticiyle paylaşacağınız teşhis kaydında bağlı Server sürümünü, seçilen yolu ve ilgili capability alanını birlikte belirtin. Bir eski test raporunda özelliğin geçmesi, bağlı instance'ın aynı özelliği açık sunduğunu kanıtlamaz.

## Örnekleri doğru yola yerleştirme

Bu kitapta `main.public.urunler` ve diğer üç parçalı adlar özgün motor içindir. Classic/native laboratuvarı `sdp_lab` şemasını kullanır. Köprüde `--schema` arka uçtaki mevcut InnoDB şemasını seçer; temel wire köprüsünden eğitimdeki `CREATE TABLE` betiklerini göndermek desteklenmez. Tablolar o profilin native/Classic yönetim bağlantısında hazırlanır.

Native bağlantı açıldıktan sonra aynı oturumda legacy SQL statement handle'ları, legacy transaction API'si ve native komutlar karıştırılmaz. Uygulamanız her iki yolu kullanıyorsa iki bağlantı nesnesi oluşturun ve iş akışını buna göre bölün. Bağlantı havuzunda native bağlantıyı normal wire bağlantı diye ödünç vermeyin.

## Bağlantı için toplanacak bilgiler

Kurulumu yapan kişiden motor/protokol, adres, port, TLS adı, CA dosyası, kullanıcı, gerekli nesne izinleri ve kullanılacak veritabanı/şema bilgisini alın. AI kullanacaksanız bunlara native aktarım durumu, model ve konuşma adları ile worker erişimini ekleyin. Bunlar sağlandığında kendi SDK'nızın bağlantı bölümünü doğrudan uygulayabilirsiniz.

## Kaynaklar

- [StarDataParadiseServer / README.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/README.md)
- [StarDataParadiseServer / compatibility/wire_v1/README.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/compatibility/wire_v1/README.md)
- [StarDataParadiseServer / contracts/sql/native-sql-v1.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/contracts/sql/native-sql-v1.md)
- [StarDataParadiseServer / SQL_SECURITY.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_SECURITY.md)
