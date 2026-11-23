---
title: "Node.js: transaction, rollback ve belirsiz sonuç"
slug: "/sdk/nodejs/05-transaction"
---

# Node.js: transaction, rollback ve belirsiz sonuç

> **Kapsam:** SDK 0.2.0 · `connect()` Wire v1. Native SQL hata kurtarma akışı farklıdır.

Transaction, birbirine bağlı değişiklikleri tek bir iş birimi olarak toplar. Bir ürünün stok düşümü ile sipariş oluşturulması aynı işin parçalarıysa uygulama bunları ayrı bağımsız commit'ler halinde bırakmamalıdır. SDK'da manuel commit varsayılandır ve transaction ilk gerekli işlemde tembel olarak başlar. `begin()` ile başlangıcı açıkça belirtebilirsiniz; açık transaction varken ikinci `begin()` çağrısı hata verir.

`execute()` başarısı sorgunun çalıştığını gösterir. Manuel kipte kalıcılık için `commit()` gerekir. `rollback()` mevcut transaction'ı geri alır. `close()` de henüz commit edilmemiş açık transaction'ı geri alarak bağlantıyı kapatır. Başarılı autocommit `CALL` ise kendisine ait kısa transaction'ı sonuçlar tamamen tüketildiğinde veya sonuç kapatıldığında commit eder; sonuç yaşam döngüsü burada iş sonucunun bir parçasıdır.

## Kontrollü stok azaltma

```js
import { openDatabase } from './db.mjs';

const db = await openDatabase();
try {
  const result = await db.execute(
    `UPDATE public.urunler SET stok = stok - :adet
     WHERE id = :id AND stok >= :adet`,
    { id: 101n, adet: 2n },
  );
  const changed = result.affectedRows;
  await result.close();
  if (changed !== 1) {
    throw new Error('Ürün yok veya yeterli stok bulunmuyor');
  }
  await db.commit();
} finally {
  await db.close();
}
```

`stok >= :adet` koşulu, kontrol ile değişikliği aynı SQL statement'ına taşır. Önce SELECT yapıp JavaScript'te kontrol ettikten sonra koşulsuz UPDATE yapmak, eşzamanlı işlemler arasında eski bilgiye dayanabilir. Yine de kullanıcı girdisinin pozitif tam sayı olması uygulama tarafından doğrulanmalıdır; negatif `adet` stok artırır. Daha büyük iş akışında aynı transaction'a sipariş ve sipariş kalemi INSERT'lerini ekleyin.

## Savepoint ile kısmi geri alma

```js
await db.begin();
await db.savepoint('istege_bagli');
// Bu noktadan sonra uygulamanın isteğe bağlı işlemleri yapılır.
await db.rollbackTo('istege_bagli');
await db.release('istege_bagli');
await db.commit();
```

Bu parça savepoint API sırasını gösterir; kendi iş statement'larınızı araya koyun. Savepoint yeni bağımsız transaction değildir. `rollbackTo()` öncesindeki değişiklikleri koruyarak işaretli noktadan sonrasını geri alır. Savepoint adları normal SQL identifier biçiminde olmalıdır; kullanıcı metnini doğrudan ad olarak kullanmak gerekli değildir.

## Commit cevabı kaybolursa

Ağ bağlantısının kopması, Server'ın yazmayı hiç yapmadığını kanıtlamaz. Commit kalıcı olduktan sonra onay istemciye ulaşmayabilir. `OutcomeUnknownError` bu durumu işaretler ve wire işleminde `requestToken` taşır. SDK mutasyonları kendiliğinden tekrar etmez.

```js
import { OutcomeUnknownError } from 'stardataparadise';
import { openDatabase } from './db.mjs';

async function commitAndInspect(db) {
  try {
    await db.commit();
    return { status: 'committed' };
  } catch (error) {
    if (!(error instanceof OutcomeUnknownError) || !error.requestToken) {
      throw error;
    }
    const recovery = await openDatabase({ autocommit: true });
    try {
      const receipt = await recovery.outcome(error.requestToken);
      return { requestToken: error.requestToken, receipt };
    } finally {
      await recovery.close();
    }
  }
}
```

Yardımcı, iş SQL'ini tekrar çalıştırmaz; durumu uygulama katmanına iletir. Kurtarma bağlantısı aynı Server ve aynı yetkili kullanıcı kimliğiyle açılmalıdır. `status: 'committed'` kaydı kalıcı commit'i doğrular. `status: 'unknown'` cevabı belirsizliği sürdürür; bunu rollback sonucu olarak yorumlamayın. Uygulamanız belirsiz işi tekrar tıklanabilir normal bir başarısızlık gibi göstermemeli; işlem token'ını koruyup uzlaştırma sürecine taşımalıdır.

## Retry ve hata günlüğü

`retryReads: true`, autocommit okumanın hazırlık aşamasında oturumu kaybettiği dar bir durumda tek yeniden bağlantı denemesini açar. Yazma, commit veya satırları okunmaya başlanmış sonucu tekrar başlatan genel retry mekanizması değildir. Hata günlüğünde `code`, `sqlstate`, `correlationId` ve varsa `requestToken` yararlıdır; parola, tam müşteri verisi ve sır içeren SQL parametreleri kaydedilmemelidir. Native hata alanları ve `runId` için [native bölümüne](07-native-ai.md) geçin.

## Kaynaklar

- [Transaction, request token ve retry uygulaması](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/src/provider.mjs)
- [Hata sınıfları](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/src/errors.mjs)
- [Kayıp commit onayı kabul senaryosu](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/tests/acceptance.mjs)
