---
title: "Model, kimlik bilgisi ve worker kurulumu"
slug: "/ai/model-kurulumu"
---

# Model, kimlik bilgisi ve worker kurulumu

**Kapsam:** Workbench 0.3.1 ve native AI profili. Sunucu/katalog kurulumunu yetkili yönetici yapar.

Bir model bağlantısını üç ayrı parça olarak hazırlayın: veritabanındaki model nesnesi, sağlayıcıya erişen kimlik bilgisi veya yerel model dosyası, bu bilgiyi kullanacak worker. Bu parçaların yalnız biri hazırsa konuşma tamamlanmayabilir.

## OpenAI veya Claude bağlantısı

Workbench'teki **AI modelleri → OpenAI bağla / Claude bağla** akışı maskeli anahtar girişi sunar. Kullanıcı kendi hesabındaki model kimliğini seçer/girer. Anahtar yerel Windows kasasında tutulur; SQL önizlemesinde anahtarın kendisi bulunmaz. Modelin `credential_ref` veya ilgili desteklenen başvurusu worker'ın güvenilir owner kaydıyla eşleşmelidir.

Anahtar kaydetmek tek başına ücretli inference başlatmaz. Bir konuşma oluşturulup AI işi kaydedildiğinde çalışan worker sağlayıcıya istek gönderir. Anahtarın kaydedilmiş olması, sağlayıcı kotasının bulunduğunu veya modelin erişilebilir olduğunu kanıtlamaz; bunlar gerçek çalışma akışında ayrıca görülür.

Uzak worker veya farklı Windows hesabı kullanılıyorsa yerel Credential Manager kaydı kendiliğinden paylaşılmaz. Güvenilir yönetici o worker kimliği için karşılık gelen bağı hazırlamalıdır. Anahtarı sorunu çözmek amacıyla SQL'e veya ortak bir JSON dosyasına yapıştırmayın.

## Yerel GGUF modeli

**GGUF dosyası seç** akışı dosyayı izinli import köküne kopyalar ve SHA-256 hesaplar. Kaynak model dosyası değiştirilmez. Önizlenen IMPORT isteği çalıştırıldıktan sonra worker dosya bütünlüğünü ve gerçek runtime yüklemesini kontrol eder; başarılı publication sonrasında model aktif olur.

Bu sürümün yerel yolu GGUF v2/v3 içindir. Her ONNX, checkpoint veya farklı biçimin aynı işlemle yüklenebileceği varsayılmaz. Model boyutunu, bağlam uzunluğunu ve bellek gereksinimini hedef makineyle eşleştirin. “Dosya seçildi” ile “model inference yapabiliyor” durumlarını arayüzde ayrı takip edin.

## Worker'ın güvenilir bağları

| Bilgi | Neden gerekir? |
| --- | --- |
| Server UUID | Yanlış veya yer değiştirmiş sunucuya bağlanmayı önlemek |
| Doğrulanmış SQL owner | Model/credential bağını doğru uygulama kimliğine sınırlamak |
| Worker actor | İş alma/yayımlama hesabının yetkisini doğrulamak |
| CA ve TLS adı | SQL sunucusunun kimliğini doğrulamak |
| Credential alias | Anahtarı SQL'de taşımadan sağlayıcıya erişmek |
| Import kökü/model deposu | Yerel dosya erişimini yönetilen sınırda tutmak |

Yerel worker başlatıcısı `StarDataParadiseAiWorker.exe` ve deployment runtime'ını kullanır. Kaynakta `connection.json` parolasız bağlantı bilgileri ve credential hedefi taşır. Worker SQL kopmasında kendi oturumunu yeniden açabilir; sonucu belirsiz provider isteğini otomatik yeniden çalıştırmaz.

## Yönetici için katalog sırası

Kaynak dağıtımındaki temel kurulum önce ortak iç kuyruğu `install --queue-only` ile hazırlar, ardından `catalog.sql` uygular. Araç/onay profili gerekiyorsa `tool_catalog.sql`, sonra `action_catalog.sql` eklenir. Kurulum/yükseltme bakım profilinde `--sdp-ai-actions=OFF` ile yapılır; başarılı tamamlanma ve eşleşen binary/katalog sonrasında `--sdp-ai-sql=ON --sdp-ai-actions=ON` ile temiz başlangıç gerekir.

Bu işlemler mevcut instance'ın yönetim planına göre uygulanmalıdır. Test dosyalarındaki fixture kurulumunu veya shim hesaplarını üretim kurulumunun yerine kullanmayın. Uygulama kullanıcılarına iç `sdp_ai`/`sdp_jobs` tablolarına doğrudan DML yetkisi verilmez; gerekli yordam izinleri açıkça tanımlanır.

## Kurulumun kabul ölçütü

Önce model nesnesi okunabilmeli ve ilgili native capability görünmelidir. Worker doğru sunucu/owner bağıyla hazır olmalıdır. Sonra küçük bir araçsız konuşmanın run kimliği, terminal durumu ve yanıtı alınmalıdır. Bir sorun varsa kimlik bilgisi kaydı, worker bağlantısı ve provider yanıtını ayrı teşhis edin. Bu akış [konuşma örneğinde](konusmalar.md) uygulanır.

## Kaynaklar

- [StarDataParadiseServer / compatibility/ai/README.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/compatibility/ai/README.md)
- [StarDataParadise / README.md](https://github.com/ParadiseIncDevelopers/StarDataParadise/blob/da02adde5ef156ca702e4ed8e88a2d8d4deab6f5/README.md)
