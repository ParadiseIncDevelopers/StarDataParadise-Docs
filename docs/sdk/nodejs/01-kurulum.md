---
title: "Node.js SDK: kurulum ve ilk sorgu"
slug: "/sdk/nodejs/01-kurulum"
---

# Node.js SDK: kurulum ve ilk sorgu

> **Kapsam:** `stardataparadise` 0.2.0 · Node.js 22 ve üzeri · Wire v1. Kaynak incelemesi: 23 Kasım 2026.

Node.js SDK, JavaScript uygulamanızdan StarDataParadise Server'a bağlanmanızı sağlar. Uygulama SQL metnini ve parametrelerini SDK'ya verir; SDK kimlik doğrulama, TLS bağlantısı, tip dönüşümü, sorgu sonucu ve transaction çağrılarını yürütür. Verinin saklanması, sorgunun yetkilendirilmesi ve kalıcı commit kararı Server'ın sorumluluğundadır. Bu ayrım nedeniyle paketi kurmak tek başına çalışan bir veritabanı oluşturmaz: erişilebilir bir Server, kullanıcı hesabı ve ilgili tabloların önceden hazırlanması gerekir. Bu rehberin `public` tabloları orijinal motorun `sql_crud_v1` kapsamındaki SQL laboratuvarına aittir. `wire_sql_basic_v1` sunan köprünün aynı DDL kapsamını sunduğu varsayılmaz; native laboratuvar ayrı kurulur.

Paket ESM kullanır ve çalışma zamanında Node.js'in yerleşik modüllerine dayanır. Bir ORM değildir; tabloları sınıflardan otomatik üretme veya migration yönetimi bu sayfada anlatılan API'nin parçası değildir. Önce SQL ile veri modelini kurun, sonra aynı SQL'i uygulamanın veri erişim katmanına taşıyın. Her HTTP isteği için ayrı bağlantı açmak basit bir başlangıç olabilir; üretimde eşzamanlılık, bağlantı sayısı ve yaşam döngüsü uygulama tarafından tasarlanmalıdır.

## 1. Paketi projeye ekleyin

Depo README'sinde belirtilen sürüm sabitleme komutu:

```powershell
node --version
npm install stardataparadise@0.2.0
```

Bu doküman npm yayın durumunu ayrıca sınamaz. Elinizde sürüm arşivi varsa yerel paketi kurabilirsiniz:

```powershell
npm install C:/SDP/packages/stardataparadise-0.2.0.tgz
```

Dosyayı `ilk-sorgu.mjs` adıyla kaydedin. `.js` uzantısı kullanacaksanız uygulamanın `package.json` dosyasında `"type": "module"` bulunmalıdır. `require()` örneklerini ESM dosyasına karıştırmayın; bu rehberdeki tüm import'lar `import ... from 'stardataparadise'` biçimindedir.

## 2. Bağlantı bilgilerini sağlayın

Örnekler `SDP_USER`, `SDP_PASSWORD`, `SDP_CA` ortam değişkenlerini okur. `SDP_CA`, sunucu sertifikasını imzalayan CA'nın PEM dosyasına işaret eder. Parolayı kaynak dosyasına veya sürüm kontrolüne yazmayın. Aşağıdaki örnek mevcut `public.urunler` tablosuna SELECT yetkisi olduğunu varsayar; tabloyu kitabın SQL laboratuvarında oluşturabilirsiniz.

```js
import { connect } from 'stardataparadise';

const db = await connect({
  host: '127.0.0.1',
  port: 7443,
  tlsName: 'localhost',
  caFile: process.env.SDP_CA,
  user: process.env.SDP_USER,
  password: process.env.SDP_PASSWORD,
  autocommit: true,
});

try {
  console.log('Server:', db.serverVersion);
  const result = await db.execute(
    'SELECT id, ad, stok FROM public.urunler WHERE id >= :ilk ORDER BY id',
    { ilk: 1n },
  );
  try {
    for await (const [id, ad, stok] of result) {
      console.log(id.toString(), ad, stok.toString());
    }
  } finally {
    await result.close();
  }
} finally {
  await db.close();
}
```

```powershell
node .\ilk-sorgu.mjs
```

Örnekte `autocommit: true` yalnızca bağımsız bir okuma yapıldığı için açıkça seçilmiştir. SDK'nın varsayılanı manuel commit'tir. Yazma işlemlerine geçtiğinizde başarılı `execute()` çağrısının tek başına değişiklikleri kalıcı yaptığı varsayımında bulunmayın. Transaction bölümü bu farkı adım adım açıklar.

## 3. Çıktıyı yorumlayın

`id` ve `stok` SQL `BIGINT` olduğu için JavaScript tarafında `BigInt` gelir. `1n` sözdizimi aynı tipte bir parametre üretir. Sorgu sonucunun boş olması bağlantının başarısız olduğu anlamına gelmez; tablonun veya filtrenin satır döndürmediğini gösterir. Kimlik doğrulama, yetki ve SQL hataları ise exception ile bildirilir.

`try/finally` blokları iki farklı kaynağı kapatır: iç blok Server'daki sonuç ve hazırlanmış statement yaşam döngüsünü, dış blok bağlantıyı bitirir. Örneği kısaltmak için bu blokları kaldırmayın; başka bir sorguya geçmeden önce etkin sonucu tüketmek ya da kapatmak gerekir.

## Sonraki adım

[Bağlantı ve TLS](02-baglanti.md) bölümünde seçenekleri okuyun; ardından [CRUD ve sonuç işleme](03-crud.md) ile aynı tabloya parametreli INSERT, UPDATE ve DELETE uygulayın. Native SQL/AI için gereken `connectNative()` ayrı bir oturum türüdür; ilk örnekteki `connect()` nesnesini sonradan native bağlantıya dönüştürmezsiniz.

## Kaynaklar

- [SDK README ve kurulum](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/README.md)
- [Genel dışa aktarımlar](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/src/index.mjs)
- [Bağlantı ve execute uygulaması](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/src/provider.mjs)
