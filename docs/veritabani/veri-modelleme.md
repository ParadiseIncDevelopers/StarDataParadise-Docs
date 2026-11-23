---
title: "Tablo tasarımı ve veri modelleme"
slug: "/veritabani/veri-modelleme"
---

# Tablo tasarımı ve veri modelleme

İyi bir tablo tasarımı, ekranın görünümünü kopyalamakla başlamaz. Önce uygulamanın hangi varlıkları ve ilişkileri yönettiğini belirleyin. Müşteri, ürün ve sipariş ayrı varlıklardır. “Siparişte hangi üründen kaç adet var?” sorusu ise sipariş ile ürün arasındaki ilişkiyi ifade eder.

Bu sayfadaki tasarım önerileri genel ilişkisel modelleme ilkeleridir. Çalıştırılabilir model [ortak laboratuvar](laboratuvar.md) içinde original wire v1 tipleri ve kısıtlarıyla verilmiştir.

## Bir satır neyi temsil ediyor?

Her tablo için tek cümlelik bir tanım yazın:

| Tablo | Bir satırın anlamı |
| --- | --- |
| musteriler | Bir müşterinin güncel temel bilgileri |
| urunler | Bir ürünün güncel satılabilir bilgileri |
| siparisler | Bir siparişin başlığı ve iş durumu |
| siparis_kalemleri | Bir siparişteki bir ürün ve sipariş anındaki fiyatı |

“Bir satır bazen müşteri, bazen ürün bilgisidir” gibi bir anlam varsa tabloyu ayırmanız gerekebilir. Sütunların çoğunun farklı satır tiplerinde boş kalması, modelde birden çok varlığın karıştığına işaret edebilir.

## Tekrarlı alanlardan ilişkiye geçmek

`urun1_id`, `urun2_id`, `urun3_id` gibi sütunlar eklemek siparişin en fazla üç ürün içerebilmesi sorununu yaratır. Yeni bir kalem için şema değişikliği gerekir. Kalem tablosunda ise her ürün ayrı satırdır; yeni kalem eklemek veri işlemidir.

Benzer biçimde `"101,102,103"` gibi virgülle ayrılmış bir kimlik listesi FK ile doğrulanamaz ve JOIN'i zorlaştırır. İlişkiyi ayrı satırlarda tutmak veri bütünlüğünü, filtrelemeyi ve toplulaştırmayı kolaylaştırır.

## Bilginin tek sahibi

Müşteri adı her siparişte yalnızca güncel müşteri bilgisi olarak tekrarlanırsa ad değişikliğinde birçok satırı güncellemeniz gerekir. Güncel müşteri adının sahibi `musteriler` tablosudur; sipariş müşteri kimliğini taşır.

Ancak fatura veya teslimat anındaki adresin değişmeden korunması gerekiyorsa tarihsel bir kopya tutmak doğru olabilir. Buradaki karar “tekrar her zaman kötüdür” değildir. Sütunun anlamı güncel bilgi mi, işlem anındaki bilgi mi, bunu açıkça tanımlamaktır.

Laboratuvarda `urunler.fiyat` güncel satış fiyatıdır. `siparis_kalemleri.birim_fiyat` sipariş anında kabul edilen fiyattır. Ürünün fiyatını güncellemek geçmiş kalemlerin fiyatını değiştirmez.

## Türetilen değerleri saklamak

`siparisler.toplam`, kalemlerden hesaplanabilir. Bu alan örneklerde işlem başlığını ve tutarlılık sorununu göstermek için ayrıca saklanır. Gerçek uygulamada iki seçenek bulunur: toplamı her okumada kalemlerden hesaplamak veya toplamı saklayıp her kalem değişikliğinde aynı transaction içinde güncellemek.

İkinci seçenek okumayı kolaylaştırabilir, fakat tutarsızlık riskini uygulamaya taşır. PK ve FK, “başlık toplamı kalem toplamına eşittir” kuralını tek başına sağlamaz. Periyodik mutabakat sorguları ve aynı transaction'da güncelleme bu tasarımın parçalarıdır.

## Kimlik seçimi

Kimlik mümkün olduğunca varlığın ömrü boyunca değişmeyen bir alan olmalıdır. Müşteri e-postasını tek PK yapmak, e-posta değişikliğini bütün ilişkileri etkileyen bir işleme dönüştürür. Ayrı BIGINT kimlik ve gerekirse e-posta UNIQUE kısıtı daha açık bir ayrım sağlar.

Sipariş kalemlerinde bileşik anahtar `(siparis_id, urun_id)` kullandık. Bu modelin iş kuralı “bir ürün bir siparişte tek kalemdir” şeklindedir. İndirim, vergi veya parti bazında aynı ürünün ayrı kalemleri gerekiyorsa `kalem_id` ya da `(siparis_id, satir_no)` gibi başka bir anahtar gerekir.

## NULL ve durum alanları

Zorunlu bilgiyi NOT NULL ile tanımlayın; isteğe bağlı bilgide NULL'ın ne anlama geldiğini belgeleyin. Boş metin veya -1 gibi sihirli değerler kullanmak her sorguya ek yorum yükler.

Durum alanı için kontrol edilebilir küçük bir değer kümesi belirleyin. Laboratuvar `hazirlaniyor`, `tamamlandi`, `iptal` değerlerini CHECK ile sınırlar. Bu CHECK, geçiş sırasını denetlemez. “Tamamlanan sipariş tekrar hazırlanmaya dönemez” gibi bir kural uygulama UPDATE koşulu, Decision veya uygun bir sunucu mantığı gerektirir.

## Tasarım incelemesi

Her yeni tabloda şu soruların cevabı bulunmalıdır: Bir satırı benzersiz kılan nedir? Hangi ilişki isteğe bağlıdır? Kimlik silinirse bağlı veriye ne olacak? Hangi alan işlem anındaki geçmişi korur? En sık hangi WHERE koşulları çalışacak? Bu sorular, sonradan eklenen rastgele index ve yardımcı sütunlardan daha etkili bir başlangıç sağlar.

**Kaynaklar:** [uygulanabilir kısıt ve tip kapsamı](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_COMPATIBILITY.md), [laboratuvar şeması](/downloads/ornekler/sql/01_sema.sql). Tasarım gerekçeleri bu rehberin örnek uygulama tercihlerini açıklar.
