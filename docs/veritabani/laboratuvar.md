---
title: "Ortak laboratuvarı kurmak"
slug: "/veritabani/laboratuvar"
---

# Ortak laboratuvarı kurmak

**Kapsam:** original wire v1 SQL, `main.public`. SQL ve dört dildeki SDK örnekleri aynı müşteri–ürün–sipariş modelini kullanır.

Bu laboratuvar küçük bir ticaret uygulamasını temsil eder. Amaç, sorguları her bölümde farklı tablo adlarıyla baştan öğrenmek yerine aynı model üzerinde adım adım ilerlemektir. Sipariş başlığı ile kalemleri ayrı tutulur; fiyat bilgisi hem ürünün güncel fiyatı hem sipariş anındaki birim fiyatı olarak farklı anlamlarla bulunur.

Classic/native SDK veya Knowledge için ayrı [native laboratuvarını](native-laboratuvar.md) kullanın. Bu sayfanın 01–03 dosyaları original motor içindir; native kurulumun 04–06 dosyalarıyla karıştırılmamalıdır.

## İlişki haritası

~~~mermaid
erDiagram
    MUSTERILER ||--o{ SIPARISLER : verir
    SIPARISLER ||--o{ SIPARIS_KALEMLERI : icerir
    URUNLER ||--o{ SIPARIS_KALEMLERI : secilir
    MUSTERILER {
        BIGINT id PK
        TEXT ad
        TEXT eposta
    }
    SIPARISLER {
        BIGINT id PK
        BIGINT musteri_id FK
        TEXT durum
        DECIMAL toplam
    }
    URUNLER {
        BIGINT id PK
        TEXT ad
        DECIMAL fiyat
        BIGINT stok
    }
    SIPARIS_KALEMLERI {
        BIGINT siparis_id PK, FK
        BIGINT urun_id PK, FK
        BIGINT adet
        DECIMAL birim_fiyat
    }
~~~

`siparis_kalemleri` bileşik anahtarı aynı ürünü bir siparişe bir kez eklemeye izin verir; miktar `adet` alanında tutulur. Gerçek uygulamanız aynı ürünü farklı kampanya veya teslimat satırlarında ayrı gösterecekse ayrıca bir kalem kimliği tasarlamanız gerekir.

## Kurulum dosyaları

1. [01_sema.sql](pathname:///StarDataParadise-Docs/downloads/ornekler/sql/01_sema.sql): Dört tablo, PK/FK/CHECK/UNIQUE kısıtları ve müşteri siparişleri için bir index.
2. [02_ornek_veri.sql](pathname:///StarDataParadise-Docs/downloads/ornekler/sql/02_ornek_veri.sql): Başlangıç müşteri, ürün ve sipariş kayıtları.
3. [03_sorgular.sql](pathname:///StarDataParadise-Docs/downloads/ornekler/sql/03_sorgular.sql): Salt okunur kontrol sorguları ve beklenen değerlerin yorumları.

Dosyalar **boş ve ayrı bir test instance'ı** içindir. Var olan tabloları silmez; aynı adlar zaten bulunursa kurulumun hata vermesi beklenir. Bu davranış yanlışlıkla mevcut verinin üstüne yazılmasını önler.

## CLI ile çalıştırmak

Bağlantı için geçerli `lab.json` profili ve işlem ortamında `SDP_PASSWORD` gerektiğini varsayıyoruz. PowerShell 7.3+:

~~~powershell
$env:SDP_PASSWORD | .\StarDataParadiseCLI.exe --profile .\lab.json --password-stdin --file .\01_sema.sql --transaction single --stop-on-error --format ndjson
if ($LASTEXITCODE -ne 0) { throw "Şema kurulamadı." }

$env:SDP_PASSWORD | .\StarDataParadiseCLI.exe --profile .\lab.json --password-stdin --file .\02_ornek_veri.sql --transaction single --stop-on-error --format ndjson
if ($LASTEXITCODE -ne 0) { throw "Örnek veriler eklenemedi." }

$env:SDP_PASSWORD | .\StarDataParadiseCLI.exe --profile .\lab.json --password-stdin --file .\03_sorgular.sql --transaction single --stop-on-error --format json
if ($LASTEXITCODE -ne 0) { throw "Kontrol sorguları tamamlanamadı." }
~~~

Profilde parola saklanmaz; parola girdisi ayrı kanaldan iletilir. Dosyaların bulunduğu çalışma dizinine göre yolları değiştirin. Workbench kullanıyorsanız aynı ifadeleri doğru wire v1 bağlantısında sırayla çalıştırın ve transaction durumunu izleyin.

## Başlangıç verisi

| Tablo | Satır sayısı | Kontrol |
| --- | ---: | --- |
| musteriler | 4 | Ayşe, Mehmet, Zeynep, Deniz |
| urunler | 4 | 101 Klavye, 102 Fare, 103 Monitör, 104 USB Hub |
| siparisler | 4 | 1001–1004 |
| siparis_kalemleri | 6 | 1001 ve 1003 ikişer kalem |

| Ürün | fiyat | stok |
| --- | ---: | ---: |
| Klavye | 750.00 | 20 |
| Fare | 350.00 | 50 |
| Monitör | 6500.00 | 8 |
| USB Hub | 900.00 | 0 |

Sipariş toplamlarının toplamı 9950.00, yalnız `tamamlandi` durumundakilerin toplamı 7600.00'dır. Sipariş 1001'in iki kalemi 750.00 + 2 × 350.00 = 1450.00 eder.

## Deneyleri tekrarlamak

Okuma örnekleri birbirini etkilemez. Yazma örnekleri başlangıç verisini değiştirebilir. Bu nedenle deneme transaction'ı açıp sonucu okuduktan sonra rollback yapın. Bazı bölümler yeni nesne oluşturur; bu nesneleri de ayrı test instance'ında veya ayrılmış schema'da tutun.

SDK bölümlerindeki yeni sipariş örnekleri 2001 gibi yeni kimlikler kullanabilir. Aynı örneği commit ederek tekrar çalıştırırsanız PK ihlali beklenir. Bu bir bağlantı hatası değildir; örnek verinin tekrar kullanımından kaynaklanır.

**Doğrulama düzeyi:** Dosyalar kaynak grameri, sözleşmeler ve mevcut test örnekleriyle karşılaştırılmıştır. Buradaki beklenen sonuçlar verilen seed verisinden türetilmiştir; bu hazırlık oturumunda çalışan Server üzerinde yürütülmemiştir.

**Kaynaklar:** [relational kurallar ve örnekler](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/tests/relations_smoke.cpp), [CLI dosya/transaction kullanımı](https://github.com/ParadiseIncDevelopers/StarDataParadiseCli/blob/95f07c6046662bfc3a49dc2ccced36898b0db07b/CLI.md), [SQL grameri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/sql/SQL.ebnf).
