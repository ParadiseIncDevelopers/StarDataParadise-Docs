---
title: "StarDataParadise nedir?"
slug: "/baslangic/stardataparadise-nedir"
---

# StarDataParadise nedir?

**Kapsam:** Ürün ailesi; Server 0.5.2 kaynak görünümü.

StarDataParadise, uygulamaların verisini sunucu üzerinde saklayıp SQL ve programlama dili SDK'ları aracılığıyla işlemesini sağlayan bir veritabanı ürün ailesidir. Sunucuya masaüstündeki Workbench, terminaldeki CLI veya uygulamanızın kullandığı SDK bağlanır. Aynı sistemdeki farklı kullanıcıların hangi nesneleri okuyabileceğini ve değiştirebileceğini sunucu denetler.

Bir satış uygulamasını düşünün: müşteri kimliği, ürün fiyatı, mevcut stok ve sipariş durumu kalıcı olmalıdır. Uygulamanın belleğinde tutulan bir liste, süreç kapanınca kaybolur. Bir veritabanında bu bilgiler şeması tanımlanmış tablolarda saklanır; sorgularla okunur ve transaction sınırları içinde değiştirilir. Örneğin stok azaltma ile sipariş oluşturmanın birlikte tamamlanması gerekir. Bunlardan yalnız birinin kalıcılaşması işletmenin kayıtlarını tutarsız bırakır.

## Ürünün parçaları ne yapar?

| Bileşen | Görevi | Tipik kullanıcısı |
| --- | --- | --- |
| Server | SQL yürütme, saklama, transaction, yetki ve etkin modüller | Uygulama ve sistem ekibi |
| Workbench | Bağlantı profili, SQL editörü, nesne ve veri araçları | Geliştirici, analist, yönetici |
| CLI | Etkileşimli terminal, betik ve otomasyon çıktısı | Geliştirici, dağıtım/işletim ekibi |
| SDK'lar | Programlama dilinden güvenli bağlantı ve sorgu | Uygulama geliştiricisi |
| AI worker | Kuyruğa kaydedilen model işini yerel veya uzak sağlayıcıyla yürütme | AI özelliğini işleten ekip |

Workbench bir istemcidir; veriyi saklayan sunucunun yerine geçmez. SDK da sunucuyu uygulamanın içine otomatik olarak kurmaz. Uygulama, çalışmakta olan ve uygun profille yapılandırılmış bir Server instance'ına bağlanır.

## SQL, PL/SQL ve AI arasındaki ilişki

SQL, hangi verinin okunacağını veya değişeceğini ifade eder. `SELECT` ürünleri okur, `INSERT` yeni bir sipariş ekler, `UPDATE` stok miktarını değiştirir. Tablo tanımı ve kısıtlar geçerli verinin yapısını belirler. PL/SQL tarafı, sunucuda saklanan yordamlar ve iş akışları için değişken, koşul ve döngü gibi yapılar sunar; desteklenen dil özgün motor ile Classic/native yolunda ayrıca değerlendirilir.

AI/Knowledge katmanı uygulamanın belirlediği kaynakları ve araçları bir model akışına bağlar. Knowledge tanımı, yetki denetimi altında çalışan tipli bir okuma arayüzüdür. Konuşma, prompt, yanıt ve araç politikaları bu arayüzü kullanabilir. Model tarafından üretilen bir cümlenin kendiliğinden veritabanı yetkisine dönüşmesi söz konusu değildir; çağrılabilecek araçlar ve onay gereksinimleri açıkça tanımlanır.

## İki motor yolunu neden bilmelisiniz?

Kaynak deposu hem Windows x64 özgün wire v1 motorunu hem Classic tabanlı motorun kaynak yamasını ve uyumluluk servislerini içerir. Bu nedenle “StarDataParadise SQL destekliyor” cümlesi tek başına bir söz dizimi garantisi değildir. Özgün motorun kendi SQL grammar'ı, tür sınırları ve yönetim RPC'leri vardır. Native SQL yolunda Classic oturumu ve AI uzantıları kullanılır. Hangi yeteneğin açık olduğunu sunucunun capability yanıtı bildirir.

Bu kitap SQL temellerini özgün motor üzerinde öğretir; native SQL ve AI bölümlerini ayrıca etiketler. Böylece örneğin özgün motordaki `main.public.urunler` adı ile Classic'teki `sdp_lab.urunler` adını aynı adlandırma sistemi sanmazsınız.

## İlk hedefiniz

İlk aşamada hedef, bir bağlantı açmak, yetenekleri görmek, birkaç tablo oluşturmak, bir satır ekleyip okumak ve işlemin ne zaman kalıcılaştığını anlamaktır. Ardından birden fazla tabloyu ilişkilendirir, uygulama koduyla transaction sınırını kurar ve beklenmeyen kesintilerde sonucu nasıl sorgulayacağınızı öğrenirsiniz. AI, History ve işler bu temel veri akışının üzerine eklenir.

**Kendinizi sınayın:** Bir SDK çağrısının başarılı döndüğü ama transaction'ın henüz commit edilmediği durumda satırın kalıcı olduğunu söyleyebilir misiniz? Hayır. Bağlantının transaction kipini ve commit sonucunu bilmeniz gerekir. Aynı kural bir dilin varsayılanı üzerinden diğer bütün SDK'lara genellenemez.

## Kaynaklar

- [StarDataParadiseServer / README.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/README.md)
- [StarDataParadiseServer / SQL_COMPATIBILITY.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_COMPATIBILITY.md)
- [StarDataParadiseServer / compatibility/ai/README.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/compatibility/ai/README.md)
