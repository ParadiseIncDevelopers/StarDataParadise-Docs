---
title: "Workbench ile günlük çalışma"
slug: "/araclar/workbench"
---

# Workbench ile günlük çalışma

**Kapsam:** Workbench 0.3.1; Qt wire v1 ve Classic Workbench bağlantıları.

Workbench, SQL öğrenirken ve uygulamanın ürettiği veriyi incelerken kullanacağınız masaüstü çalışma alanıdır. Bir profilin neye bağlandığını açıkça tanımlamak, doğru şemada çalışmak ve sorgu/transaction durumunu görmek günlük kullanımın temelidir. Kaynak deposundaki bir EXE çıktı yolu, başka bir bilgisayarda indirilebilir paket bağlantısı veya kurulum garantisi değildir; kendi dağıtımınızın EXE, DLL ve destek dosyalarını birlikte tutun.

## İlk profil

Qt istemcisinde **Connections → Manage profiles…** bölümünden adres, port, kullanıcı ve CA dosyasını girin. Sertifika adı bağlantı adresinden farklıysa **TLS name** alanını doldurun. **Test** bağlantı ayarını sınar; **Connect** SQL çalışma sayfasını açar. Yerel parola saklama seçeneği Windows Credential Manager kullanır. Profili paylaşırken parola saklandığını varsaymayın; başka bir Windows kullanıcısının aynı kayda erişimi ayrı konudur.

Classic Workbench için doğrudan Classic TCP ayarlarını kullanın. Yerel paylaşılan dinleyici özel olarak kurulmuşsa kaynak örneği `localhost:3197` adresidir. Bu portu, özgün Qt wire bağlantısının yerine tahmin ederek yazmayın. **Test Connection** sonrasında doğru sunucu/şema ile açıldığınızı doğrulayın.

## Sorgu yazma rutini

Bir değişiklik üzerinde çalışırken önce ihtiyacınız olan sütunları seçerek mevcut veriyi okuyun. Geliştirme sırasında `SELECT *` keşif için kullanılabilse de uygulama sorgusunda açık sütun listesi, veri sözleşmesini daha görünür kılar. SQL editöründe seçili metni çalıştırma ile bütün betiği çalıştırmayı ayırın; yalnız UPDATE'i seçmekle CREATE/INSERT dahil tüm betiği çalıştırmak farklı sonuç üretir.

Transaction kontrollerinden açık işlem durumuna bakın. Tablo düzenleyicisinde görünen bir değişikliğin ne zaman sunucuya gönderildiğini ve ne zaman commit edildiğini kullandığınız ekranın işlem akışıyla takip edin. Bir çalışma sayfasını kapatmak, başarılı commit cevabı yerine geçmez. Uzun açık transaction'ları başka işlere geçmeden bitirin.

## Nesne gezgini ve tablo inceleme

Nesne gezgininde yapı ile veriyi ayrı inceleyin. Yapı görünümü sütun tiplerini, NULL durumunu ve anahtarları anlamak içindir; veri görünümü o yapıya uyan satırları gösterir. Bir “müşteri” tablosu yalnız ad sütunundan ibaret değildir: anahtar, ilişki ve yaşam döngüsü tasarımı uygulamanın güvenilirliğini belirler. Veri aktarımını kullanmadan önce kaynak/ hedef türlerinin, özellikle decimal ve zaman alanlarının nasıl eşleştiğini kontrol edin.

Bir nesne görünmüyorsa hemen silindiğini düşünmeyin. Profilin farklı instance'a bağlanması, mevcut kullanıcının yetkisi, seçilen şema veya etkin modül farklılığı bu durumu açıklayabilir. Yetkisiz nesnelerin metadata'sı da filtrelenebilir.

## AI çalışma alanı

Güncel kaynak sürümünde OpenAI/Claude bağlantısı, yerel GGUF seçimi ve worker durumu/başlatma akışı bulunur. Model kurarken kaydettiğiniz anahtar ile SQL nesnesi birbirinden ayrıdır. Anahtar maskeli girişle yerel kasaya gider; SQL önizlemesinde anahtar yerine başvuru yer alır. AI SQL'i ilgili native çalışma alanında yürütün. Normal SQL editöründeki bağlantının native AI desteğine sahip olduğunu ayrıca doğrulayın.

HIST/Git ve yeni SQL JOB ekranları ertelenmiş durumdadır. Tasarım galerilerinin bulunması, o komutların kullanılabilir olduğu anlamına gelmez. Aktif ekrandaki capability durumunu kaynak sürüm bilgisiyle birlikte yorumlayın.

## Günlük bir görev örneği

“Stokta kalmayan ürünleri incele” görevi için doğru eğitim profiline bağlanın; `urunler` yapısında `stok` türünü doğrulayın; `SELECT id, ad, stok FROM main.public.urunler WHERE stok = 0;` çalıştırın. Ardından stok düzeltmesi gerekiyorsa ilgili ürün kimliğini ve iş gerekçesini belirleyip ayrı bir transaction'da değişikliği yapın. Görsel grid, WHERE koşulunun ve işlem sınırının yerini almaz.

## Kaynaklar

- [StarDataParadise / README.md](https://github.com/ParadiseIncDevelopers/StarDataParadise/blob/da02adde5ef156ca702e4ed8e88a2d8d4deab6f5/README.md)
- [StarDataParadiseServer / SQL_SECURITY.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_SECURITY.md)
