---
title: "Mevcut kapsam ve sonraki özellikler"
slug: "/referans/yol-haritasi"
---

# Mevcut kapsam ve sonraki özellikler

Bir kullanıcı kılavuzu, bugünkü çalışan sözleşmeyle gelecek tasarımını açık ayırmalıdır. Bir komutun tasarım notunda, ekran görselinde veya eski kabul denemesinde bulunması o komutun bağlı sunucuda kullanılabildiğini kanıtlamaz. Başlangıç noktası sürüm metadata'sı ve gerçek capability yanıtıdır.

## Mevcut ürün odağı

Server 0.5.2 kaynak sürümü SQL, PL/SQL, AI ve Knowledge ailelerini listeler. Workbench 0.3.1 kaynak açıklaması kullanıcıya ait OpenAI/Claude anahtarları, yerel GGUF importu, worker başlatma/durum ve ilgili SQL çalışma alanlarını anlatır. SDK'lar normal wire bağlantısının yanında, ilgili dillerde ayrı native SQL oturumu sunar.

Kısa SQL/PLSQL native uzantıları kendi kaynak ve kabul kayıtlarına sahiptir. Bunlar özgün wire grammar'ın otomatik genişlemesi değildir. Her komutun geçerli olduğu yol [Classic farkları](../veritabani/classic-farklari.md) bölümünde açıklanır; native dil uzantılarının ayrıntısı aynı bölüm ailesinde verilir.

## Açıkça ertelenenler

| Alan | Release'deki durum | Mevcut benzer adla karıştırılmaması gereken |
| --- | --- | --- |
| SQL HIST/Git | `sql_hist` ertelenmiş | Özgün History v1 log/read/diff/restore |
| Yeni public SQL JOB | `sql_jobs` ertelenmiş | Özgün jobs v1 ve scheduler RPC'leri |

Bu kitap ertelenen aileler için kullanıcıya çalışır CREATE/BRANCH/SYNC komutu vaat etmez. Gelecekte tamamlandıklarında ayrıca desteklenen söz dizimi, yetkiler, işlem modeli, kurtarma ve SDK eşleşmesi belgelenmelidir. Şu an tarih veya sürüm taahhüdü verilmez.

## Yeni bir özelliği dokümana ekleme ölçütü

Önce ürün kaynağı ve public sözleşmesi belli olmalıdır. Sonra ilgili motor/protokol üzerinde capability kapısı, hata kodları, yetki koşulları, kaynak sınırları ve kabul kanıtı bulunmalıdır. UI önerisi veya grammar derlemesinin başarılı olması, gerçek SQL yürütme ve kalıcılık kabulünün yerine geçmez. Belgenin örneği, varsa gereken katalog/worker kurulumu ve bağımsız test verisiyle birlikte verilmelidir.

Bir özellik yalnız belirli binary veya geliştirme fixture'ında doğrulanmışsa bunu genel release desteği diye sunmak yerine kapsamını yazın. Eski test raporunun kalan NOT_RUN bölümleri varsa tek bir PASS kaydından tüm sağlayıcılar için sonuç çıkarmayın.

## Dokümantasyonu güncel tutma

Sürüm yükseltmesinde önce release ve README karşılaştırılır; sonra değişen SDK imzaları, SQL grammar ve kurulum adımları incelenir. Örnek veri modeli ve beklenen sonuçlar tekrar doğrulanır. Kullanıcıların en çok kopyaladığı bağlantı, INSERT/UPDATE, commit ve hata kurtarma örnekleri önceliklidir. Kaynak commit'leri ve doğrulama sınırı [kaynak kayıtlarına](kaynaklar.md) yazılır.

## Kaynaklar

- [StarDataParadiseServer / release.json](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/release.json)
- [StarDataParadiseServer / README.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/README.md)
- [StarDataParadise / README.md](https://github.com/ParadiseIncDevelopers/StarDataParadise/blob/da02adde5ef156ca702e4ed8e88a2d8d4deab6f5/README.md)
- [StarDataParadiseServer / compatibility/upstream/sql-short-native.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/compatibility/upstream/sql-short-native.md)
