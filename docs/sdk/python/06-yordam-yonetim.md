---
title: "Python: yordamlar, çoklu sonuçlar ve yönetim çağrıları"
slug: "/sdk/python/06-yordam-yonetim"
---

# Python: yordamlar, çoklu sonuçlar ve yönetim çağrıları

> **Kapsam:** SDK 0.3.0 · Wire v1. Sunucu özelliği, mevcut nesne ve kullanıcı yetkisi birlikte gerekir.

DB-API cursor, normal SELECT dışında sunucuda tanımlı yordamları da çağırabilir. Yordam iş kurallarını bir sunucu biriminde toplar; Python kodu giriş parametrelerini yollar ve OUT değerlerini veya üretilen sonuç kümelerini okur. Hangi parametrenin IN, OUT ya da IN OUT olduğunu yordam tanımı belirler. SDK bu tanım yerine otomatik bir iş kuralı oluşturmaz.

## `callproc()` ve OUT satırı

Aşağıdaki `sdk_list` adı SDK kabul fixture'ında bulunan örnek yordamdır. Kendi sunucunuzda aynı yordam yoksa kendi yordamınızın gerçek adı ve imzasını kullanın.

```python
from db import open_database

with open_database() as db:
    with db.cursor() as cursor:
        original_parameters = cursor.callproc("sdk_list", (101, None))
        out_row = cursor.fetchone()
        print("OUT satırı:", out_row)
        while cursor.nextset():
            print("Küme:", cursor.set_name)
            for row in cursor:
                print(row)
```

Bu sağlayıcının `callproc()` dönüş değeri verilen parametre dizisidir; OUT değerlerini o dizinin kendiliğinden değişmesiyle aramayın. OUT satırı cursor'dan okunur, ardından `nextset()` ile sonraki kümelere geçilir. Saf OUT argümanındaki `None` çağrıda literal NULL yer tutucusu olur. Nullable IN parametresi gerekiyorsa doğru tipte `Bind(None, ...)` kullanın.

Aynı çağrı açık SQL ile de yazılabilir:

```python
cursor.execute("CALL sdk_list(:anahtar, NULL)", {"anahtar": 101})
```

`callproc` yordam adının normal, gerekirse nitelikli identifier olduğunu doğrular. Yordam adı olarak SQL parçası göndermeyin. Hangi yordamların çağrılabileceğini uygulama tasarımında açıkça sınırlandırmak ve Server yetkilerini buna göre vermek gerekir.

## İç içe parametreler

```python
from stardataparadise_sdk import Record, Collection

kayit = Record((("urun_id", 101), ("aciklama", "Örnek")))
liste = Collection((kayit, None, 3))
```

Bu değerler RECORD ve COLLECTION kabul eden mevcut yordam argümanlarına bağlanır. `dict` veya `list` kullanmak kendiliğinden doğru SQL tipini bildirmez. Tipli sarmalayıcılar iç içe üyelerin anlamını ve sırayı korur. Yordam SQL tipi farklıysa parametreyi rastgele JSON metnine çevirerek hatayı gizlemek yerine sözleşmeyi düzeltin.

## Yönetim ve tanılama

```python
with open_database(autocommit=True) as db:
    print(db.capabilities())
    print(db.health())
    print(db.metadata())
    print(db.history("public.urunler", limit=20))
```

Bu çağrılar açık cursor sonucu yokken çalıştırılmalıdır. `capabilities()` ilan edilen özellikleri döndürür; izin kontrolünün yerine geçmez. Bir özellik desteklense bile kullanıcı gerekli nesneye erişemeyebilir. Uygulamanın yönetim ekranında desteklenmeyen işlemleri gizlemek kullanılabilirliği iyileştirir; yetkilendirmenin son kararı Server'dadır.

| Metot | Kullanım | Gerekli bağlam |
| --- | --- | --- |
| `history(target, limit=...)` | Wire History kayıtlarını incelemek | Hedef tablo ve izin |
| `validate_decision(sql)` | Decision kuralını doğrulatmak | İlgili özellik ve yetki |
| `predict(name, features)` | Aktif modelden tahmin almak | Gerçek model ve özellik sözlüğü |
| `dataset(dataset_id)` | Dataset durumunu okumak | Mevcut dataset |
| `submit_compute(count)` | Compute işi oluşturmak | Jobs desteği ve izin |
| `job(job_id)` | İş durumunu okumak | Yetkili iş kimliği |
| `cancel_job(job_id)` | İptal istemek | Çalışmanın iptal edilebilir durumu |
| `administration_health()` | Yönetici sağlık bilgisi | Yönetici yetkisi |

```python
with open_database(autocommit=True) as db:
    submitted = db.submit_compute(100)
    state = db.job(submitted["job_id"])
    print(state)
```

İş kimliğinin dönmesi tamamlanma sinyali değildir. Uygulamanız terminal durumu okuyana kadar işi devam ediyor olarak ele almalıdır. Kısa aralıklarla sınırsız polling döngüsü kurmak yerine kontrol sıklığı ve süre bütçesi belirleyin. İptal isteği, işin önceki kalıcı etkilerini otomatik geri alma garantisi sağlamaz; son durumu tekrar okuyun.

## Özellik adlarının kapsamı

Buradaki wire `history()`, `submit_compute()` ve `job()` metotları yeni native SQL HIST/SQLgit ve SQL JOB zamanlama komutlarıyla aynı şey değildir. İncelenen sürümde yeni native komutlar ertelenmiştir. AI worker'ın kendi iç kuyruğu da genel SQL job zamanlayıcısı olarak sunulmaz. Native AI konuşmaları için bir sonraki bölümde ayrı `connect_native()` oturumu açacağız.

## Kaynaklar

- [callproc, nextset ve yönetim metotları](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/src/stardataparadise_sdk/_dbapi.py)
- [Yordam ve yönetim örnekleri](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/BUILD.md)
- [Kabul testi yordam sözleşmeleri](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/tests/test_contract.py)
- [Sürüm kapsamı](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/README.md)
