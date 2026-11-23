---
title: "Node.js: native SQL ve AI oturumları"
slug: "/sdk/nodejs/07-native-ai"
---

# Node.js: native SQL ve AI oturumları

> **Kapsam:** SDK 0.2.0 · `connectNative()` · Server'ın `native_sql_v1` ilan ettiği ayrı native oturum.

Native SQL bağlantısı, SDK'nın wire CRUD bağlantısından farklı bir kullanım yüzeyidir. Native oturumda SQL Classic tarafında derlenir, parametreler konumsal `?` işaretleriyle verilir ve sonuçlar `sets` içinde materyalize edilir. `connect()` ile açılan bağlantıya `START AI CONVERSATION` göndererek aynı özelliği açmış olmazsınız. `connectNative()` açılışta capability kontrolü yapar ve destek yoksa hata verir.

## İlk native sorgu

```js
import { connectNative } from 'stardataparadise';

const db = await connectNative({
  host: '127.0.0.1',
  port: Number(process.env.SDP_NATIVE_PORT ?? '7443'),
  user: process.env.SDP_USER,
  password: process.env.SDP_PASSWORD,
  caFile: process.env.SDP_CA,
  tlsName: process.env.SDP_TLS_NAME ?? 'localhost',
  timeoutMs: 75000,
});
try {
  const result = await db.execute(
    'SELECT id, ad FROM sdp_lab.urunler WHERE id = ?',
    [101n],
    { maxRows: 100 },
  );
  console.log(result.sets[0].rows);
} finally {
  db.close();
}
```

`sdp_lab.urunler` Classic/native laboratuvarında önceden oluşturulmuş olmalıdır; orijinal motorun `main.public` tablosuyla aynı fiziksel nesne olduğu varsayılmaz. `SDP_NATIVE_PORT` burada uygulama tarafından okunan ayardır. Native destekli köprünüz farklı portta çalışıyorsa doğru dinleyiciyi belirtin; port numarası tek başına native desteğinin kanıtı değildir.

## Wire ile native karşılaştırması

| Konu | `connect()` | `connectNative()` |
| --- | --- | --- |
| Parametre | `:id` ve nesne | `?` ve dizi |
| Varsayılan commit | Manuel | Autocommit |
| Sonuç | Pull tabanlı `Result` | `sets[].rows` |
| Etkilenen satır | `affectedRows` number | `sets[].affectedRows` BigInt |
| Kurtarma kimliği | Wire receipt `requestToken` | Native hata/AI `runId` bilgisi |
| Otomatik tekrar | Dar kapsamlı okuma seçeneği | Native SQL tekrarlanmaz |

`maxRows` 1–10.000 aralığındadır; varsayılanı 1000'dir. Bu bir sayfalama cursor'ı değildir. Büyük veriyi mantıklı sorgu aralıklarına bölün ve bütün satırların alındığını varsaymayın. Sonuçlar Server sınırları içinde parçalara bölünerek taşınabilir; SDK parça sırasını ve SHA-256 bütünlüğünü doğrulayıp birleştirir. Native `execute()` tek statement gönderir. Bir procedure gövdesi tek statement olabilir, fakat istemci `DELIMITER` komutu SQL metnine eklenmez.

## AI konuşması

Aşağıdaki parçayı yukarıdaki bağlantının `try` bloğunda, bağlantı kapanmadan çalıştırın.

Önkoşullar: desteklenen native Server, yapılandırılmış AI worker, erişilebilir model ve mevcut `app.assistant` konuşması. Sağlayıcı anahtarı SDK koduna eklenmez; worker'ın sahipliğine bağlı kimlik deposunda tutulur.

```js
await db.execute('START AI CONVERSATION app.assistant');
await db.execute('APPEND PROMPT ?', [
  'İzinli bağlamı kullanarak stok durumunu açıkla.',
]);
await db.execute(
  'APPEND RESPONSE INTO @answer AS JSON RETURNING METADATA INTO @meta',
);
await db.commit({ waitTimeoutMs: 20000 });
const response = await db.execute('SELECT @answer, @meta');
const [answer, metadata] = response.sets[0].rows[0];
console.log(answer.text);
console.log(metadata.text);
```

`answer` ve `metadata` JSON olduğunda `NativeJson` değerleridir. Özgün sayısal basamakları korumak için `.text` kullanılabilir. Model erişimi OpenAI, Claude veya yapılandırılmış yerel GGUF modeline dayanabilir; bağlanan SDK modeli kendisi indirmez veya sağlayıcı kimliğini kendiliğinden oluşturmaz.

## Asenkron çalışma ve hata kurtarma

`commit({asynchronous: true})` kalıcı çalışmanın metaverisini döndürür. Dönen metaverideki gerçek run kimliğini uygulamanız saklamalıdır. Daha sonra `fetchResponse(runId)` sonucu sorgular, `cancelRun(runId)` iptal talebi gönderir. `asynchronous: true` ile `waitTimeoutMs` birlikte kullanılamaz. Bekleme süresi bağlantının süre sınırının içine sığmalıdır; Node uygulaması bu farkı doğrular.

Native hata `commitState: 'committed'` ve `runId` taşıyorsa iş SQL'ini yeniden göndermek çift işlem oluşturabilir. Aynı run'ı sorgulayın. `actionCommitState` varsa AI turunun commit durumuyla araç eyleminin commit durumunu ayrı değerlendirin. Ağ sonucu belirsiz native işlemde genel bir wire CRUD receipt token'ı bulunduğunu varsaymayın. Native API otomatik reconnect/replay yapmaz; belirsizliği iş anahtarı veya run durumu üzerinden çözmeniz gerekir.

Yeni native SQL HIST/SQLgit ve SQL JOB bu sürümde ertelenmiştir. Native AI'nin iç işi ile wire compute/jobs API'si ayrı kapsamları temsil eder.

## Kaynaklar

- [Native bağlantı, sonuç ve commit API](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/src/native.mjs)
- [Native hata testleri](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/tests/native.test.mjs)
- [Native AI örneği ve sürüm kapsamı](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/README.md)
- [Hata alanları](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/src/errors.mjs)
