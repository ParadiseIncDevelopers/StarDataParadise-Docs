---
title: "Python SDK: kurulum ve ilk sorgu"
slug: "/sdk/python/01-kurulum"
---

# Python SDK: kurulum ve ilk sorgu

> **Kapsam:** `stardataparadise_sdk` 0.3.0 · Python 3.12 ve üzeri · DB-API 2.0 / Wire v1. Kaynak incelemesi: 23 Kasım 2026.

Python SDK, StarDataParadise Server'a TLS üzerinden bağlanan bir DB-API 2.0 istemcisidir. SQL metnini ve parametrelerini sunucuya gönderir, sonuçları Python değerlerine dönüştürür ve transaction yaşam döngüsünü yönetir. Çalışma zamanında Python standart kütüphanesine dayanır; native DLL yüklemek gerekmez. SDK kurulumu Server kurulumundan ayrıdır. Server'ın çalışması, kullanıcının tanımlanması ve örnekteki tabloların oluşturulması önkoşuldur.

Bu bölümdeki `public` tabloları orijinal motorun `sql_crud_v1` kapsamındaki SQL laboratuvarını kullanır. Bir köprünün `wire_sql_basic_v1` desteği, aynı CREATE TABLE ve diğer DDL işlemlerini sunduğu anlamına gelmez. Native SQL laboratuvarı `sdp_lab` veritabanında ayrıca hazırlanır. Önce hangi bağlantıya ve motora eriştiğinizi belirlemek, daha sonra görülecek “desteklenmeyen komut” hatalarının önemli bölümünü önler.

## 1. Sanal ortam oluşturun

SDK deposu yerel wheel üzerinden kurulum akışını belgelendirir. Aşağıdaki komutlarda wheel dosyasını gerçekten bulunduğu konuma göre değiştirin:

```powershell
python --version
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install --no-deps C:\SDP\packages\stardataparadise_sdk-0.3.0-py3-none-any.whl
```

Sanal ortam, uygulamanın bağımlılıklarını sistemdeki diğer Python projelerinden ayırır. `pip` komutunu Python yorumlayıcısıyla `-m pip` şeklinde çağırmak hangi ortama kurduğunuzu açık hale getirir. Bu rehber kamuya açık PyPI yayınını doğrulamaz; belirtilen wheel adını internet üzerinde mutlaka bulunan bir paket gibi değerlendirmeyin. Derleme gerekiyorsa depodaki `ci.ps1` ve sabit wheelhouse gereksinimlerini kullanın.

```powershell
.\.venv\Scripts\python.exe -c "import stardataparadise_sdk as sdp; print(sdp.__version__, sdp.apilevel, sdp.paramstyle)"
```

Beklenen SDK arayüzü `apilevel = '2.0'`, `paramstyle = 'named'` olarak tanımlıdır. İsimli parametre biçimi, wire sorgularında `:id` ve Python sözlüğü kullanacağımızı gösterir.

## 2. İlk sorguyu çalıştırın

`SDP_USER`, `SDP_PASSWORD`, `SDP_CA` ortam değişkenlerini süreç için sağlayın. CA dosyası sunucu sertifikasına güveni, `tls_name` sertifikadaki sunucu kimliğini doğrular. Örnekte mevcut `public.urunler` tablosu için SELECT izni gerekir.

```python
# ilk_sorgu.py
import os
from stardataparadise_sdk import connect

with connect(
    host="127.0.0.1",
    port=7443,
    user=os.environ["SDP_USER"],
    password=os.environ["SDP_PASSWORD"],
    ca_file=os.environ["SDP_CA"],
    tls_name="localhost",
    autocommit=True,
) as db:
    print("Server:", db.server_version)
    with db.cursor() as cursor:
        cursor.execute(
            "SELECT id, ad, stok FROM public.urunler WHERE id >= :ilk ORDER BY id",
            {"ilk": 101},
        )
        for urun_id, ad, stok in cursor:
            print(urun_id, ad, stok)
```

```powershell
.\.venv\Scripts\python.exe .\ilk_sorgu.py
```

İçteki `with` cursor kaynaklarını kapatır; dıştaki `with` bağlantı yaşam döngüsünü yönetir. Örnekte bağımsız okuma için autocommit açık seçilmiştir. Varsayılan manuel kipte bağlantı bağlamından başarıyla çıkılması commit, hata ile çıkılması geri alma ve kapatma davranışı doğurur. Bu davranışı anlamadan `with` bloğu içinde hataları yutup işlem başarılıymış gibi devam etmeyin.

## 3. Sonucu değerlendirin

`BIGINT` sütunlar Python `int`, metinler `str` olarak gelir. Sorgunun sıfır satır dönmesi, kurulumun bozuk olduğunu göstermez; filtreye uyan veri bulunmayabilir. TLS, kimlik doğrulama, yetki veya SQL hataları exception olarak bildirilir. `ModuleNotFoundError` ise genellikle script'in paketin kurulduğu sanal ortamdan farklı bir yorumlayıcıyla çalıştırıldığını gösterir.

Sonraki sayfalarda bağlantı seçeneklerini ortak bir `db.py` yardımcısına taşıyacağız, CRUD işlemlerini ayrıntılandıracağız ve veri tiplerini inceleyeceğiz. `connect_native()` ile açılan native SQL/AI oturumu farklıdır; orada cursor yerine doğrudan `execute()` ve konumsal parametreler kullanılır.

## Kaynaklar

- [README ve wheel kurulumu](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/README.md)
- [DB-API sabitleri ve connect imzası](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/src/stardataparadise_sdk/__init__.py)
- [Derleme ve kullanım ayrıntıları](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.Python/blob/2bccf1306e401955304f5bd5f9c415250c6a55a4/BUILD.md)
