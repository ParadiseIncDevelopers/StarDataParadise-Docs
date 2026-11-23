---
title: "C/C++ SDK — Yönetim, History ve işler"
slug: "/sdk/c-cpp/05-yonetim"
---

# C/C++ SDK — Yönetim, History ve işler

**Kapsam:** Sunucunun ilan ettiği wire RPC aileleri; nesne ve yönetici izinleri ayrıca gerekir.

Yönetim arayüzleri aynı bağlantı üzerinde yapılandırılmış JSON istek/yanıtları kullanır. Bir fonksiyonun SDK başlığında bulunması, bağlı sunucunun ilgili modülü açık sunduğunu göstermez. Önce capability ve işlem ailesinin kendi destek yanıtını okuyun; ardından yalnız gerekli yetkileri taşıyan hesapla çağrıyı yapın.

| C fonksiyonu | Kullanım alanı | Örnek işlem |
| --- | --- | --- |
| `sdp_history_command` | Revizyon okuma ve geri yükleme | LOG, READ, DIFF, RESTORE |
| `sdp_decision_command` | Kural açıklama ve doğrulama | VALIDATE, WHYNOT, WHATIF |
| `sdp_job_command` | Kalıcı iş ve takvim | SUBMIT, STATUS, WATCH |
| `sdp_dataset_command` | Tipli veri kümesi snapshot'ı | CREATE, GET |
| `sdp_model_command` | Model yaşam döngüsü | TRAIN, EVALUATE, ACTIVATE |
| `sdp_backup_command` | Yedek arşivleri | CATALOG, VERIFY, RESTORE |
| `sdp_admin_command` | Sağlık, yapılandırma, bakım | STATUS, HEALTH |

## Salt okunur sağlık isteği

```cpp
sdp::client::Buffer output;
sdp_error error{};
auto status = sdp_admin_command(
    connection.native_handle(), SDP_ADMIN_HEALTH,
    sdp::client::text("{}"), output.put(), &error
);
sdp::client::check(status, error);
std::cout << output.view() << '\n';
```

`UNKNOWN` sağlık durumu kontrolün henüz yapılmamış olmasını ifade edebilir. `HEALTH_CHECK` gerçek ölçümü başlatır; HEALTH mevcut kanıtı okur. Kontrol zamanı ile sonucu birlikte gösterin. Yönetici yetkisi gerektiren çağrıyı uygulamanın her normal HTTP isteğine eklemek uygun bir tasarım değildir; ayrı işletim akışı kullanın.

## İş gönderme ve izleme

Compute işi için `kind`, sayım ve request token içeren istek gönderilir. Dönen `job_id` sonraki status/watch/cancel çağrılarının anahtarıdır. Açık transaction içinde iş talebi commit sonrasında görünür olur; rollback worker başlatmaz. Bu durum, “iş talebini ekledim, neden çalışmadı?” sorusunda ilk kontrol edilmesi gereken noktadır.

İstemcinin kapanması sunucudaki kalıcı işi otomatik iptal etmez. `cancel_requested` iptal talebinin kabul edildiğini, `state: cancelled` kesin son durumu ifade eder. Uygulama bu iki durumu aynı başarı mesajıyla göstermemelidir.

Takvim türleri zaman içinde genişleyebilir. Native SDK 0.4.1 `sql_script` ve `retrain` tariflerini aynı ABI üzerinden destekler; bağlı sunucudaki ilgili `kinds` bilgisini denetleyin. Yeni public `CREATE JOB` SQL ailesi bu eski RPC yeteneğiyle eşdeğer değildir ve mevcut release'de ertelenmiştir.

## History restore akışı

Restore önce hedef ve revizyondan bir önizleme planı üretir. Planın etkileyeceği nesne, satır/alan ve bağımlılıkları inceleyin. Apply yalnız plan kimliği ile yeni request token alır. Mevcut revizyon değişmişse yeni plan gerekir. Bu akışı “eski dosyayı yerine kopyala” şeklinde uygulamayın; veritabanı yeni bir değişiklik kaydı oluşturur ve mevcut yetkileri/kısıtları denetler.

## Yönetim yanıtlarını uygulamaya sunma

Wire JSON'undaki büyük kimlikler ondalık dizge olarak gelebilir. Bunları 32 bit sayıya daraltmayın. API yanıtını kullanıcıya göstermeden önce rolüne uygun alanları seçin. İş/backup/model kimliği ile durumunu ilişkilendirin; oturum, parola ve sağlayıcı secret'larını destek çıktısına taşımayın. Buffer sahipliği burada da SQL yanıtlarıyla aynıdır: her çıktıyı yalnız bir kez SDK'nın free işleviyle bırakın.

## Kaynaklar

- [StarDataParadiseDLLler / ABI.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseDLLler/blob/3199235c9641733332e9b8c82f9e875170c4eedb/ABI.md)
- [StarDataParadiseDLLler / include/StarDataParadiseDLLler.h](https://github.com/ParadiseIncDevelopers/StarDataParadiseDLLler/blob/3199235c9641733332e9b8c82f9e875170c4eedb/include/StarDataParadiseDLLler.h)
- [StarDataParadiseServer / JOBS.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/JOBS.md)
- [StarDataParadiseServer / release.json](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/release.json)
