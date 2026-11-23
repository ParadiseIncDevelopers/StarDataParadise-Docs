---
title: "Node.js: CRUD ve sorgu sonuçlarını işleme"
slug: "/sdk/nodejs/03-crud"
---

# Node.js: CRUD ve sorgu sonuçlarını işleme

> **Kapsam:** SDK 0.2.0 · Wire v1 · `public.urunler` laboratuvar tablosu. Önceki bölümdeki `db.mjs` yardımcısı kullanılır.

CRUD; kayıt oluşturma, okuma, güncelleme ve silme işlemleridir. SDK bu işlemleri SQL ile gerçekleştirir. Wire API'de parametre işareti `:ad` biçimindedir; değerler ikinci argümanda bir nesne olarak verilir. Parametrenin adında SQL tarafında iki nokta bulunur, JavaScript nesnesinde sade anahtar kullanmak okunaklıdır.

Değerleri SQL metnine string birleştirme ile eklemeyin. Parametre bağlama, kullanıcı girdisini SQL yapısından ayırır ve gerçek veri tipinin taşınmasını sağlar. Parametreler tablo veya sütun adlarının yerine geçmez. Kullanıcıya sıralama seçeneği sunulacaksa sütun adını uygulamanızın sabit izinli listesinden seçin; serbest SQL parçasını sorguya eklemeyin.

## Oluşturma ve güncelleme

Aşağıdaki işlemler aynı transaction içinde yapılır. `9001` yalnızca örnek ürün kimliğidir; tekrar çalıştırmadan önce laboratuvar verinizi değerlendirin. Birincil anahtar çakışması yeni bir satırın aynı kimlikle oluşturulmasını engeller.

```js
import { Decimal } from 'stardataparadise';
import { openDatabase } from './db.mjs';

const db = await openDatabase();
try {
  const inserted = await db.execute(
    `INSERT INTO public.urunler (id, ad, fiyat, stok)
     VALUES (:id, :ad, :fiyat, :stok)`,
    { id: 9001n, ad: 'Klavye', fiyat: Decimal.parse('750.00'), stok: 12n },
  );
  console.log('Eklenen:', inserted.affectedRows);
  await inserted.close();

  const updated = await db.execute(
    'UPDATE public.urunler SET stok = :stok WHERE id = :id',
    { id: 9001n, stok: 15n },
  );
  console.log('Güncellenen:', updated.affectedRows);
  await updated.close();
  await db.commit();
} finally {
  await db.close();
}
```

Bir hata `commit()` öncesinde yayılırsa `finally` içindeki bağlantı kapatma açık transaction'ı geri alır. `commit()` cevabı kaybolursa sonuç belirsiz olabilir; bu senaryo [transaction bölümünde](05-transaction.md) ayrıca ele alınır. Wire sonuçlarının `affectedRows` değeri JavaScript `number` olarak gelir; native sonuçların alanı farklı tiptedir.

## Okuma ve sınırlı bellek kullanımı

```js
const result = await db.execute(
  `SELECT id, ad, fiyat, stok FROM public.urunler
   WHERE stok >= :esik ORDER BY id`,
  { esik: 1n },
);
try {
  for (;;) {
    const rows = await result.fetchMany(100);
    if (rows.length === 0) break;
    for (const [id, ad, fiyat, stok] of rows) {
      console.log(id.toString(), ad, fiyat.toString(), stok.toString());
    }
  }
} finally {
  await result.close();
}
```

Bu parça, açık bir `db` bağlantısının çevresinde çalıştırılır. `fetchMany(100)` istemciye en çok yüz satırdan oluşan bir grup döndürür. Tüm satırları diziye biriktirmediğiniz sürece uygulamanın satır tamponu büyümez. Sorgunun Server tarafındaki çalışma maliyeti ayrıca değerlendirilmelidir; küçük fetch boyutu kötü bir sorgu planını düzeltmez.

| API | Dönen değer ve kullanım |
| --- | --- |
| `fetchOne()` | Bir satır dizisi; mevcut küme bitince `null` |
| `fetchMany(n)` | En çok `n` satır; küme bitince boş dizi |
| `fetchAll()` | Mevcut sonuç kümesinin tüm kalan satırları |
| `for await ... of result` | Satırları sırasıyla tüketir |
| `columns` | Sütun adı ve SQL tipi metaverisi |
| `nextSet()` | Sonraki yordam sonuç kümesine geçer |
| `close()` | Kalan sonucu bırakır ve kaynakları kapatır |

`fetchAll()` küçük ayar tabloları için uygundur; büyük raporları kontrolsüz biçimde belleğe almak için kullanmayın. Satır dizisindeki sıranın SELECT listesindeki sırayla aynı olduğunu düşünerek isimleri açıkça yazın. `SELECT *` şema değiştikçe uygulamanın beklediği sütun sırasını bozabilir.

## Silme ve NULL

```js
const removed = await db.execute(
  'DELETE FROM public.urunler WHERE id = :id',
  { id: 9001n },
);
console.log('Silinen:', removed.affectedRows);
await removed.close();
await db.commit();
```

DELETE örneği filtrelidir; aynı komutu `WHERE` olmadan çalıştırmak çok daha geniş bir değişiklik yapar. Referans verilen ürünlerin silinmesi veri modelindeki kısıtlara bağlıdır. NULL göndermek istediğinizde `Bind(null, 'TEXT')` gibi açık tip kullanın; boş metin `''` ve SQL NULL farklı değerlerdir. Laboratuvarın `ad` sütunu `NOT NULL` olduğundan burada NULL örneği için müşteri eposta alanı gibi nullable bir sütun seçilmelidir.

## Kaynaklar

- [execute ve Result API](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/src/provider.mjs)
- [Bind ve Decimal tipleri](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/src/types.mjs)
- [Kabul örnekleri](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/tests/acceptance.mjs)
