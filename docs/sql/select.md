---
title: "SELECT: veriyi okumak"
slug: "/sql/select"
---

# SELECT: veriyi okumak

**Kapsam:** original wire v1 SQL; ortak laboratuvar tabloları.

SELECT ile hangi sütunların ve hangi satırların sonuçta bulunacağını belirlersiniz. Sonuç, tablonun kendisi değildir; sorgu tamamlanırken oluşturulan bir veri görünümüdür. Sonuçtaki sütun sırası SELECT listesinin sırasını izler. Bir SDK satır değerlerini indeksle okuyorsa bu sıra sözleşmenin bir parçasıdır.

## Sütunları açıkça seçmek

~~~sql
SELECT id, ad, fiyat
FROM public.urunler
ORDER BY id;
~~~

| id | ad | fiyat |
| ---: | --- | ---: |
| 101 | Klavye | 750.00 |
| 102 | Fare | 350.00 |
| 103 | Monitör | 6500.00 |
| 104 | USB Hub | 900.00 |

Tabloyu değiştiren bir komut çalıştırmadıysanız beklenen satırlar bunlardır. DECIMAL değerin istemcide nasıl gösterildiği SDK'ya göre değişebilir; sayısal değer aynı olsa da ekrandaki ölçek ayrı bir biçimlendirme kararıdır.

Bir ayrıntı ekranında tek ürüne ihtiyaç varsa bütün tabloyu okuyup uygulamada aramak yerine sunucuda filtreleyin:

~~~sql
SELECT id, ad, fiyat, stok
FROM public.urunler
WHERE id = 101;
~~~

PK olan `id` için bir veya sıfır satır beklenir. Sıfır satır bulunması tek başına SQL hatası değildir. Uygulama bunu “ürün bulunamadı” sonucuna çevirebilir.

## Tablo takma adı

~~~sql
SELECT u.id, u.ad, u.stok
FROM public.urunler AS u
WHERE u.stok > 0
ORDER BY u.id;
~~~

`u` takma adı sorgunun içinde tabloyu temsil eder. Takma ad atandıktan sonra o tabloya ait nitelemeleri aynı takma ad üzerinden yazın. Özellikle JOIN bölümünde birden çok tablonun `id` sütunu bulunduğunda belirsizliği önler.

Bu motorda tablo takma adı ile SELECT çıktı sütununa ad verme aynı özellik değildir. İncelenen gramer SELECT ifadesinden sonra `AS yeni_ad` tanımlamıyor. Bu nedenle örnekler `SUM(toplam) AS toplam_tutar` gibi çıktı alias'ları kullanmaz. Rapor başlığını uygulamada veya sonuç metadata'sını eşleyen katmanda belirleyebilirsiniz.

## İfadeler ve hesaplanan değerler

~~~sql
SELECT id, ad, fiyat, stok, fiyat * stok
FROM public.urunler
WHERE id = 101;
~~~

Son ifade başlangıç verisinde 15000.00 değerini hesaplar. Tabloya yeni sütun eklemez ve `fiyat` veya `stok` değerini değiştirmez. Bu tür hesaplama, ekran için türetilen bir değeri depolamadan elde etmeyi sağlar.

Aritmetik operasyonlarda veri tipi önemlidir. BIGINT taşması hatadır; para benzeri değerlerde DECIMAL kullanın. İki NULL olmayan sayının çarpımı ile NULL içeren bir çarpım aynı davranışı üretmez. NULL hesaplama sonucunu etkileyebilir; [NULL](filtreleme-null.md) bölümündeki mantığı uygulayın.

## Tekrarlanan değerler

~~~sql
SELECT DISTINCT durum
FROM public.siparisler
ORDER BY durum;
~~~

Bu sorgu üç farklı durum üretir: `hazirlaniyor`, `iptal`, `tamamlandi`. DISTINCT bütün projeksiyon satırına uygulanır. `SELECT DISTINCT musteri_id, durum`, müşteri kimliği ve durum ikililerini tekilleştirir; tek başına müşteri listesini üretmez.

## Sonucu okumak ve kapatmak

Server sonucu parça parça verir. SDK'nın iterator, cursor veya reader yapısıyla tüm satırları işleyebilir; yalnızca ilk sayfaya ihtiyaç varsa sonucu açık bırakmadan kapatabilirsiniz. Sonuç kapatılmadan aynı bağlantıda ikinci sorgu başlatmak bir kaynak kullanım hatasına dönüşebilir.

`fetchmany(20)` benzeri bir çağrı ilk yirmi satırı uygulamaya alır; bu, SQL motorunun yalnızca yirmi satırlık iş yaptığı anlamına gelmez. Sorguya uygun WHERE yazmak ve indeksi değerlendirmek ayrı sorumluluklardır.

## Alıştırma

Stoku sıfır olan ürünün yalnızca kimliğini ve adını bulun:

~~~sql
SELECT id, ad
FROM public.urunler
WHERE stok = 0;
~~~

Beklenen tek kayıt `104, USB Hub` değerleridir. Bu sorguya ORDER BY eklemek sonucu değiştirmez, fakat daha sonra birden çok stok dışı ürün eklenirse gösterim sırasını belirler.

**Kaynaklar:** [SQL grameri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/sql/SQL.ebnf), [ayrıştırıcı](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/sql/syntax.cpp), [SQL sonuç sözleşmesi](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/contracts/sql/SQL_RPC_V1.md).
