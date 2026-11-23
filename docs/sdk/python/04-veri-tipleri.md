---
title: "Python: tip dönüşümleri, Decimal ve zaman değerleri"
slug: "/sdk/python/04-veri-tipleri"
---

# Python: tip dönüşümleri, Decimal ve zaman değerleri

> **Kapsam:** SDK 0.3.0 · Wire v1 tip eşlemesi ve ayrıca belirtilen native farkları.

Python bazı veritabanı tiplerini doğal olarak temsil eder: `int` büyük tam sayıları saklar, `Decimal` ondalık basamakları korur ve `bytes` ikili veriyi taşır. Yine de Python tipinin kapasitesi SQL sütununun sınırını genişletmez. Örneğin Python `int` sınırsız büyüyebilse de wire `BIGINT` işaretli 64 bit aralığıyla sınırlıdır. Tipi doğru seçmek, yalnızca hatadan kaçınmak değil iş verisinin anlamını korumaktır.

## Wire v1 tipleri

| SQL tipi | Python girişi/sonucu | Not |
| --- | --- | --- |
| `BOOLEAN` | `bool` | `int` ile karıştırmadan kullanın |
| `BIGINT` | `int` | İşaretli 64 bit sınırı doğrulanır |
| `DECIMAL` | `decimal.Decimal` | En çok 38 basamak |
| `TEXT` | `str` | Unicode metin |
| `BLOB` | `bytes`, girişte ayrıca bytearray/memoryview | Ham baytlar |
| `DATE` | `datetime.date` | Saat ve ofset yoktur |
| `TIME` | `datetime.time` veya `TimeValue` | Nanosaniye için özel temsil gerekir |
| `TIMESTAMP WITH TIME ZONE` | Ofsetli datetime veya `TimestampValue` | Nanosaniye ve ofset korunur |
| `RECORD` / `COLLECTION` | `Record` / `Collection` | Tipli iç içe değerler |
| SQL `NULL` | Sonuçta `None`; girişte tip bildirimi | `Bind` veya `setinputsizes` |

## Para ve miktar

```python
from decimal import Decimal
from stardataparadise_sdk import Bind

fiyat = Decimal("1299.90")
parameters = {
    "id": 101,
    "fiyat": Bind(fiyat, "DECIMAL", precision=12, scale=2),
}
cursor.execute(
    "UPDATE public.urunler SET fiyat = :fiyat WHERE id = :id",
    parameters,
)
```

`Decimal("1299.90")` metinden kesin ondalık değer oluşturur. `Decimal(1299.90)` ise önce Python float'ının ikili temsilinden yola çıkar; para için bu yaklaşımı kullanmayın. `Bind` ile verilen precision ve scale, parametre sözleşmesini açıklaştırır. SDK hassasiyet veya ölçek kaybını sessizce yuvarlayarak çözmez. İşinizin yuvarlama kuralını uygulama veya SQL hesaplama tasarımında bilinçli olarak belirleyin.

## NULL bağlama

```python
cursor.execute(
    "UPDATE public.musteriler SET eposta = :eposta WHERE id = :id",
    {"id": 3, "eposta": Bind(None, "TEXT")},
)
```

Alternatif olarak cursor giriş tipini önceden bildirebilirsiniz:

```python
cursor.setinputsizes({"eposta": "TEXT"})
cursor.execute(
    "UPDATE public.musteriler SET eposta = :eposta WHERE id = :id",
    {"id": 3, "eposta": None},
)
cursor.setinputsizes({})
```

`setinputsizes` bu sağlayıcıda isimden SQL tip bildirimine bir mapping alır; başka DB-API sürücülerindeki sıralı boyut listelerini aynen aktarmayın. Bildirimleri ihtiyaç bittiğinde temizlemek, cursor'ı farklı sorgularda yeniden kullanırken görünmeyen tip varsayımlarını azaltır. SQL NULL, boş metin ve eksik sözlük anahtarı farklı durumlardır.

## Zaman hassasiyeti

```python
from datetime import datetime, timezone, timedelta
from stardataparadise_sdk import TimeValue, TimestampValue

an = datetime(2026, 11, 23, 10, 30, tzinfo=timezone(timedelta(hours=3)))
saat = TimeValue(10, 30, 0, 123456789)
kesin_an = TimestampValue(1795435200, 123456789, 180)
```

Ofsetsiz, yani naive datetime, hangi anı kastettiği belirsiz olduğu için uygun timestamp bağlama biçimi değildir. `TimestampValue.to_datetime()` ancak nanosaniye değeri Python'un mikrosaniye hassasiyetine kayıpsız sığıyorsa dönüşür; aksi durumda veri hatası verir. `TimeValue.to_time()` için de aynı hassasiyet kuralı geçerlidir. Uygulamanız nanosaniyeye ihtiyaç duyuyorsa wrapper'ı saklayın; sırf standart datetime elde etmek için basamakları atmayın.

## Native sonuçların farkı

Native bağlantı işaretsiz 64 bit tam sayıları Python `int`, 65 basamağa kadar native DECIMAL değerlerini `Decimal`, JSON verisini `NativeJson`, SQL TIME sürelerini `NativeTime` olarak döndürür. `NativeTime` negatif veya 24 saati aşan SQL sürelerini metniyle korur; gün içi saat olan wire `TimeValue` ile aynı model değildir.

`NativeJson.text` orijinal JSON'u saklar. `.decode()` Python tam sayıları ve `Decimal` kullanarak çözümleme yapar. SQL NULL ile JSON metni içindeki `null` farklı katmanlardadır: biri sütunun değersiz olması, diğeri JSON belgesinin içerdiği değerdir. Uygulama API'sine aktarırken `Decimal` ve tarihleri hangi JSON biçiminde vereceğinizi açıkça tanımlayın; Python'un standart `json.dumps` çağrısı bütün özel tipleri kendiliğinden serileştirmez.

## Kaynaklar

- [Wire tip kodlayıcı ve çözücü](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/src/stardataparadise_sdk/_types.py)
- [Native tipler](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/src/stardataparadise_sdk/_native.py)
- [setinputsizes uygulaması](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/src/stardataparadise_sdk/_dbapi.py)
