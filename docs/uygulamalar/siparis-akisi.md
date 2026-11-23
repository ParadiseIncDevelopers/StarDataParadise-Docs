---
title: "Uçtan uca sipariş uygulamasını tasarlamak"
slug: "/uygulamalar/siparis-akisi"
---

# Uçtan uca sipariş uygulamasını tasarlamak

**Kapsam:** Ortak laboratuvar modeli; özgün wire SQL üzerinde uygulama transaction'ı. Dört dilin SDK örnekleri aynı veri modelini kullanır.

Bu bölümde tablo tasarımı, SQL ve SDK davranışını tek iş akışında birleştireceğiz. Müşteri 1, ürün 101'den iki adet almak istiyor. Başlangıçta ürün fiyatı 750.00, stok 20. Başarılı bir siparişin tutarı 1500.00 ve yeni stok 18 olmalıdır. Bunlar aynı transaction'ın sonuçlarıdır.

## Kabul ölçütleri

Sipariş ancak müşteri ve ürün mevcutsa, miktar pozitifse ve yeterli stok varsa oluşturulur. Ürün fiyatı sipariş kalemine kopyalanır; gelecekte ürünün liste fiyatı değiştiğinde geçmiş siparişin toplamı değişmez. Sipariş başlığı, kalemi ve stok değişikliği birlikte commit edilir. Başarısız işte bu üç değişiklikten yalnız biri kalmamalıdır.

| Veri | Kaynak/hesaplama | Neden saklanır? |
| --- | --- | --- |
| Sipariş kimliği | Uygulamanın benzersiz iş kimliği | Tek bir siparişi izlemek |
| Müşteri kimliği | Doğrulanmış müşteri seçimi | Sahiplik ve ilişki |
| Ürün kimliği | Seçilen ürün | Stok ve kalem ilişkisi |
| Birim fiyat | İşlem anında okunan exact decimal | Geçmiş fiyatı korumak |
| Miktar | Pozitif iş girdisi | Stok ve toplam hesaplama |
| Toplam | Birim fiyat × miktar | Siparişin tutarı |

## Transaction içindeki sıra

1. Girdileri uygulama katmanında tür ve aralık bakımından doğrulayın.
2. Doğru kullanıcıyla bağlantı açın; çok adımlı işi explicit transaction'a alın.
3. Ürünün fiyatını okuyun ve sonucu kapatın.
4. Stok güncellemesini yeterlilik koşuluyla yapın.
5. Etkilenen satır sayısı 1 değilse işi durdurup rollback yapın.
6. Sipariş başlığını ve kalemini aynı bağlantı/transaction içinde ekleyin.
7. Commit cevabını değerlendirin; kesin başarıyı uygulama iş kaydına bağlayın.

Koşullu stok SQL'i, API'ye göre bind adı uyarlanarak:

```sql
UPDATE public.urunler
SET stok = stok - :adet
WHERE id = :urun_id AND stok >= :adet;
```

Parametreler bu sayfadaki sayılarla metin birleştirerek gönderilmez. Java JDBC'de `?`, normal Node/Python/.NET wire arayüzünde ilgili adlandırılmış parametreler kullanılır. Aynı işin bir kısmını başka bir bağlantıda yapmak transaction bütünlüğünü bozar.

## Ön okuma neden tek başına yetmez?

Uygulama stoğu 20 okuyabilir, fakat yazma anına kadar başka bir sipariş de aynı ürünü isteyebilir. Gerçek UPDATE koşulunda stok yeterliliğinin bulunması ve etkilenen satır sayısının kontrolü bu iş kuralını yazma noktasında uygular. Veritabanındaki `CHECK(stok >= 0)` da veri bütünlüğünü destekler. Bu kontrollerin rolleri farklıdır: kullanıcıya erken mesaj vermek, doğru yazma koşulu kurmak ve geçersiz kalıcı veriyi reddetmek.

## Hatalı tekrarları önleme

Örneklerde Java sipariş 2001, .NET sipariş 2002 kullanır. Aynı örneği aynı kimlikle ikinci kez çalıştırmak duplicate key hatası verebilir; bu normaldir. Eğitimde ikinci deneme için yeni kimlik kullanabilir veya rollback senaryosu çalışabilirsiniz. Gerçek uygulamada yeni bir HTTP denemesi geldi diye aynı siparişe sürekli yeni kimlik üretmek doğru tekilleştirme değildir.

Commit cevabı kaybolursa kullanıcıya hemen “sipariş başarısız” demeyin. Wire request token'ın outcome kaydını sorgulayın; ardından uygulamanın sipariş kimliğiyle veriyi uzlaştırın. `unknown` durumunda işi inceleme akışına alın. Para tahsilatı veya bildirim gibi dış etkiler, veritabanı rollback'iyle geri dönmez; bunları commit sonrası ayrı durumlu işler olarak tasarlayın.

## Dört dilde uygulama

- [Node.js stok servisi](../sdk/nodejs/08-uygulama-sorun-giderme.md) asenkron bağlantı ve koşullu güncellemeyi gösterir.
- [Python stok servisi](../sdk/python/08-uygulama-sorun-giderme.md) DB-API ve context/exception akışını açıklar.
- [Java sipariş servisi](../sdk/java/uygulama-ornegi.md) fiyat, stok, başlık ve kalemi JDBC transaction'ında birleştirir.
- [.NET sipariş servisi](../sdk/dotnet/uygulama-ornegi.md) aynı işi ADO.NET komut ve transaction nesneleriyle yapar.

Node/Python stok örnekleri stok işleminin sınırını öğretir; tek başlarına sipariş başlığı/kalemi oluşturan tam ödeme sistemi değildir. Java/.NET sipariş projeleri iş akışının daha geniş bölümünü birleştirir. Her örneğin önkoşulunu ve değiştirdiği veriyi kendi README'sinden okuyun.

## Çalışma görevi

Boş laboratuvarı kurun ve dört tablo sayısını doğrulayın. Önce rollback edilen bir stok değişikliği yapın; stoğun 20 kaldığını görün. Sonra bir tam sipariş oluşturup stok 18, yeni başlık toplamı 1500.00 ve kalem miktarı 2 sonuçlarını sorgulayın. Son olarak stoktan fazla miktar talep edin ve hiçbir yeni siparişin kalıcılaşmadığını kontrol edin. Canlı ağ kesintisi senaryosu yalnız ayrılmış test ortamında, sunucu/SDK'nın desteklenen test akışıyla yürütülmelidir; üretim sürecini rastgele keserek denenmez.

## Kaynaklar

- [StarDataParadiseServer / SQL_COMPATIBILITY.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_COMPATIBILITY.md)
- [StarDataParadiseServer / TRANSACTIONS_AND_WAL.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/TRANSACTIONS_AND_WAL.md)
- [StarDataParadise.SDK.Java / README.md](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Java/blob/10b565b05f9f90d75b642ef8ed6aa11b712302d6/README.md)
- [StarDataParadise.SDK.NET / README.md](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/README.md)
