---
title: "Python: CRUD, cursor ve toplu işlemler"
slug: "/sdk/python/03-crud"
---

# Python: CRUD, cursor ve toplu işlemler

> **Kapsam:** SDK 0.3.0 · Wire v1 · orijinal SQL laboratuvarı. Örnekler [db.py](02-baglanti.md) yardımcısını kullanır.

Python wire API'de sorgu parametreleri isimlidir. SQL metninde `:id` kullanılır, değer `{"id": 101}` sözlüğüyle aktarılır. `%s`, Python f-string veya native `?` işaretleri bu bağlantının parametre sözleşmesi değildir. Değeri SQL'e ayrı göndermek hem tipin korunmasını hem de kullanıcı verisinin SQL yapısından ayrılmasını sağlar. Tablo ve sütun adları parametre değildir; değişken sıralama gerekiyorsa uygulamanın sabit izinli adlarından seçin.

## INSERT ve UPDATE

```python
from decimal import Decimal
from db import open_database

with open_database() as db:
    with db.cursor() as cursor:
        cursor.execute(
            """INSERT INTO public.urunler (id, ad, fiyat, stok)
               VALUES (:id, :ad, :fiyat, :stok)""",
            {"id": 9001, "ad": "Kulaklık", "fiyat": Decimal("1250.00"), "stok": 10},
        )
        print("Eklenen:", cursor.rowcount)
        cursor.execute(
            "UPDATE public.urunler SET stok = :stok WHERE id = :id",
            {"id": 9001, "stok": 14},
        )
        print("Güncellenen:", cursor.rowcount)
```

Dış `with` başarıyla bittiğinde iki statement aynı manuel transaction içinde commit edilir. `9001` örnek kimliktir; aynı INSERT tekrar çalıştırılırsa birincil anahtar çakışması beklenebilir. Örneğin idempotent olduğu varsayılmamalıdır. `rowcount` yazma statement'ında etkilenen satır sayısını verir; SELECT sonucunun toplam satır sayısını öğrenmek için bu alana güvenmeyin. Kaynak, sonuç kümesi varken başlangıçta `-1` kullanabilir.

## SELECT ve satır grupları

```python
with open_database(autocommit=True) as db:
    with db.cursor() as cursor:
        cursor.arraysize = 100
        cursor.execute(
            """SELECT id, ad, fiyat, stok FROM public.urunler
               WHERE stok >= :esik ORDER BY id""",
            {"esik": 1},
        )
        while rows := cursor.fetchmany():
            for urun_id, ad, fiyat, stok in rows:
                print(urun_id, ad, str(fiyat), stok)
```

`arraysize`, parametresiz `fetchmany()` için istenen satır sayısını belirler. Wire çekiminde SDK her ağ grubunu Server sınırına uygun biçimde en çok 1024 satırla sınırlar. `fetchmany(n)` daha büyük bir liste isteyebilir, fakat bu istek birden fazla ağ çekimi gerektirebilir. Bu nedenle “fetch boyutu” ile sorgunun toplam sonuç sınırı aynı kavram değildir.

| Cursor API | Kullanım |
| --- | --- |
| `fetchone()` | Bir satır tuple'ı; küme bittiğinde `None` |
| `fetchmany(n)` | En çok `n` satırlık liste |
| `fetchall()` | Mevcut kümenin kalan tüm satırları |
| `for row in cursor` | Sıralı satır tüketimi |
| `description` | Ad, SQL tipi, hassasiyet, ölçek gibi metaveri |
| `nextset()` | Yordamın sonraki sonuç kümesine geçiş |
| `close()` | Sonucu ve cursor kaynaklarını kapatma |

## `executemany()` ile toplu DML

```python
from stardataparadise_sdk import Bind

with open_database() as db:
    with db.cursor() as cursor:
        cursor.executemany(
            "INSERT INTO public.musteriler (id, ad, eposta) VALUES (:id, :ad, :eposta)",
            [
                {"id": 9001, "ad": "Örnek Müşteri A", "eposta": "a@example.test"},
                {"id": 9002, "ad": "Örnek Müşteri B", "eposta": Bind(None, "TEXT")},
            ],
        )
        print("Toplam eklenen:", cursor.rowcount)
```

Bu API yalnızca sonuç kümesi üretmeyen INSERT, UPDATE ve DELETE statement'ları içindir. Autocommit kipinde kendi transaction'ı içinde atomik çalışır. Mevcut manuel transaction içinde ise iç savepoint kullanır; listedeki bir işlem başarısız olduğunda bu toplu çağrının etkilerini geri alır. Daha önce aynı dış transaction'da yapılmış başka işlerin sonucunu uygulama belirler. Bu davranışı “her satır ayrı kalıcı commit” olarak düşünmeyin.

## DELETE ve sonraki sorguya geçiş

```python
with open_database() as db:
    with db.cursor() as cursor:
        cursor.execute("DELETE FROM public.urunler WHERE id = :id", {"id": 9001})
        print("Silinen:", cursor.rowcount)
```

Filtre olmadan DELETE çok daha geniş bir değişiklik yapar. Başka tablolardan referanslanan kayıtlarda foreign key kısıtları devreye girebilir. Aynı cursor'da yeni `execute()` önceki sonucu bırakır; hâlâ okumak istediğiniz satırlar varsa önce tüketin. Ayrı cursor'la aynı bağlantıda paralel sonuç açmayı denemeyin. Sonraki bölümde NULL, DECIMAL ve zaman tiplerinin doğru temsilini ayrıntılandıracağız.

## Kaynaklar

- [Cursor, executemany ve fetch uygulaması](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/src/stardataparadise_sdk/_dbapi.py)
- [Toplu işlem kabul testleri](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/tests/test_contract.py)
- [Tip bağlama](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/src/stardataparadise_sdk/_types.py)
