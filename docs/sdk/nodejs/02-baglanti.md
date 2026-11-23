---
title: "Node.js: bağlantı, TLS ve kaynak yaşam döngüsü"
slug: "/sdk/nodejs/02-baglanti"
---

# Node.js: bağlantı, TLS ve kaynak yaşam döngüsü

> **Kapsam:** SDK 0.2.0 · `connect()` · Wire v1. Native bağlantı farkları [ayrı bölümde](07-native-ai.md) açıklanır.

Bir bağlantı, tek bir kimlikle açılmış Server oturumudur. Bağlantının açık olması her tabloyu okuyabileceğiniz veya her yönetim işlemini yapabileceğiniz anlamına gelmez; Server her işlem için izinleri uygular. Uygulama başlangıcında bağlantıyı test etmek, bir sorgunun başarısını değerlendirmek ve oturumu kapatmak ayrı sorumluluklardır.

## Bağlantı seçenekleri

| Seçenek | Varsayılan | Anlamı |
| --- | --- | --- |
| `host` | `127.0.0.1` | TCP bağlantısının gideceği adres |
| `port` | `7443` | Wire v1 TLS dinleyicisinin portu |
| `user`, `password` | Zorunlu | Server kullanıcı bilgileri |
| `caFile` | Verilmezse Node güven deposu | Güvenilecek CA PEM dosyası veya dosya URL'si |
| `tlsName` | `host` | Sertifikada doğrulanacak sunucu adı |
| `timeoutMs` | `5000` | Bağlantı ve wire isteği süre sınırı; 100–120.000 ms |
| `autocommit` | `false` | Açık transaction yokken bağımsız işlemlerin commit davranışı |
| `retryReads` | `false` | Güvenli autocommit okuma hazırlığında sınırlı tekrar |

`host` ve `tlsName` aynı şeyi ifade etmez. Örneğin bağlantı `127.0.0.1` adresine giderken sertifika `localhost` adına verilmiş olabilir. Bu durumda `host: '127.0.0.1', tlsName: 'localhost'` kullanılır. Gerçek sunucunuzun sertifikası başka bir ad taşıyorsa `localhost` metnini aynen kopyalamayın. CA dosyası sertifika zincirine güven sağlar; TLS adı ise doğru sunucuya bağlandığınızı doğrular. Her iki kontrol de gereklidir.

## Ortak bağlantı fabrikası

Aşağıdaki dosya uygulamaya ait bir yardımcıdır; SDK'nın yerleşik bağlantı havuzu değildir. Farklı sayfalardaki örneklerde seçeneklerin tekrar edilmesini önler.

```js
// db.mjs
import { connect } from 'stardataparadise';

function required(name) {
  const value = process.env[name];
  if (!value) throw new Error(`${name} tanımlanmalı`);
  return value;
}

export function openDatabase({ autocommit = false } = {}) {
  return connect({
    host: process.env.SDP_HOST ?? '127.0.0.1',
    port: Number(process.env.SDP_PORT ?? '7443'),
    tlsName: process.env.SDP_TLS_NAME ?? 'localhost',
    caFile: required('SDP_CA'),
    user: required('SDP_USER'),
    password: required('SDP_PASSWORD'),
    timeoutMs: 15000,
    autocommit,
  });
}
```

`SDP_PORT` uygulamanın kendi konfigürasyon seçimidir; SDK ortam değişkenlerini otomatik okumaz. Bu yardımcı onları okuyup gerçek API seçeneklerine dönüştürür. Hatalı bir portu sessizce varsayılana çevirmek yerine doğrulama hatasının görünür olmasına izin verin.

## Bir bağlantıda tek etkin işlem

`connect()` ile açılan bağlantı bir anda tek işlem ve tek etkin sonuç taşır. Aynı `db` nesnesinde `Promise.all([db.execute(...), db.execute(...)])` çalıştırmak paralel sorgu desteği oluşturmaz. İkinci işlem meşgul bağlantı hatası alabilir. Bağımsız işleri eşzamanlı çalıştırmanız gerekiyorsa ayrı bağlantılar kullanın ve toplam bağlantı sayısını Server kapasitesiyle sınırlandırın.

```js
import { openDatabase } from './db.mjs';

const db = await openDatabase({ autocommit: true });
try {
  const features = await db.capabilities();
  console.log(features);
  const result = await db.execute('SELECT id, ad FROM public.urunler');
  try {
    console.log(await result.fetchMany(50));
  } finally {
    await result.close();
  }
  console.log(await db.health());
} finally {
  await db.close();
}
```

Yönetim çağrısının sonuç kapatıldıktan sonra yapılması bilinçli bir sıralamadır. Aktif cursor varken `capabilities()`, `health()` veya başka sorgu başlatmayın.

## Kapatma, iptal ve yeniden bağlanma

`close()` açık transaction'ı geri alır ve oturumu kapatır. Yazmayı saklamak istiyorsanız önce `commit()` gerekir. `reconnect()` yeni oturum açar; mevcut transaction veya açık sonuç varken bunu oturum tamiri gibi kullanamazsınız. Başarılı bağlantı kurulması eski session nesnelerinin korunması anlamına gelmez.

`cancel()` devam eden wire isteğine aynı kimlikle ayrı kontrol bağlantısı üzerinden iptal gönderir. İptal talebinin kabul edilmesi, daha önce commit edilmiş bir işi geri alma işlemi değildir. Özellikle yazma ve commit hatalarında [sonuç kurtarma akışını](05-transaction.md) uygulayın. Süre aşımı yalnızca istemcinin ne kadar beklediğini belirler; iş sonucuna ilişkin kesin bir rollback kanıtı sayılmaz.

## Kaynaklar

- [Bağlantı seçenekleri, yaşam döngüsü ve yönetim](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/src/provider.mjs)
- [TLS kimlik ve CA doğrulaması](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/src/wire.mjs)
- [SDK README](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Node/blob/74a0d86416b89fdc6e9af395edee4576c745b5c0/README.md)
