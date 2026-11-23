---
title: "Node.js: stok servisi örneği ve sorun giderme"
slug: "/sdk/nodejs/08-uygulama-sorun-giderme"
---

# Node.js: stok servisi örneği ve sorun giderme

> **Kapsam:** SDK 0.2.0 · Wire v1 · mevcut `public.urunler` tablosu. Kod uygulamaya ait örnek servis katmanıdır.

SDK kullanımını web framework'ünden ayırmak, veri erişimini bağımsız bir iş fonksiyonu olarak düşünmeyi kolaylaştırır. Aşağıdaki servis bir ürünün stokunu azaltır. HTTP gövdesini ayrıştırma, kullanıcı kimliğini kontrol etme ve yanıt kodu seçme uygulamanın dış katmanında kalır. Servis, veritabanı bağlantısını açar, parametreli statement çalıştırır, etkilenen satırı denetler ve commit sonucunu döndürür.

## Tam iş fonksiyonu

Önce [bağlantı bölümündeki](02-baglanti.md) `db.mjs` dosyasını oluşturun. Sonra aşağıdaki kodu `stok-servisi.mjs` olarak kaydedin.

```js
import { OutcomeUnknownError } from 'stardataparadise';
import { openDatabase } from './db.mjs';

export async function stokAyir(urunId, adet) {
  if (typeof urunId !== 'bigint' || urunId <= 0n) {
    throw new TypeError('urunId pozitif BigInt olmalı');
  }
  if (typeof adet !== 'bigint' || adet <= 0n) {
    throw new TypeError('adet pozitif BigInt olmalı');
  }

  const db = await openDatabase();
  try {
    const result = await db.execute(
      `UPDATE public.urunler SET stok = stok - :adet
       WHERE id = :id AND stok >= :adet`,
      { id: urunId, adet },
    );
    const affected = result.affectedRows;
    await result.close();
    if (affected !== 1) {
      await db.rollback();
      return { durum: 'reddedildi', neden: 'Ürün yok veya stok yetersiz' };
    }
    await db.commit();
    return { durum: 'tamamlandi', urunId: urunId.toString(), adet: adet.toString() };
  } catch (error) {
    if (error instanceof OutcomeUnknownError) {
      return {
        durum: 'sonuc_belirsiz',
        requestToken: error.requestToken ?? null,
      };
    }
    throw error;
  } finally {
    await db.close();
  }
}
```

```js
// deneme.mjs
import { stokAyir } from './stok-servisi.mjs';
console.log(await stokAyir(101n, 2n));
```

Bu örnek sipariş kaydı üretmez; sadece stok ayırma işinin SDK yaşam döngüsünü gösterir. Gerçek sipariş akışında, aynı transaction'a sipariş INSERT'i ve kalem INSERT'lerini ekleyin. `sonuc_belirsiz` çıktısında kullanıcının işlemi körlemesine tekrarlamasına izin vermeden [receipt sorgulama akışını](05-transaction.md) çalıştırın. Kullanıcının aynı iş isteğini iki kez göndermesini engellemek için uygulama düzeyinde benzersiz iş anahtarı tasarlamak da ayrı bir gereksinimdir.

## Sonuçları uygulama katmanına taşıma

Başarı yalnızca SQL statement'ının kabul edilmesiyle tanımlanmaz; commit'in tamamlanması gerekir. İş kuralı reddi, teknik hata ve belirsiz sonuç farklı sonuçlardır. “Stok yetersiz” durumunda kullanıcı adet değiştirebilir. Kimlik doğrulama hatasında bağlantı ayarı düzeltilmelidir. Belirsiz commit durumunda yeni bir stok düşümü başlatmak yerine önceki işlemin akıbeti araştırılır.

Bu ayrımı API yanıtınızda da koruyun. Örnekte dönen metin kimlikler JSON ile güvenle taşınır. İstemcinin `urunId` ve `adet` alanlarını sayıya zorla çevirmesine gerek yoktur. Sunucudan gelen hata nesnesini bütün alanlarıyla son kullanıcıya yansıtmak yerine operasyon günlüğüne anlamlı kodları kaydedin ve kullanıcıya uygun açıklama verin.

## Yaygın sorunlar

| Belirti | Muhtemel neden | Kontrol |
| --- | --- | --- |
| ESM import hatası | Yanlış uzantı/modül ayarı | `.mjs` veya `type: module` |
| TLS bağlantısı kurulamıyor | Yanlış CA, ad veya port | `caFile`, `tlsName`, dinleyici |
| Bağlantı meşgul | Aynı bağlantıda paralel çağrı | İşleri sırala veya ayrı bağlantı kullan |
| Yeni sorgu başlayamıyor | Açık sonuç tüketilmemiş | `result.close()` ve `finally` |
| Yazılan satır görünmüyor | Manuel transaction commit edilmemiş | `commit()` sonucu |
| Büyük kimlik bozuluyor | `Number()` dönüşümü | `BigInt` ve metin JSON alanları |
| AI komutu desteklenmiyor | Wire bağlantısı veya eksik native capability | `connectNative()` ve Server kapsamı |
| Süre aşımından sonra çift işlem | Kör tekrar | Receipt/run tabanlı uzlaştırma |

## Kontrol edilebilir kabul denemesi

Ayrı bir laboratuvar ürününde başlangıç stokunu okuyun. Fonksiyonu pozitif küçük adetle bir kez çalıştırın; tamamlandı yanıtından sonra yeni bağlantıyla stokun azaldığını doğrulayın. Stoktan büyük bir adet gönderip reddedildi yanıtında değerin değişmediğini kontrol edin. Negatif ve sıfır girdinin SQL çalışmadan reddedildiğini değerlendirin. Bu adımlar rehber örneği için önerilen kullanıcı kabul denemesidir; doküman hazırlanırken canlı Server'da çalıştırılmış sonuç olarak sunulmaz.

SDK deposunun kendi kabul testleri gerçek TLS, tipler, yordamlar, iptal ve kayıp commit onayı için daha geniş fixture senaryoları içerir. Uygulamanızda bu testlerin varlığını kendi veri modelinizin doğrulandığı anlamına getirmeyin; iş kurallarınız için uygun laboratuvar doğrulamasını ayrıca yapın.

## Örnek dosyalar

Aynı klasöre alınabilecek dosyalar: [ilk-sorgu.mjs](pathname:///StarDataParadise-Docs/downloads/sdk/nodejs/ornekler/ilk-sorgu.mjs), [db.mjs](pathname:///StarDataParadise-Docs/downloads/sdk/nodejs/ornekler/db.mjs), [stok-servisi.mjs](pathname:///StarDataParadise-Docs/downloads/sdk/nodejs/ornekler/stok-servisi.mjs), [deneme.mjs](pathname:///StarDataParadise-Docs/downloads/sdk/nodejs/ornekler/deneme.mjs). Paket, çalışan Server, laboratuvar tabloları ve ortam değişkenleri önkoşuldur.

## Kaynaklar

- [SDK kabul senaryoları](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/tests/acceptance.mjs)
- [Transaction ve sonuç yaşam döngüsü](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/src/provider.mjs)
- [Hata sınıfları](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/src/errors.mjs)
