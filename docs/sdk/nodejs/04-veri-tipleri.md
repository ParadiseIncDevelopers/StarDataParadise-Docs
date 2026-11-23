---
title: "Node.js: SQL ve JavaScript veri tipleri"
slug: "/sdk/nodejs/04-veri-tipleri"
---

# Node.js: SQL ve JavaScript veri tipleri

> **Kapsam:** SDK 0.2.0. İlk tablo Wire v1 içindir; native farkları ayrıca gösterilir.

Veritabanındaki değeri doğru okumak, yalnızca ekrana yazdırmak değildir. Para tutarını JavaScript `number` içine dönüştürmek veya büyük bir kimliği normal JSON sayısına çevirmek, değer daha Server'a ulaşmadan hassasiyet kaybına yol açabilir. SDK bu yüzden bazı SQL tiplerini açık sarmalayıcılarla taşır. Uygulamanın API ve dosya dışa aktarma katmanı da bu hassasiyeti korumalıdır.

## Wire v1 tip eşlemesi

| SQL tipi | JavaScript değeri | Dikkat edilecek nokta |
| --- | --- | --- |
| `BOOLEAN` | `boolean` | `true`/`false`; metin değildir |
| `BIGINT` | `bigint` | İşaretli 64 bit sınırını aşamaz |
| `DECIMAL` | `Decimal` | En çok 38 basamak; ölçek korunur |
| `TEXT` | `string` | Unicode metin |
| `BLOB` | `Buffer`/`Uint8Array` | Metne dönüştürmeden baytları koruyun |
| `DATE` | `DateValue` | Takvim tarihi; saat dilimi taşımaz |
| `TIME` | `TimeValue` | Nanosaniye hassasiyetli gün içi saat |
| `TIMESTAMP WITH TIME ZONE` | `TimestampValue` | Epoch saniye, nanosaniye ve UTC ofseti |
| `RECORD`, `COLLECTION` | `RecordValue`, `Collection` | İç içe tipli değerler |
| SQL `NULL` | Okumada `null`; yazmada `Bind` | Girişte SQL tipi açıkça belirtilir |

`number` ile tam sayı gönderilebilir, ancak SDK güvenli JavaScript tam sayı aralığını denetler. Büyük kimliklerde baştan itibaren `BigInt` kullanın. `BigInt(Number(...))` ile kaybedilmiş basamaklar geri gelmez. Wire API kesirli `number` değerini otomatik olarak DECIMAL saymaz; para için `Decimal.parse('1299.90')` kullanın.

## Açık hassasiyet ve tipli NULL

```js
import { Bind, Decimal } from 'stardataparadise';

const parameters = {
  id: 101n,
  fiyat: Bind(Decimal.parse('1299.90'), 'DECIMAL', 12, 2),
};
const result = await db.execute(
  'UPDATE public.urunler SET fiyat = :fiyat WHERE id = :id',
  parameters,
);
await result.close();

const customer = await db.execute(
  'UPDATE public.musteriler SET eposta = :eposta WHERE id = :id',
  { id: 1n, eposta: Bind(null, 'TEXT') },
);
await customer.close();
```

Bu parçalar mevcut manuel transaction içinde kullanılır; ardından uygulama `commit()` veya `rollback()` seçer. `precision: 12, scale: 2` SQL tarafındaki `DECIMAL(12,2)` ile uyumludur. SDK ölçek küçültürken kayıplı bir dönüşümü sessizce yapmaz. Yuvarlama politikası iş kuralınızsa açıkça tanımlayın ve hesaplamayı o kurala göre yapın.

## Zaman değerleri

```js
import { DateValue, TimeValue, TimestampValue } from 'stardataparadise';

const tarih = DateValue.parse('2026-11-23');
const saat = TimeValue.parse('14:35:08.123456789');
const an = new TimestampValue(1795435200n, 123456789, 180);
```

Üç değer farklı soruları cevaplar: tarih takvim gününü, saat gün içindeki zamanı, timestamp belirli bir anı temsil eder. JavaScript `Date`, nanosaniye hassasiyetini tek başına koruyamaz. Tam veri gerekli olduğunda `TimestampValue.seconds`, `nanos` ve `offsetMinutes` alanlarını saklayın. Kaynak, sunucunun sabit UTC ofsetleriyle bağlama yaptığını belirtir; bir bölge adını tüm yaz saati kurallarının otomatik uygulanacağı garantisi olarak yorumlamayın.

## JSON yanıtı üretmek

```js
const apiItem = {
  id: id.toString(),
  ad,
  fiyat: fiyat.toString(),
  stok: stok.toString(),
};
const json = JSON.stringify(apiItem);
```

Uygulama API'nizde kimlik ve tutarı metin olarak vermek bilinçli bir sözleşme olmalıdır. JavaScript `JSON.stringify()` doğrudan `BigInt` kabul etmez. Her değeri gelişigüzel `Number()` ile çevirmek bu problemi görünüşte çözerken veri bütünlüğünü bozabilir. İstemcilere hangi alanların metin olduğunu API dokümanında belirtin.

## Native SQL farkları

`connectNative()` sonuçlarında işaretli ve işaretsiz tam sayılar `BigInt`, DECIMAL `NativeDecimal`, JSON `NativeJson`, zaman değerleri `NativeTemporal` olabilir. Native DECIMAL en çok 65 toplam basamak ve 30 kesir basamağıyla temsil edilir; bunu wire DECIMAL'in 38 basamak sınırıyla karıştırmayın. Native SQL `TIME` negatif veya 24 saatten uzun süreler taşıyabilir; wire `TimeValue` gün içi saat modelidir.

`NativeJson.text` özgün JSON sayılarının basamaklarını korur. `JSON.parse(value.text)` çok büyük sayıları JavaScript `number` olarak yuvarlayabilir. Kesin basamakların gerektiği rapor, imza veya arşiv senaryolarında özgün metni koruyun; parse etme kararını tüketicinin sayı modeline göre verin.

## Kaynaklar

- [Wire tiplerin uygulaması](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/src/types.mjs)
- [Native tiplerin uygulaması](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/src/native.mjs)
- [SDK README](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/README.md)
