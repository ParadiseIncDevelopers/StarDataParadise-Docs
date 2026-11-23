---
title: "Yedekleme ve geri yükleme"
slug: "/isletim/yedek-kurtarma"
---

# Yedekleme ve geri yükleme

**Kapsam:** Özgün Server `backup_v1` ailesi. Classic fiziksel arşiv ve binlog stratejisi ayrı kurulum planıdır.

Bir yedeğin varlığı ile geri yüklenebilirliği farklıdır. İşletim süreciniz yedek oluşturmayı, doğrulamayı, ayrı hedefte açmayı ve uygulamanın veri anlamını kontrol etmeyi kapsamalıdır. History revizyonu veya çalışan disk üzerindeki ikinci bir klasör, tek başına bağımsız yedek stratejisi sayılmaz.

## Backup alanını yapılandırın

Server config'ine data, log ve temp'ten bağımsız mevcut bir `backup` dizini eklenir. Yapılandırma yoksa `backup_v1` kapalıdır. Disk arızasından korunacak kopyalar için ayrı depolama seçin. Sunucu hizmet hesabının gereken yazma/okuma hakları olmalıdır; sıradan uygulama kullanıcısına backup yönetim hakkı verilmesi gerekmez.

## Oluşturma ve takip

Wire CLI'da yönetici bağlantısıyla:

```text
\rpc backup catalog {}
\rpc backup submit {}
```

İkinci yanıtın `job_id` değerini alın; `backup status` çağrısına bu gerçek kimliği gönderin. CLI yazma isteğinde gereken token'ı üretir. Ham SDK/RPC tüketicisi aynı token sözleşmesini kendisi uygulamalıdır. İstemcinin kapanması kalıcı sunucu işini durdurmaz.

| İşlem | Girdi ve amaç |
| --- | --- |
| `backup_submit` | Request token; isteğe bağlı boyut sınırı; iş oluşturur |
| `backup_status` / `backup_cancel` | Gerçek `job_id`; ilerleme veya iptal |
| `backup_catalog` | Arşiv kimliği ve doğrulama durumu |
| `backup_verify` | Gerçek `backup_id`; restore doğrulamasını tekrarlar |
| `backup_restore` | `backup_id` ve yeni `target_name`; ayrı hedef oluşturur |
| `backup_delete` | Seçili arşivi kaldırır; mevcut restore hedefini kaldırmaz |

## Arşivde ne bulunur?

Kaynak sözleşmesi storage, bağlı WAL segmentleri, checkpoint, tipli logical export ve manifest içerir. Manifest ilgili LSN, boyut ve SHA-256 bilgilerini kaydeder. Yedek hazır sayılmadan önce geçici instance'a restore ve fiziksel/tipli içerik eşitliği kontrolü yapılır. Model ve routine kayıtları ile ilgili History referansları da bu kapsamda ele alınır.

Bu özellik, sizin uygulamanızın bütün bağımlılıklarını otomatik yedeklediği anlamına gelmez. TLS özel anahtarı, bootstrap kimlik bilgisi ve dış worker credential'ları ayrı kurulum sınırındadır. Bunların yeniden sağlanması için işletim kaydınız olmalıdır; aynı arşiv içinden otomatik kopyalanacaklarını varsaymayın.

## Ayrı hedefe geri yükleme

Restore mevcut bir instance'ın üzerine yazmak yerine `temp/restores/<target_name>` altında yeni bir hedef oluşturur. Hedef varsa işlem reddedilir. Gerçek arşiv kimliğini catalog'dan seçin; yeni ve anlamlı bir hedef adı verin. Ardından geri yüklenen data için ayrı Server config'i, farklı port ve uygun TLS/kimlik kurulumuyla bağlantı açın.

Uygulama kabulünde tablo ve satır sayılarıyla birlikte anlamlı iş kontrolleri de yapın: sipariş başlıkları ile kalem toplamları uyumlu mu, gerekli yordamlar mevcut mu, ilgili müşteri/ürün anahtarları korunmuş mu? Yalnız “Server başladı” kontrolü bütün veri anlamını doğrulamaz.

## Saklama ve başarısızlık

Yeterli alan bulunmaması, eksik dosya, manifest bozulması veya hash uyuşmazlığı halinde hazır arşiv/restore hedefi yayımlanmaz. Durum kodunu iş kaydına taşıyın. Silme politikanız, en son doğrulanmış yedeği yanlışlıkla yok etmemelidir. Eski arşiv silme ile yeni arşivi doğrulama bağımsız adımlar olarak planlanabilir.

Özgün backup profilinde PITR kapalıdır; bağımsız kesintisiz WAL arşiv zinciri üretilmez. “Dün 14:37:12'ye kesin döneriz” gibi bir hedef bu özellikten çıkarılamaz. Classic ortamında binlog/GTID ve arşivleme, kendi doğrulanmış kurtarma tasarımınızın parçası olmalıdır.

## Kaynaklar

- [StarDataParadiseServer / BACKUP.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/BACKUP.md)
- [StarDataParadiseServer / ADMIN.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/ADMIN.md)
- [StarDataParadiseServer / compatibility/wire_v1/README.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/compatibility/wire_v1/README.md)
