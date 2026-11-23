---
title: "Python: bağlantı, TLS ve cursor yaşam döngüsü"
slug: "/sdk/python/02-baglanti"
---

# Python: bağlantı, TLS ve cursor yaşam döngüsü

> **Kapsam:** SDK 0.3.0 · `connect()` · Wire v1. Native bağlantı için [native SQL/AI](07-native-ai.md) bölümüne bakın.

Python DB-API bağlantısı, kimliği doğrulanmış bir Server oturumunu temsil eder. Cursor ise bu oturum üzerinde statement çalıştırır ve sonuçları okur. Aynı bağlantıdan birden fazla cursor nesnesi oluşturulabilse de bir anda yalnızca tek etkin sonuç tutulabilir. Bu nedenle cursor nesnesi sayısını paralel sorgu kapasitesiyle karıştırmamak gerekir.

## Bağlantı seçenekleri

| Seçenek | Varsayılan | Açıklama |
| --- | --- | --- |
| `host` | `127.0.0.1` | Bağlantının gideceği adres |
| `port` | `7443` | Wire v1 TLS portu |
| `user`, `password` | Zorunlu | Server kullanıcı bilgileri |
| `ca_file` | `None` | CA PEM dosyası; verilmezse platform güven yapılandırması |
| `tls_name` | `None` | Ayrı TLS adı; verilmezse bağlantı adresinin kimliği |
| `timeout` | `15` | Saniye; pozitif ve en çok 300 |
| `autocommit` | `False` | Varsayılan manuel transaction |
| `retry_reads` | `False` | Sınırlı, güvenli autocommit okuma tekrarı |

Node.js'teki `timeoutMs` ile Python'daki `timeout` aynı birimde değildir. Python'da `timeout=15`, on beş saniyedir. Native SQL örneklerinin 75 saniyelik varsayılanı ise normal wire bağlantısının 15 saniyelik varsayılanından farklıdır. İstemcinin bekleme süresi işin gerçekten commit olup olmadığı hakkında tek başına karar vermez.

## Tek noktadan bağlantı oluşturma

```python
# db.py — uygulamaya ait yardımcı
import os
from stardataparadise_sdk import connect


def open_database(*, autocommit=False):
    return connect(
        host=os.environ.get("SDP_HOST", "127.0.0.1"),
        port=int(os.environ.get("SDP_PORT", "7443")),
        user=os.environ["SDP_USER"],
        password=os.environ["SDP_PASSWORD"],
        ca_file=os.environ["SDP_CA"],
        tls_name=os.environ.get("SDP_TLS_NAME", "localhost"),
        timeout=15,
        autocommit=autocommit,
    )
```

Bu dosya SDK'nın kendiliğinden okuduğu bir konfigürasyon değildir. Ortam değişkenlerini uygulama okur ve API'ye açık argümanlar verir. Sertifikanız `localhost` için üretilmemişse doğru adı sağlayın. `host` yönlendirme adresidir; `tls_name` ise sertifika doğrulamasındaki kimliktir. Yanlış ad hatasını TLS kontrolünü kapatarak geçiştirmek yerine sertifika ve bağlantı ayarlarını eşleştirin.

## Sonuçları ve bağlantıyı kapatın

```python
from db import open_database

with open_database(autocommit=True) as db:
    print(db.capabilities())
    with db.cursor() as cursor:
        cursor.execute("SELECT id, ad FROM public.urunler ORDER BY id")
        print(cursor.fetchmany(20))
    print(db.health())
```

Cursor bağlamından çıkıldığında kalan sonuç bırakılır. `health()` çağrısının bunun ardından gelmesi önemlidir; açık sonucu başka bir yönetim çağrısıyla aynı anda yürütmeyin. Çok uzun sonuçları okuyacağınızda cursor'ı gereksiz yere açık tutan kullanıcı arayüzü beklemelerini transaction içine taşımayın. Veriyi yeterli gruplarla işleyin, iş bittikten sonra bağlantıyı serbest bırakın.

`close()` manuel transaction içindeki henüz commit edilmemiş yazmaları geri alır. Bağlantı bağlamı başarılı çıkışta commit eder; açık bir bağlantıyı sadece `close()` ile bitirmek ise “başarıda commit” anlamına gelmez. Özellikle kütüphane kodunda hangi katmanın transaction sahibi olduğunu açıkça kararlaştırın. Yardımcı fonksiyon başka bir katmanın bağlantısını aldıysa kendiliğinden commit etmesi tüm iş akışını parçalara bölebilir.

## İş parçacıkları ve yeniden bağlanma

Paket `threadsafety = 1` bildirir. Bağımsız worker thread'ler için ayrı bağlantılar kullanın. SDK'da hazır bir istemci bağlantı havuzu yoktur; dışarıdan havuz yönetimi eklerseniz açık transaction veya sonuç taşıyan bağlantıyı başka işe vermeyin. Havuz büyüklüğünü Server'ın bağlantı sınırına göre belirlemek uygulama sorumluluğudur.

`reconnect()` yeni session açar ve eski session nesnelerini kurtarma garantisi vermez. Normal bağlantı açık transaction veya sonuç taşırken buna izin verilmez. `cancel()`, aktif isteğe ayrı kontrol bağlantısıyla iptal talebi gönderir; sorgu beklerken ayrı bir kontrol akışından çağrılır. İptal ve tekrar deneme, commit sonucu belirsizliğiyle aynı şey değildir. Belirsiz yazmada receipt sorgulama yolunu [transaction bölümünden](05-transaction.md) izleyin.

## Kaynaklar

- [Connection yaşam döngüsü](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/src/stardataparadise_sdk/_dbapi.py)
- [connect varsayılanları ve threadsafety](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/src/stardataparadise_sdk/__init__.py)
- [DB-API davranış özeti](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/BUILD.md)
- [TLS ve kimlik doğrulaması](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/src/stardataparadise_sdk/_wire.py)
