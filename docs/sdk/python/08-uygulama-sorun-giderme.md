---
title: "Python: stok servisi örneği ve sorun giderme"
slug: "/sdk/python/08-uygulama-sorun-giderme"
---

# Python: stok servisi örneği ve sorun giderme

> **Kapsam:** SDK 0.3.0 · Wire v1 · `public.urunler` tablosu. Örnek uygulama kodudur; SDK'nın yerleşik bir servisi değildir.

Veri erişim kodunu küçük bir iş fonksiyonunda toplamak, HTTP katmanı, zamanlanmış betik ve komut satırı uygulaması arasında yeniden kullanmayı sağlar. Aşağıdaki fonksiyon bir ürünün stokunu azaltır ve üç farklı sonucu ayırır: tamamlandı, iş kuralı nedeniyle reddedildi, commit sonucu belirsiz. Teknik hataların tamamını stok yetersizliği gibi göstermek yerine bu ayrımı korur.

Önce [bağlantı bölümündeki](02-baglanti.md) `db.py` dosyasını oluşturun. Ortak SQL laboratuvarındaki ürün `101` başlangıçta 20 stokla gelir; laboratuvarı daha önce değiştirdiyseniz deneme öncesi güncel değeri okuyun. Örnek, Server'a UPDATE izni olan bir kullanıcıyla çalıştırılır.

## İş fonksiyonu

```python
# stok_servisi.py
from stardataparadise_sdk import OutcomeUnknown
from db import open_database


def stok_ayir(urun_id: int, adet: int) -> dict:
    if type(urun_id) is not int or urun_id <= 0:
        raise ValueError("urun_id pozitif int olmalı")
    if type(adet) is not int or adet <= 0:
        raise ValueError("adet pozitif int olmalı")

    db = open_database()
    try:
        with db.cursor() as cursor:
            cursor.execute(
                """UPDATE public.urunler SET stok = stok - :adet
                   WHERE id = :id AND stok >= :adet""",
                {"id": urun_id, "adet": adet},
            )
            affected = cursor.rowcount
        if affected != 1:
            db.rollback()
            return {"durum": "reddedildi", "neden": "Ürün yok veya stok yetersiz"}
        db.commit()
        return {"durum": "tamamlandi", "urun_id": urun_id, "adet": adet}
    except OutcomeUnknown as error:
        return {
            "durum": "sonuc_belirsiz",
            "request_token": error.request_token,
        }
    finally:
        db.close()
```

```python
# deneme.py
from stok_servisi import stok_ayir

if __name__ == "__main__":
    print(stok_ayir(101, 2))
```

```powershell
.\.venv\Scripts\python.exe .\deneme.py
```

`type(value) is int` kontrolü burada bilinçli seçildi: Python'da `bool`, `int` alt sınıfı olsa da `True` değerini ürün kimliği veya adet olarak kabul etmek istemiyoruz. Değerler bağlanırken SDK ayrıca SQL BIGINT aralığını doğrular. HTTP isteğinde metin olarak gelen bir kimliği dönüştürme ve hatalı gövdeye uygun yanıt verme dış katmanın sorumluluğudur.

## Gerçek sipariş akışına genişletme

Bu fonksiyon stok düşümünü gösterir; sipariş veya ödeme oluşturmaz. Sipariş kaydı ve kalemlerini eklerken aynı transaction içinde INSERT yapın. Commit başarılı olduktan sonra iş tamamlandı sayılır. Bildirim veya e-posta gibi dış etkileri uzun süre açık veritabanı transaction'ı içinde bekletmeyin; gerekiyorsa uygulamanın ayrı güvenilir teslim tasarımını kurun.

`sonuc_belirsiz` çıktısında kullanıcıya aynı işlemi tekrar yaptırmadan önce [outcome sorgusuyla](05-transaction.md) receipt durumunu kontrol edin. İş isteği için benzersiz uygulama anahtarı tutmak, çift HTTP gönderimiyle belirsiz ağ sonucunu birbirinden ayırmanıza yardımcı olur. Bu örnek tek başına genel idempotency sistemi sağlamaz.

## Sorun giderme tablosu

| Belirti | Kontrol edilecek nokta |
| --- | --- |
| `ModuleNotFoundError` | Kurulum ve çalıştırma aynı `.venv` Python'ını mı kullanıyor? |
| TLS kimlik hatası | `tls_name` sertifikadaki adla, `ca_file` güven zinciriyle uyuşuyor mu? |
| SQL parametre hatası | Wire için `:ad` ve mapping, native için `?` ve tuple/list kullanılıyor mu? |
| `DataError` / NULL | `Bind(None, 'TEXT')` veya uygun `setinputsizes` var mı? |
| Açık cursor sonucu hatası | Önceki cursor tüketildi veya kapatıldı mı? |
| Yazma kayboluyor | Manuel transaction commit edildi mi; yalnızca `close()` mu çağrıldı? |
| Sonuç belirsiz | Token kaydedilip aynı kimlikle `outcome()` sorgulandı mı? |
| Native AI desteklenmiyor | `connect_native()` ve `native_sql_v1` var mı; worker/model hazır mı? |

## Laboratuvar kabul adımları

Önce başlangıç stokunu ayrı bir okuma bağlantısıyla kaydedin. Pozitif ve stoktan küçük bir adet gönderin; tamamlandı sonucundan sonra yeni bağlantıyla değerin azaldığını kontrol edin. Ardından stoktan büyük bir adet isteyip reddedildi sonucunda değerin değişmediğini doğrulayın. Sıfır, negatif, bool ve metin girdilerinin SQL çalışmadan reddedildiğini değerlendirin.

Bu adımlar önerilen kullanıcı kabul senaryolarıdır; doküman hazırlanırken canlı Server üzerinde yürütülmüş sonuçlar olarak sunulmaz. SDK'nın kendi test deposu tipler, cursor yaşam döngüsü, executemany atomikliği, iptal ve kayıp commit onayı için fixture testleri içerir. Kendi uygulamanızın iş kuralları ve izin modeli ayrıca doğrulanmalıdır.

## Örnek dosyalar

Aynı klasöre alınabilecek dosyalar: [ilk_sorgu.py](/downloads/sdk/python/ornekler/ilk_sorgu.py), [db.py](/downloads/sdk/python/ornekler/db.py), [stok_servisi.py](/downloads/sdk/python/ornekler/stok_servisi.py), [deneme.py](/downloads/sdk/python/ornekler/deneme.py). Paket, çalışan Server, laboratuvar tabloları ve ortam değişkenleri önkoşuldur.

## Kaynaklar

- [SDK kabul ve transaction testleri](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/tests/test_contract.py)
- [Connection/Cursor yaşam döngüsü](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/src/stardataparadise_sdk/_dbapi.py)
- [DB-API hata sınıfları](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/src/stardataparadise_sdk/_errors.py)
