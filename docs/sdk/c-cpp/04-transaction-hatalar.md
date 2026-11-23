---
title: "C/C++ SDK — Transaction ve belirsiz sonuç"
slug: "/sdk/c-cpp/04-transaction-hatalar"
---

# C/C++ SDK — Transaction ve belirsiz sonuç

**Kapsam:** Wire v1 transaction ve request token sözleşmesi.

Birden fazla yazmayı tek iş olarak yapmak için `sdp_tx_begin`, `sdp_tx_commit` ve `sdp_tx_rollback` kullanılır. C++ `Transaction` sınıfı bu çağrıları sahiplik nesnesiyle sarar. Başarılı bir INSERT yanıtı, açık transaction'ın commit edildiği anlamına gelmez.

## C++ işlem örneği

```cpp
sdp::client::Transaction transaction(connection);
{
    sdp::client::Statement insert(
        connection,
        "INSERT INTO main.public.musteriler (id, ad, eposta) VALUES (:id, :ad, :eposta)",
        R"({"id":{"type":"BIGINT"},"ad":{"type":"TEXT"},"eposta":{"type":"TEXT"}})"
    );
    auto answer = insert.execute(
        R"({"id":{"t":"i64","v":"9001"},"ad":{"t":"text","v":"SDK Deneme"},"eposta":{"t":"text","v":"demo@example.invalid"}})"
    );
    std::cout << answer.view() << '\n';
}
transaction.rollback();
```

Bu deneme kasıtlı olarak rollback ile biter; müşteri 9001 kalıcılaşmaz. Aynı kodun tam tüketici hali [main.cpp](/downloads/ornekler/cpp/main.cpp) içindedir. Kalıcı iş için rollback yerine `transaction.commit(token)` çağrılır. Token uygulamada üretilmiş 32 küçük harfli hex karakterden oluşmalıdır; belgede gösterilen sabit bir token'ı bütün isteklerde tekrar kullanmayın.

## Savepoint kullanımı

C API'de `sdp_tx_savepoint`, `sdp_tx_rollback_to` ve `sdp_tx_release` bulunur. Ad 1–64 ASCII harf, rakam veya alt çizgiden oluşur. Bir siparişe ek hizmet eklemek gibi isteğe bağlı alt adımda savepoint işin ilk kısmını koruyup alt adımı geri almak için kullanılabilir. İşlemin tamamını etkileyen stok/ödeme kuralı hatasını savepoint ile örtmeyin; bu durumda tüm transaction geri alınmalıdır.

## Başarısızlıkları ayırın

| Durum | Uygulama davranışı |
| --- | --- |
| SQL/constraint hatası, bağlantı sağlıklı | İş kuralına göre rollback; girdiyi veya sıralamayı düzeltme |
| Açılmadan önce TLS/auth hatası | Bağlantı ayarını düzeltme; yazma yürütülmemiştir |
| Token taşıyan yazma gönderildikten sonra kopma | `unknown_outcome` değerlendirme; sonucu sorgulama |
| `outcome = committed` | Makbuzdaki LSN ile kalıcı sonucu kaydetme |
| `outcome = unknown` | Sonucu belirsiz tutma; başarısız/rollback diye etiketlememe |

C++ hatasında `error.status()`, `error.details()` ve `error.unknown_outcome()` alanları vardır. Commit isteği belirsiz sonuçla dönerse `Transaction` sınıfı bunu normal bir “scope sonunda kesin rollback yapılır” durumu gibi ele almaz. Sunucu commit etmiş olabilir; destructor'ın çalışmış olması bu olasılığı ortadan kaldırmaz.

## Sonucu yeni bağlantıdan sorgulayın

```cpp
auto receipt = recovery_connection.outcome(saved_request_token);
std::cout << receipt.view() << '\n';
```

Bu kesitte `recovery_connection`, aynı doğrulanmış kullanıcıyla yeni açılmış bağlantıdır. `saved_request_token` ilk yazma/commit isteğine ait gerçek tokendır. Token'ı hata logunda diğer gerekli teşhis bilgileriyle koruyabilirsiniz; parolayı veya tüm hassas SQL parametrelerini aynı loga eklemeyin.

`unknown`, kayıt bulunmaması veya saklama penceresi dışında kalma gibi nedenlerle sonucu çözemediğinizi gösterir. Aynı işin tekrar çalıştırılmasını uygulama düzeyindeki benzersiz işlem anahtarı ve kalıcı iş kaydıyla ele alın. Network timeout'u nedeniyle siparişi ikinci kez oluşturmaya karar veren genel bir retry katmanı yazmayın.

## Kaynaklar

- [StarDataParadiseDLLler / ABI.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseDLLler/blob/3199235c9641733332e9b8c82f9e875170c4eedb/ABI.md)
- [StarDataParadiseDLLler / include/StarDataParadiseDLLler.hpp](https://github.com/ParadiseIncDevelopers/StarDataParadiseDLLler/blob/3199235c9641733332e9b8c82f9e875170c4eedb/include/StarDataParadiseDLLler.hpp)
