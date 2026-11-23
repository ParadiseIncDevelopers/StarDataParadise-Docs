---
title: "Node.js: yordamlar, çoklu sonuçlar ve yönetim API'leri"
slug: "/sdk/nodejs/06-yordam-yonetim"
---

# Node.js: yordamlar, çoklu sonuçlar ve yönetim API'leri

> **Kapsam:** SDK 0.2.0 · Wire v1. Özellikler Server'ın capability ve kullanıcı izinlerine bağlıdır.

Uygulama tek bir SELECT'ten daha karmaşık bir iş yaptığında, sunucuda tanımlanmış bir yordamı çağırabilir. Wire API'de bunun yolu `execute('CALL ...', parameters)` kullanmaktır. Çağrılan yordamın var olması, parametre sayısı ve tiplerinin uyuşması, ayrıca kullanıcının çalıştırma izninin bulunması gerekir. Bir örnekte yordam adı görmek o yordamın varsayılan kurulumda otomatik geldiği anlamına gelmez.

## Yordam sonuçlarını sırayla okuyun

Kaynak kabul testindeki `sdk_list` yordamı aşağıdaki mekanizmayı gösterir. Bu ad test fixture'ına aittir; kendi ortamınızda aynı sözleşmeyle bir yordam oluşturmadıysanız uygulama yordamınızın adını ve parametrelerini kullanın.

```js
const result = await db.execute(
  'CALL sdk_list(:input_key, NULL)',
  { input_key: 1n },
);
try {
  const outRows = await result.fetchAll();
  console.log('OUT değerleri:', outRows);
  while (await result.nextSet()) {
    console.log('Küme adı:', result.setName);
    for await (const row of result) {
      console.log(row);
    }
  }
} finally {
  await result.close();
}
```

İlk sonuç kümesi OUT parametrelerini içerir; ardından yordamın ürettiği cursor kümeleri gelir. `nextSet()` ilerleme işlemini yapar, `setName` adlandırılmış cursor kümesini gösterir. İlk fetch'ten önce bütün metaverinin hazır olduğunu varsaymayın; bazı alanlar sonuç verisi çekildiğinde güncellenir. Bir kümeyi tamamen okumadan sonraki kümeye geçmek kalan satırları bırakır. Uygulama gerçekten bütün satırlara ihtiyaç duyuyorsa önce mevcut kümeyi tüketmelidir.

## İç içe değerler

```js
import { RecordValue, Collection } from 'stardataparadise';

const record = new RecordValue([
  ['urun_id', 1n],
  ['aciklama', 'Örnek kayıt'],
]);
const collection = new Collection([record, null, 3n]);
```

Bunlar `RECORD` ve `COLLECTION` bekleyen mevcut yordam parametrelerine bağlanabilir. Normal JavaScript nesnesini kendiliğinden SQL RECORD saymayın. Sarmalayıcı kullanılması alan sırasını, alan adlarını ve üyelerin tiplerini açık hale getirir. Tüm iç içe verileri tek bir JSON metnine çevirmek farklı bir sözleşmedir; sunucunun yordam tanımı hangi türü bekliyorsa o tür gönderilmelidir.

## Kullanılabilir özellikleri keşfetme

```js
const features = await db.capabilities();
console.log(features);
const health = await db.health();
const metadata = await db.metadata();
```

Bu çağrılar için açık sonucu kapatmış olun. Capability bilgisi bir özelliğin sunucuda ilan edildiğini gösterir; kullanıcının o özelliğe erişim izni olduğunu tek başına kanıtlamaz. Yönetim ekranı açılırken desteklenmeyen düğmeleri gizlemek yararlı olabilir, ancak güvenlik sınırı her zaman Server'ın yetki denetimidir.

| Metot | Amaç | Önkoşul |
| --- | --- | --- |
| `history(target, {limit})` | Mevcut wire History kaydını okumak | Hedef ve History erişimi |
| `validateDecision(sql)` | Decision tanımını doğrulatmak | İlgili özellik ve izin |
| `predict(name, features)` | Tanımlı/aktif modelden tahmin | Model ve uygun özellik alanları |
| `dataset(id)` | Dataset bilgisini almak | Mevcut dataset ve izin |
| `submitCompute(count)` | Wire compute işi göndermek | Jobs desteği ve izin |
| `job(id)` / `cancelJob(id)` | İşi izlemek / iptal istemek | İşin kimliği ve erişim |
| `administrationHealth()` | Yönetim sağlık bilgisi | Yönetici yetkisi |

```js
const history = await db.history('public.urunler', { limit: 20 });
console.log(history);
const submitted = await db.submitCompute(100);
console.log(await db.job(submitted.job_id));
```

İş göndermek, işin o anda tamamlandığı anlamına gelmez. Dönen `job_id` değerini koruyun ve durumu ayrı okuyun. İptal isteği de tamamlanmış işin etkilerini geri alan bir transaction değildir; durum geçişlerini tekrar sorgulayın. Bu örnekler kullanıcının ilgili yetkilere sahip olduğu laboratuvar ortamı içindir.

## Mevcut API ile yol haritasını ayırın

`history()` ve `submitCompute()` gibi wire metotları, yeni native SQL `HIST`/SQLgit ve SQL `JOB` sözdizimiyle aynı özellik değildir. İncelenen sürümde yeni native HIST ve SQL JOB ertelenmiştir. AI worker'ın iç kuyruğu da uygulamaya açık genel SQL zamanlayıcı olarak yorumlanmamalıdır. Uygulamanın özellik ekranını bu üç ayrı kavrama göre tasarlamak, desteklenmeyen bir SQL komutunu yanlış bağlantıya gönderme sorununu önler.

## Kaynaklar

- [Yordam ve yönetim örnekleri](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/tests/acceptance.mjs)
- [Result ve yönetim metotları](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/src/provider.mjs)
- [Record ve Collection](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/src/types.mjs)
- [Kapsam ve ertelenen özellikler](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/README.md)
