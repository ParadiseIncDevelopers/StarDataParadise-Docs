---
title: "Windows üzerinde eğitim ortamını hazırlama"
slug: "/baslangic/kurulum"
---

# Windows üzerinde eğitim ortamını hazırlama

**Kapsam:** Özgün Windows x64 wire v1 Server. Classic kurulumu ayrı profile aittir.

Bu bölüm yeni ve boş bir eğitim instance'ı içindir. İşletme verisi içeren bir instance üzerinde başlangıç betiklerini çalıştırmayın. Var olan bir kurulumun ayarını değiştirecekseniz ürünün Reconfigure akışını ve yedekleme planınızı kullanın.

## 1. İstemci ile sunucu kurulumunu ayırın

Çevrimdışı Windows paketi ayrı MSI bileşenleri ve ortak `Setup.ps1` sihirbazı içerir. Yalnız mevcut bir sunucuya bağlanacaksanız Workbench veya CLI yeterli olabilir. Aynı bilgisayarda eğitim sunucusu çalıştıracaksanız Server bileşeni ve ona ait veri, log, temp, TLS ve gerekirse backup yolları hazırlanır.

İmzasız geliştirme paketi için kaynaktaki `-AllowDevelopment` seçeneği bulunur. Bu, geliştirme paketini bilinçli seçme seçeneğidir; her kurulum komutuna otomatik eklenmesi gereken bir bayrak değildir. Dağıtımın sürümünü ve sağlanan bütünlük bilgisini kendi teslim kaydıyla doğrulayın.

## 2. Bir instance'a ait dosyaları düzenleyin

| Dizin/dosya | Amaç |
| --- | --- |
| `C:/SDP/lab/data` | Veri deposu, WAL ve ilişkili kalıcı kayıtlar |
| `C:/SDP/lab/logs` | Sunucu günlükleri |
| `C:/SDP/lab/tmp` | Geçici çalışma alanı |
| `C:/SDP/lab/tls` | Sertifika zinciri ve özel anahtar |
| `C:/SDP/lab/server.json` | Instance yapılandırması |
| `C:/SDP/lab/ca.pem` | İstemcinin güveneceği CA; özel anahtar içermez |

Birden fazla instance aynı data dizinini paylaşmamalıdır. Farklı instance'lar için benzersiz port, isim ve çalışma dizinleri seçin. Özel anahtarın okunabilirliğini sunucu hesabı ve ilgili yöneticilerle sınırlayın.

## 3. Yapılandırmayı oluşturun

TLS dosyalarını yöneticinizden alabilirsiniz. Yalnız yerel ve boş eğitim instance'ı için [yerel TLS hazırlığı](yerel-tls.md) sayfasında ayrı bir CA ve localhost sertifikası oluşturma akışı bulunur. Bu dosyalar hazır olduktan sonra:

```json
{
  "instance_name": "egitim",
  "data_dir": "data",
  "log_dir": "logs",
  "temp_dir": "tmp",
  "tls_certificate": "tls/server-chain.pem",
  "tls_private_key": "tls/server-key.pem",
  "port": 7443,
  "max_connections": 16,
  "timeout_ms": 10000
}
```

Göreli yollar config dosyasının bulunduğu dizine göre çözülür. Varsayılan dinleme adresi loopback'tir. Uzak bağlantı açılması ayrıca `bind` ve `allow_remote` yapılandırmasını gerektirir. İlk eğitim için yerel bağlantı yeterlidir.

## 4. Yöneticiyi oluşturun ve başlatın

Server EXE dizininden:

```powershell
.\StarDataParadiseServer.exe --config C:\SDP\lab\server.json --bootstrap-admin local-admin
.\StarDataParadiseServer.exe --config C:\SDP\lab\server.json --initialize-storage
.\StarDataParadiseServer.exe --config C:\SDP\lab\server.json
```

Bootstrap parola girişini iki kez ister. Kaynak sözleşmesi 16–1024 UTF-8 bayt aralığını belirtir; Türkçe karakter sayısı ile UTF-8 bayt sayısı aynı olmayabilir. Parolayı komut satırı argümanına yazmayın. Başlangıç tamamlandığında `LISTENING` kaydından gerçek adres ve portu okuyun.

Bu sıra **ham binary ile yeni ve boş bir veri dizini** içindir. `--initialize-storage`, SQL için gereken storage dosyasını oluşturur; yalnız bootstrap yapıp başlatmak SQL'i kullanılabilir hale getirmez. Installer'ın storage'ı önceden hazırladığı instance'a veya mevcut veri dizinine bu başlatma komutunu yeniden uygulamayın. `--check-storage`, `--recover-storage` ve `--checkpoint-storage` ayrı bakım işlemleridir; normal bağlantı sorununda rastgele sırasıyla çalıştırılacak komutlar değildir.

## 5. İlk istemci denetimi

CLI dizininde, sertifikanızın adını kullanarak:

```powershell
.\StarDataParadiseCLI.exe --host localhost --port 7443 --user local-admin --ca C:\SDP\lab\ca.pem --status
```

Beklenen sonuç başarılı bir TLS/kimlik doğrulama ve sunucu durumudur. Ardından etkileşimli bağlantı açıp `\capabilities` çalıştırın. SQL laboratuvarını başlatmadan önce özgün SQL desteğini ve eğitim hesabının gerekli izinlerini kontrol edin.

## Kurulum sorununu ayırma

`LISTENING` yoksa önce Server günlüğünü ve dosya yollarını inceleyin. Sunucu dinliyorsa fakat TLS hatası varsa CA ve SAN eşleşmesine bakın. TLS başarılı fakat auth başarısızsa kullanıcı/parola ve hesap durumunu kontrol edin. Kimlik doğrulama başarılı olup SQL desteklenmiyorsa storage/capability ve doğru motor seçimini değerlendirin. Bu sırayla ilerlemek ağ sorununu SQL değiştirerek çözmeye çalışmanızı engeller.

Windows hizmeti olarak çalıştırma ve dosya izinleri [işletim bölümünde](../isletim/gozlemleme.md) açıklanır. Sihirbazdaki Repair program dosyalarını, Reconfigure instance ayarlarını ele alır; kaldırma işlemi kaynak kılavuzunda veri ve backup dizinlerini koruyacak şekilde tanımlanmıştır.

## Kaynaklar

- [StarDataParadiseServer / RUN.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/RUN.md)
- [StarDataParadiseServer / packaging/SETUP.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/packaging/SETUP.md)
- [StarDataParadiseServer / ADMIN.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/ADMIN.md)
- [StarDataParadiseServer / StarDataParadiseServer/service.cpp](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/StarDataParadiseServer/service.cpp)
- [StarDataParadiseServer / StarDataParadiseServer/storage_admin.cpp](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/StarDataParadiseServer/storage_admin.cpp)
