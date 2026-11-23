---
title: "Transaction, commit, rollback ve belirsiz sonuç"
slug: "/sql/transaction"
---

# Transaction, commit, rollback ve belirsiz sonuç

**Kapsam:** original wire v1 SQL. Native SQL transaction akışı ilgili SDK sayfalarında ayrıca ele alınır.

Transaction, birlikte başarılı olması gereken değişikliklerin sınırıdır. Bir sipariş açarken stok düşümü, sipariş başlığı ve kalem aynı işin parçaları olabilir. Bir adım başarısız olduğunda diğerlerinin kalıcı kalmasını istemiyorsanız bu adımları aynı transaction'a koyarsınız.

## Original motorda kontrol nereden yapılır?

Server protokolünde `tx_begin`, `tx_commit`, `tx_rollback` ve savepoint işlemleri vardır. SDK'lar bunları kendi dilinin API'siyle sunar. CLI'da aşağıdaki ters eğik çizgili komutlar aynı işlemleri çağırır:

~~~text
\begin
\savepoint kontrol
\rollback kontrol
\release kontrol
\commit
~~~

Bunlar SQL gramerinin parçası değildir. SQL `BEGIN ... END` bloğu PL/SQL için kullanılır. Bir SQL dosyasını `--transaction single` ile çalıştırırken dosyaya ayrıca `\begin` eklemeyin; CLI bu modda açık transaction komutlarını reddeder.

## Bir siparişi atomik oluşturmak

Aşağıdaki örneğin tamamı **etkileşimli CLI oturumunda** kullanılır. Önce ürün 101'in stokunu kontrol edip bir azaltır, ardından yeni sipariş ve kalem oluşturur:

~~~text
\begin
UPDATE public.urunler SET stok = stok - 1
WHERE id = 101 AND stok >= 1;
~~~

Etkilenen satır sayısı **1** olmalıdır. Sonuç 0 ise sonraki adımlara devam etmeden `\rollback` yapın.

~~~sql
INSERT INTO public.siparisler (id, musteri_id, durum, toplam)
VALUES (2001, 1, 'hazirlaniyor', 750.00);

INSERT INTO public.siparis_kalemleri
    (siparis_id, urun_id, adet, birim_fiyat)
VALUES (2001, 101, 1, 750.00);
~~~

Sonuçları aynı transaction içinde okuyun. Deneme için `\rollback`; işlemi bilerek kalıcılaştırmak için `\commit` kullanın. Kodda etkilenen satır kontrolü, hata yakalama ve rollback dalı zorunlu iş akışıdır. Yalnız SQL ifadelerini art arda gönderip bütününün başarılı olmasını ummayın.

## Autocommit ve manuel mod

Autocommit modunda her normal yazma ifadesi kendi başına kalıcılaşabilir. İki ayrı INSERT'in ikinci adımı hata verirse ilk adım geri alınmış sayılmaz. Manuel transaction'da ise uygulama commit kararını verir.

Node.js ve Python'un wire bağlantıları gibi bazı SDK arayüzlerinin varsayılanı manuel transaction'dır. Native bağlantıların varsayılanı farklı olabilir. Varsayılanı tahmin etmek yerine seçtiğiniz SDK bölümünü okuyun ve uygulama açılışında modunuzu açıkça belirleyin.

## Kısa transaction tasarımı

Original SQL sözleşmesi tek bir exclusive serializable transaction lease tanımlar ve lease süresini sınırlar. Uzun transaction diğer oturumların beklemesine neden olabilir. Transaction açıkken kullanıcıdan onay beklemeyin, HTTP servisi çağırmayın veya büyük bir dosya yüklemesini bekletmeyin.

Veriyi ve gerekli iş girdilerini önce hazırlayın; veritabanında kısa süre içinde kontrol edin, değiştirin ve commit edin. Ağ veya dış servis koordinasyonu gerekiyorsa bunun için ayrı bir uygulama akışı kurun. Aynı bağlantıyı eşzamanlı istekler arasında paylaşmak bu problemi çözmez.

## Savepoint

Savepoint bütün transaction'ı bitirmeden bir alt adıma dönmeyi sağlar:

~~~text
\begin
\savepoint opsiyonel
~~~

Opsiyonel değişikliği yapın; bu adım istenmiyorsa `\rollback opsiyonel` kullanın. Transaction'ın tamamını sonlandırmak için yine commit veya tam rollback gerekir. Savepoint'i kalıcı bir sürüm veya bağımsız commit olarak değerlendirmeyin.

## Commit cevabı kaybolursa

En kritik durum, sunucu commit yapmışken cevabın istemciye ulaşmamasıdır. “Bağlantı koptu” demek “yazma olmadı” demek değildir.

Original wire yazmaları ve commit işlemleri 32 küçük harfli hexadecimal request token ile izlenir; SDK/CLI bu ayrıntıyı yönetir. Belirsiz hata token veriyorsa aynı kullanıcıyla yeni bağlantı açarak outcome sorgulayın. CLI:

~~~text
\outcome <hata-ile-donen-token>
~~~

`committed` ve LSN gelmesi işlemin kaydedildiğini gösterir. `unknown`, “rollback oldu” anlamına gelmez; kayıt bulunmamış veya saklama süresi geçmiş olabilir. Sözleşmedeki görünürlük penceresi 24 saattir ve aktöre bağlıdır. Bir belirsiz yazmayı otomatik tekrar göndermek çift sipariş veya çift stok düşümüne yol açabilir. Uygulamanın sipariş kimliği gibi iş anahtarlarıyla mutabakat yapın; çözülemeyen durumu normal başarı gibi göstermeyin.

**Kaynaklar:** [wire transaction ve outcome sözleşmesi](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/contracts/sql/SQL_RPC_V1.md), [CLI transaction/çıkış kodları](https://github.com/ParadiseIncDevelopers/StarDataParadiseCli/blob/95f07c6046662bfc3a49dc2ccced36898b0db07b/CLI.md), [oturum ve lease davranışı](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_SECURITY.md).
