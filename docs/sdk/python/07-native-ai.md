---
title: "Python: native SQL ve AI oturumları"
slug: "/sdk/python/07-native-ai"
---

# Python: native SQL ve AI oturumları

> **Kapsam:** SDK 0.3.0 · `connect_native()` · `native_sql_v1` destekleyen Server.

Native bağlantı aynı paket içinde ayrı bir API sunar. Normal DB-API `connect()` isimli parametreler ve cursor kullanırken, `connect_native()` SQL'i doğrudan `execute()` ile çalıştırır ve konumsal `?` parametreleri alır. Native oturum varsayılan olarak autocommit'tir. Açılışta Server'ın `native_sql_v1` capability'si kontrol edilir; desteklenmeyen bir oturuma geçiş sessizce yapılmaz.

## Native bağlantı ve sonuç yapısı

```python
import os
from stardataparadise_sdk import connect_native


def open_native():
    return connect_native(
        host=os.environ.get("SDP_HOST", "127.0.0.1"),
        port=int(os.environ.get("SDP_NATIVE_PORT", "7443")),
        user=os.environ["SDP_USER"],
        password=os.environ["SDP_PASSWORD"],
        ca_file=os.environ["SDP_CA"],
        tls_name=os.environ.get("SDP_TLS_NAME", "localhost"),
        timeout=75,
    )


db = open_native()
try:
    result = db.execute(
        "SELECT id, ad FROM sdp_lab.urunler WHERE id = ?",
        (101,),
        max_rows=100,
    )
    for row in result.sets[0].rows:
        print(row)
finally:
    db.close()
```

`sdp_lab.urunler` native/Classic laboratuvarında önceden oluşturulur. Orijinal motorun `main.public` tablosuyla aynı nesne olduğu varsayılmaz. `SDP_NATIVE_PORT` uygulamaya ait bir konfigürasyon ismidir; gerçek native destekli dinleyicinin portunu verin. `?` için tek elemanlı tuple yazarken `(101,)` sonundaki virgül önemlidir; `(101)` tek başına tuple değildir.

| Alan/API | Anlamı |
| --- | --- |
| `result.sets` | Sonuç kümeleri tuple'ı |
| `sets[i].columns` | Sütun metaverisi |
| `sets[i].rows` | Materyalize edilmiş satırlar |
| `sets[i].affected_rows` | Etkilenen satır sayısı |
| `sets[i].last_insert_id` | Sonuçta bildirilen ekleme kimliği |
| `result.in_transaction` | Server'ın işlem durumu |
| `result.autocommit` | Oturumun commit kipi |

Native `max_rows` varsayılan 1000, aralığı 1–10.000'dir. Bu bir sonsuz cursor değildir; büyük sonuçları tasarımda kontrollü sorgulara bölün. SDK büyük yanıtların parçalarını sınır ve SHA-256 kontrolüyle birleştirir. Tek `execute()` çağrısı tek SQL statement içindir; procedure gövdesi tek statement olarak gönderilebilir, istemci `DELIMITER` komutu gönderilmez.

## AI konuşmasını çalıştırma

Önce AI worker, erişilebilir model ve `app.assistant` konuşması sunucuda oluşturulmalıdır. Sağlayıcı anahtarı Python bağlantı seçeneklerine konmaz; worker tarafındaki sahipliğe bağlı kimlik deposunda tutulur.

```python
db = open_native()
try:
    db.execute("START AI CONVERSATION app.assistant")
    db.execute("APPEND PROMPT ?", ("İzinli bağlama göre stok durumunu açıkla.",))
    db.execute("APPEND RESPONSE INTO @answer AS JSON RETURNING METADATA INTO @meta")
    db.commit(wait_timeout_ms=20000)
    result = db.execute("SELECT @answer, @meta")
    answer, metadata = result.sets[0].rows[0]
    print(answer.decode())
    print(metadata.decode())
finally:
    db.close()
```

JSON sonuçları `NativeJson` ise `.decode()` Python `int` ve `Decimal` ile çözümleme yapar; `.text` orijinal metni korur. Örnekte native transaction/AI commit sınırını açık göstermek için `try/finally` kullanıldı. Native bağlantı DB-API sınıfından gelen context manager davranışını da taşır; `with` başarıda ayrıca commit çağırabileceği için bir AI akışındaki commit sayısını bilinçli tasarlayın.

## Asenkron çalışma ve kurtarma

`commit(asynchronous=True)` kalıcı run metaverisini döndürür. Uygulama dönen gerçek run kimliğini saklar, sonra `fetch_response(run_id)` ile sonucu veya `cancel_run(run_id)` ile iptal isteğini yönetir. `asynchronous=True` ile `wait_timeout_ms` birlikte verilmez. Bekleme süresi bağlantının timeout değerinden en az üç saniye kısa olmalıdır; örnekte 20 saniyelik bekleme 75 saniyelik bağlantı bütçesine sığar.

Bir hata `commit_state='committed'` ve `run_id` taşıyorsa önceki business SQL'i tekrar çalıştırmayın; aynı run'ı sorgulayın. `action_commit_state` araç işleminin, `commit_state` AI turunun farklı sonucunu gösterebilir. Transport sonucu belirsiz native yazmada eski wire `request_token` receipt akışının mevcut olduğu varsayılmaz. Native `reconnect()` otomatik kurtarma sağlamaz; API SQL statement'ını kendiliğinden yeniden göndermez.

OpenAI, Claude ve yerel GGUF kullanımı sunucudaki model/worker yapılandırmasına bağlıdır. Yeni native SQL HIST/SQLgit ve SQL JOB bu sürümde ertelenmiştir; wire History ve compute/jobs metotları ayrı kapsamda kalır.

## Kaynaklar

- [NativeConnection ve sonuç tipleri](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/src/stardataparadise_sdk/_native.py)
- [Native AI örneği](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/BUILD.md)
- [Native hata ve tür testleri](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/tests/test_native.py)
- [Hata metaverisi](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/src/stardataparadise_sdk/_errors.py)
