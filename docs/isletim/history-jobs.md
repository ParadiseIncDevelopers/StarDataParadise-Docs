---
title: "History, Decision ve kalıcı işler"
slug: "/isletim/history-jobs"
---

# History, Decision ve kalıcı işler

**Kapsam:** Özgün wire v1 modülleri. Yeni native SQL HIST/Git ve public SQL JOB ile aynı özellikler değildir.

Temel SQL ile doğru veri modelini kurduktan sonra geçmiş inceleme, açıklanabilir kural ve arka plan işi ihtiyaçları ortaya çıkar. Bu özellikleri etkinleştirirken sunucunun capability yanıtını ve hesap izinlerini denetleyin; SDK'da metodun bulunması tek başına yeterli değildir.

## History: değişiklikleri okumak

History revizyon, nesne kimliği ve tipli içerik üzerinden geçmişi incelemeyi sağlar. LOG değişiklikleri, READ geçmiş değerleri, DIFF iki revizyon arasındaki farkı sunar. Mevcut kullanıcı hakları geçmiş veride de uygulanır. Güncel tabloda erişemediğiniz veriyi eski revizyondan almak bir yetki atlama yolu değildir.

CLI örneği:

```text
\rpc history log {"target":"main.public.siparisler","limit":10}
```

Bu çağrıdan gerçek revizyon ve nesne bilgilerini alın. Bir örnek dosyada yazan 40 gibi bir revizyonun kendi instance'ınızda mevcut olduğunu varsaymayın. History'nin bazı okuma akışları açık transaction/sonuç bulunmamasını ister; kendi SDK yönetim sayfasındaki önkoşulları uygulayın.

Restore/revert akışı önce plan üretir. Planın hedefini, revizyonunu, etkilenecek satırları ve bağımlılıkları okuyun. Uygulama aynı plan ve uygun request token ile yapılır. Hedefin mevcut revizyonu değişmişse yeni plan hazırlanır. Restore mevcut geçmişi yok sayıp dosyayı geriye sarmak yerine yeni bir commit olarak ele alınır.

## Decision: kuralın nedenini açıklamak

Decision kuralları belirtilen tablo olayında koşul ve eylem tanımlar. SET kuralları türetilmiş alanı hesaplayabilir; ALLOW/DENY kuralları işlemin izin durumunu belirler. Kuralların önceliği, sürümü ve etkinliği önemlidir. Eğitim için adım adım tanım ve örnekler veritabanı bölümündeki Decision sayfasındadır.

WHYNOT ve WHATIF bir senaryoyu gerçek satır yazmadan değerlendirir. Bu sonuç, daha sonra gerçek yazma anında aynı koşulların hâlâ geçerli olacağını garanti etmez; sunucu yazmayı tekrar denetler. Bir açıklama aracını yetki veya eşzamanlılık kontrolünün yerine koymayın.

## Kalıcı işin transaction'a bağı

```text
\rpc job capabilities {}
\rpc job submit {"kind":"compute","count":10000}
```

Dönen gerçek `job_id` ile status/watch/cancel çağrılarını yapın. Açık transaction'daki submit önce oturuma özeldir; commit kuyruğa yayınlar, rollback işi başlatmaz. Bağlantı kapansa da yayımlanmış iş sunucuda devam eder. Server kesildiğinde sonucu yayımlanmamış aktif iş, kaynak profiline göre `interrupted` durumuna geçebilir.

| İş durumu | Anlam |
| --- | --- |
| queued / starting | Kuyrukta veya worker hazırlığında |
| running | Yürütülüyor |
| succeeded | Sonuç başarıyla yayımlanmış |
| failed | Bilinen başarısızlık |
| cancelled | İptalin kesin terminal durumu |
| interrupted | Kesinti sonrası tamamlanmamış iş |

## Takvim ve SQL betiği

Desteklenen iş/takvim türünü kendi capability yanıtından okuyun. Özgün scheduler aralık veya Windows zaman diliminde günlük saat, kaçırılan pencere için `skip`/`run_once`, sınırlı retry/backoff sunar. `sql_script` profili tek transaction içinde sınırlı sayıda SELECT/INSERT/UPDATE/DELETE yürütür; belgelediği ifade, byte ve satır sınırları vardır. `retrain` mevcut modeli anında değiştirmek yerine yeni model sürümü üretir; etkinleştirme ayrı adımdır.

Bu RPC ailesinin mevcut olması `CREATE JOB` gibi ertelenmiş yeni native SQL ailesini açmaz. Yeni HIST/SQL JOB fikirleri [sürüm kapsamı](../referans/surum-uyumluluk.md) ve [yol haritası](../referans/yol-haritasi.md) içinde ayrıca gösterilir.

## Kaynaklar

- [StarDataParadiseServer / HISTORY.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/HISTORY.md)
- [StarDataParadiseServer / DECISION.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/DECISION.md)
- [StarDataParadiseServer / JOBS.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/JOBS.md)
- [StarDataParadiseServer / release.json](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/release.json)
