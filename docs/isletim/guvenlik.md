---
title: "Kullanıcı, rol ve uygulama güvenliği"
slug: "/isletim/guvenlik"
---

# Kullanıcı, rol ve uygulama güvenliği

**Kapsam:** Özgün wire SQL güvenlik kataloğu. Classic/native hesap sözdizimi ayrı değerlendirilir.

Bir uygulama veritabanına başarıyla bağlanabiliyor diye bütün tabloları ve yönetim işlemlerini kullanmamalıdır. Yetki tasarımı, uygulamanın hangi iş için hangi nesneye eriştiğini görünür kılar. Geliştirme sırasında bootstrap yöneticisiyle yapılan denemeyi gerçek uygulama hesabına taşımadan önce gerekli hakları ayırın.

## Özgün motorda kullanıcı ve rol

```sql
CREATE USER rapor_kullanicisi;
CREATE ROLE siparis_okuyucular;
GRANT SELECT ON TABLE main.public.siparisler TO ROLE siparis_okuyucular;
GRANT siparis_okuyucular TO USER rapor_kullanicisi;
```

`CREATE USER` hesabı kapalı durumda oluşturur. Parola, SQL metninin içine konmaz; kimliği doğrulanmış password_set işlemi veya CLI'daki `\password rapor_kullanicisi` akışı kullanılır. Başarılı parola kaydı hesabın kalıcı doğrulayıcısını etkinleştirir. Kullanıcı kendi parolasını değiştirirken eski parolasını kanıtlar; yönetici ayrı yetkiyle sıfırlama yapabilir.

Bu komutları Classic'teki `'user'@'host'` hesap tanımlarıyla birleştirmeyin. Kaynak profili farklıdır. Bir köprü hesabının etkin Classic kimliği, kullanıcı adından tahmin edilen bir host dizgesiyle değiştirilmemelidir.

## Haklar hangi anda kontrol edilir?

Özgün Server prepare, execute, fetch ve korunan yönetim çağrılarında güncel hakları denetler. Bir statement'ı daha önce hazırlamış olmak, sonra kaldırılan hakkı süresiz kullanma hakkı vermez. Metadata da kullanıcının nesne haklarına göre filtrelenir. Bir tablo görünmüyorsa doğru hesap ve role bakın; yönetici bağlantısıyla görünmesi, uygulama hesabının yetkili olduğunu kanıtlamaz.

GRANT/REVOKE ve parola değişiklikleri autocommit işlemleridir. Yetki değişikliklerini normal sipariş transaction'ının içine koyan genel bir migration betiği yazmayın. Güvenlik değişikliği de sonuç belirsizliğine konu olabileceği için kalıcı sonucu gerektiğinde doğrulayın.

## Uygulama katmanı kuralları

SQL parametreleme değerler içindir. Tablo/sütun adı gibi yapısal parçaları kullanıcıdan doğrudan almayın; bir seçim sunuyorsanız uygulamada izinli adlarla eşleyin. Sorguyu ekranda önizlemek, gerçek çalıştırmada yetki ve iş kuralı denetiminin yerine geçmez.

Tek bir yöneticinin parolasını bütün hizmetlere dağıtmak yerine hizmetin gereken tablo ve yordam haklarını tanımlayın. Okuma hizmeti yalnız okuma rolüyle, yazma hizmeti gerekli DML haklarıyla, operasyon görevi ayrı yönetim hesabıyla çalışabilir. Eğitimdeki basit rol örneği bütün üretim haklarını kapsayan bir hazır güvenlik politikası değildir; sizin nesne modelinize göre daraltılır.

## Bağlantı havuzu ve kimlik

Session reset açık işlem, ifade ve okuyucu durumunu bırakabilir; kullanıcı kimliğini değiştirmez. Başka kullanıcı adına işlem yapmak için aynı bağlantının metadata'sını değiştirmek yerine yeni doğru kimlikli oturum gerekir. Havuzdaki bağlantıyı tekrar kullanmadan önce önceki işten kalan transaction ve sonuç durumunu temizleyin. SDK'nın native bağlantısı ile normal wire bağlantısını aynı havuz kategorisi altında karıştırmayın.

## Günlüklerde ne olmalı?

İş kimliği, Server sürümü, hata kodu, SQLSTATE, correlation ID ve gerektiğinde request token/run ID çoğu teşhis için yeterli başlangıçtır. Parola, TLS özel anahtarı ve sağlayıcı secret'ı günlük konusu değildir. SQL parametreleri kişisel veya ticari veri içeriyorsa hata raporuna bütünüyle dökmek yerine gereken alanı sınırlayın.

## Yetkiyi nasıl sınarsınız?

Uygulama hesabıyla izinli bir okumanın başarılı, izinsiz bir yazmanın reddedildiğini görün. Ardından bir rol hakkını kaldırıp mevcut oturumdaki sonraki isteğin davranışını kontrol edin. Sınama, doğru kullanıcıyla ve izolasyonlu eğitim verisiyle yapılmalıdır. Sunucu kaynak sözleşmesinin ne vaat ettiğini bilmek, dağıtımınızın izinlerini gözlemlemenin yerine geçmez.

## Kaynaklar

- [StarDataParadiseServer / SQL_SECURITY.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_SECURITY.md)
- [StarDataParadiseCli / CLI.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseCli/blob/95f07c6046662bfc3a49dc2ccced36898b0db07b/CLI.md)
- [StarDataParadiseServer / compatibility/ai/README.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/compatibility/ai/README.md)
