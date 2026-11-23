---
title: "Python: transaction ve belirsiz commit sonucunu çözme"
slug: "/sdk/python/05-transaction"
---

# Python: transaction ve belirsiz commit sonucunu çözme

> **Kapsam:** SDK 0.3.0 · Wire v1 · `connect()` / DB-API. Native API'nin commit ve kurtarma sözleşmesi ayrıdır.

Varsayılan bağlantı manuel commit kipindedir. Transaction ilk statement gerektiğinde başlar; bu Python wire API'sinde ayrıca public `begin()` veya `savepoint()` metodu bulunmaz. Transaction sınırını `commit()`, `rollback()` ve bağlantı bağlamı belirler. Bu nedenle başka bir dilin SDK örneğindeki metot adlarını Python'a yalnızca küçük harfle çevirerek kullanmayın.

`with connect(...) as db` başarılı çıkışta commit eder ve ardından bağlantıyı kapatır. İçeriden exception çıkarsa açık transaction kapanırken geri alınır. Yalnızca `db.close()` çağırmak başarıda commit etmez. İş fonksiyonlarınızın bir bölümü `with` kullanıp başka bölümü bağlantıyı elle yönetiyorsa bu farkı açıkça belgeleyin.

## Birden fazla statement'ı tek iş olarak çalıştırma

```python
from db import open_database

with open_database() as db:
    with db.cursor() as cursor:
        cursor.execute(
            """UPDATE public.urunler SET stok = stok - :adet
               WHERE id = :id AND stok >= :adet""",
            {"id": 101, "adet": 2},
        )
        if cursor.rowcount != 1:
            raise ValueError("Ürün yok veya yeterli stok bulunmuyor")
        # Aynı iş için sipariş/kalem INSERT'leri bu noktaya eklenebilir.
```

Örnek `adet` değerinin pozitif olduğunu varsayar; gerçek uygulamada bunu SQL'den önce doğrulayın. Statement koşulu kontrolü değişiklikle birlikte yapar. Ayrı SELECT ile stok okuyup sonra koşulsuz UPDATE yapmak eşzamanlı değişikliklerde eski bilgiye dayanabilir. Eklenecek sipariş INSERT'lerinin de aynı transaction içinde olması, işin bir kısmının kalıcı olup diğer kısmının başarısız kalmasını önler.

## Exception'ı yanlış yerde yutmayın

Bir `with db` bloğunda hata yakalanıp dışarı çıkarılmazsa bağlam yöneticisi normal çıkış görür ve kalan transaction'ı commit edebilir. İşin bütünü başarısız sayılmalıysa exception'ı yeniden yükseltin veya bilinçli şekilde `rollback()` çağırın. Hata mesajını günlüğe yazıp hiçbir karar vermeden devam etmek transaction politikası değildir.

`executemany()` mevcut transaction içinde kendi savepoint'ini kullanır. Bu toplu işlemin geri alınması daha önce yapılmış her değişikliğin otomatik geri alındığı anlamına gelmez. İş gereksinimine göre dış transaction'ı da bitirin. Bu ayrıntı özellikle bir CSV içe aktarma sırasında bazı gruplar başarılı, sonraki grup başarısız olduğunda önem kazanır.

## Commit cevabı gelmezse

Server commit'i kalıcı hale getirmiş, ancak bağlantı yanıt gelmeden kopmuş olabilir. `OutcomeUnknown` içindeki `request_token` bu wire işleminin sorgulanmasını sağlar. Aynı yazmayı hemen tekrar çalıştırmayın.

```python
from stardataparadise_sdk import OutcomeUnknown
from db import open_database


def commit_and_inspect(db):
    try:
        db.commit()
        return {"status": "committed"}
    except OutcomeUnknown as error:
        if not error.request_token:
            raise
        with open_database(autocommit=True) as recovery:
            receipt = recovery.outcome(error.request_token)
        return {"request_token": error.request_token, "receipt": receipt}
```

Bu yardımcı yalnızca commit ve durum sorgusunu yapar; iş SQL'ini yeniden göndermediğine dikkat edin. Kurtarma aynı yetkili kullanıcı kimliğiyle aynı Server'a bağlanmalıdır. Receipt `status == 'committed'` diyorsa kalıcı sonuç doğrulanmıştır. `unknown` sonucu kesin başarısızlık değildir; belirsizlik devam eder. Token'ı uygulamanın iş kaydıyla ilişkilendirmek ve durumu tekrar araştırabilmek gerekir.

İsterseniz `db.commit(request_token=...)` ile 32 küçük harf hexadecimal karakterden oluşan token'ı uygulama üretebilir. Ancak aynı token'ı bağımsız farklı işler için tekrar kullanmayın. Token yalnızca bu wire kalıcılık sözleşmesinin kimliğidir; bütün uygulama işlerinin otomatik idempotent hale geldiğini garanti etmez.

## Retry ve tanılama

SDK yazmaları otomatik tekrar etmez. `retry_reads=True`, autocommit okumanın sonucu henüz dönmeden yaşanan belirli transport kopmalarında tek yeniden denemeye izin verir. Kırılmış cursor'ın daha önce teslim edilmiş satırlarını yeniden başlatmaz. İstemci süre aşımını her zaman “iş hiç yapılmadı” diye yorumlamak çift yazma üretebilir.

Hata sınıfları DB-API hiyerarşisini kullanır: `ProgrammingError`, `DataError`, `IntegrityError`, `OperationalError`, `NotSupportedError` ve diğerleri. Tanılamada `code`, `sqlstate`, `correlation_id`, `line`, `column` ve varsa `request_token` alanlarını okuyun. Tam SQL parametrelerini ve parolaları günlüğe dökmeden operasyonu bulabilecek bir uygulama iş kimliği kullanın.

## Kaynaklar

- [Connection transaction ve context manager kodu](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/src/stardataparadise_sdk/_dbapi.py)
- [OutcomeUnknown ve hata sınıfları](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/src/stardataparadise_sdk/_errors.py)
- [Commit onayı kaybı ve retry testleri](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/tests/test_contract.py)
