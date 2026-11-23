---
title: "Instance, sağlık ve performans gözlemi"
slug: "/isletim/gozlemleme"
---

# Instance, sağlık ve performans gözlemi

**Kapsam:** Özgün Windows Server yönetimi ve wire admin RPC'leri.

İşletimde ilk soru “sunucu çalışıyor mu?” olabilir, fakat yeterli değildir. Aktif transaction sayısı, kilit beklemeleri, storage sağlığı, sertifika geçerliliği, yedek doğrulaması ve iş kuyruğu farklı sinyallerdir. Ölçümün zamanı ve kanıtı durum kadar önemlidir.

## Instance düzeni

Her instance için benzersiz `instance_name`, port, data, log, temp ve gerekirse backup dizini kullanın. Veri dizinini paylaşan iki süreç açmayın. Bir instance'ı hizmet haline getirirken işletim sistemi hizmet hesabının config ve TLS dosyalarını okuyabildiğini, yalnız ilgili çalışma dizinlerine yazabildiğini doğrulayın.

```powershell
.\StarDataParadiseServer.exe --config .\server.json --service install
.\StarDataParadiseServer.exe --config .\server.json --service start
.\StarDataParadiseServer.exe --config .\server.json --service status
```

Bu komutlar yerel Windows Service Control Manager yetkisi gerektirir. Windows yöneticisi olmakla veritabanı administrator hesabı ayrı yetkilerdir. Hizmet kimliği `StarDataParadise-<instance_name>`, hesap `NT SERVICE\StarDataParadise-<instance_name>` biçimindedir. Kaldırma hizmet kaydını ele alır; instance dosyalarını aynı işlem diye değerlendirmeyin.

## Durum ile ölçüm farkı

```text
\rpc admin status {}
\rpc admin health {}
\rpc admin health-check {"check":"storage"}
```

`admin_status` oturum, transaction, kilit bekleme ve storage bilgilerini döndürür. Kaynakta 250 ms ve üstündeki tamamlanan sorgu olayları görünür. `admin_health` en son kontrolün sonucunu okur; `admin_health_check` seçilen kontrolü çalıştırır. Henüz ölçülmeyen bir alanın `UNKNOWN` görünmesi, ölçülmüş sağlıksız sonuçla aynı değildir.

| Kontrol | İncelenen alan |
| --- | --- |
| storage | Sayfa bütünlüğü ve ilgili kaynak kullanımı |
| history | Journal bütünlüğü ve saklama kullanımı |
| backup | Doğrulanmış arşiv manifest kanıtı |
| certificate | TLS sertifikası durumu |
| jobs | İş yürütme sağlığı |

Kontrol sonuçlarını saat ve instance kimliğiyle ilişkilendirin. Farklı porttaki eğitim instance'ından alınmış sağlıklı durum, üretimdeki instance'ın kanıtı değildir.

## Yavaşlıkta inceleme sırası

Önce sorunun bağlantı açmada mı, sorgu yürütmede mi, fetch sırasında mı, commit'te mi yoksa AI yanıt beklemede mi olduğunu belirleyin. Sorgu yavaşsa planı, filtreyi, dönen satır sayısını ve indeks uygunluğunu kontrol edin. Fetch sırasında sorun varsa açık okuyucunun yaşam süresi ve uygulama işlemesi belirleyici olabilir. Commit yavaşlığını dış sağlayıcı yanıt süresiyle birleştirmeyin.

Özgün motorun kaynakta bildirdiği sınır ve destek bayraklarına göre değerlendirme yapın. Deadlock grafiği gibi kapalı bir capability'nin arayüz taslağı olması, gerçek teşhis verisi sunduğu anlamına gelmez. Uygulama aynı bağlantıyı iki işe paylaştırıyorsa görülen gecikme sorgu planından önce bağlantı kullanım modelinden kaynaklanabilir.

## Yapılandırma değişikliği

`admin_config_preview` değişikliği doğrular; `admin_config_apply` izinli ayarı önceki dosyayı koruyarak uygular. `timeout_ms` yeni ağ I/O sınırlarında ve yeni SQL oturumlarında etkili olur. Port ve max_connections değişiklikleri restart gerektirir. Kullanıcıya “ayar kaydedildi” ile “yeniden başlatma tamamlandı ve yeni port hizmet veriyor” durumlarını ayrı gösterin.

## Destek kaydı

`admin_support_preview` ve `admin_support_create` izinli config alanları ve redakte log özetleri üretir. Genel terminal çıktısını, bütün SQL parametrelerini ve secret'ları rastgele tek dosyada toplamak yerine bu destek akışını kullanın. Bir olay raporunda zaman, instance/sürüm, son başarılı işlem, hata kodu, correlation ID ve varsa request token/run ID birlikte bulunmalıdır.

## Kaynaklar

- [StarDataParadiseServer / ADMIN.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/ADMIN.md)
- [StarDataParadiseServer / RUN.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/RUN.md)
- [StarDataParadiseCli / CLI.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseCli/blob/95f07c6046662bfc3a49dc2ccced36898b0db07b/CLI.md)
