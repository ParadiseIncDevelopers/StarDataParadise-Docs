---
title: "CLI ile sorgu, betik ve otomasyon"
slug: "/araclar/cli"
---

# CLI ile sorgu, betik ve otomasyon

**Kapsam:** Windows wire v1 `StarDataParadiseCLI.exe`. Classic `mysqlsh.exe` ayrı istemcidir.

CLI hem SQL'i etkileşimli denemek hem aynı betiği denetlenebilir biçimde tekrar çalıştırmak için kullanılır. Otomasyonda başarı ölçütü yalnız ekranda bir sonuç görmek değildir; çıkış kodunu, çıktı olaylarını ve transaction sonucunu değerlendirmelisiniz.

## Profil dosyası

`lab.json` örneği:

```json
{
  "host": "127.0.0.1",
  "port": 7443,
  "user": "local-admin",
  "ca_file": "ca.pem",
  "tls_name": "localhost",
  "timeout_ms": 5000,
  "production": false
}
```

CA yolu profile göre çözülür. Profil parola alanı kabul etmez. Etkileşimli bağlantı için `StarDataParadiseCLI.exe --profile .\lab.json` yeterlidir; parola konsolda okunur. Üretim profili `production: true` veya `--prod` ile görünür PROD etiketi taşıyabilir. Bu etiket yetki sağlamaz; ortamı fark etmeye yardımcı olur.

## Sık kullanılan komutlar

| CLI komutu | Amaç |
| --- | --- |
| `\status`, `\capabilities` | Bağlantı ve desteklenen özellikler |
| `\databases`, `\tables`, `\describe NAME` | Yetki kapsamındaki katalog |
| `\run FILE` | UTF-8 SQL betiği |
| `\begin`, `\commit`, `\rollback` | Transaction sınırı |
| `\savepoint NAME`, `\rollback NAME`, `\release NAME` | Ara geri dönüş noktası |
| `\format table`, `\format vertical` | Sonuç görünümü |
| `\timing on` | İfade süresini stderr'e yazma |
| `\outcome TOKEN` | Belirsiz wire yazmasının kalıcı kaydı |
| `\quit` | Oturumu kapatma |

SQL ifadeleri noktalı virgülle biter. CLI komutlarını `.sql` dosyalarına rastgele karıştırmayın; özellikle `--transaction single` açık transaction komutlarını reddeder. SQL laboratuvarındaki DDL/DML betikleri tek transaction seçeneğiyle, yönetim çağrıları ise kendi belirtilen bağlamlarında yürütülmelidir.

## Tek transaction ile otomasyon

PowerShell 7.3+ üzerinde, parola işlem ortamından sağlandığında:

```powershell
$env:SDP_PASSWORD | .\StarDataParadiseCLI.exe --profile .\lab.json --password-stdin --file .\ders.sql --transaction single --stop-on-error --format ndjson --output .\ders-sonuc.ndjson
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
```

`--transaction single` bütün girdi için tek işlem açar; hata halinde geri alır. Varsayılan `--transaction each`, normal yazma ifadelerini ayrı transaction'larda yürütür. Bu fark, bir seed dosyasının yarıda kalması halinde hangi kayıtların kalıcı olacağını belirler. `--stop-on-error` hata sonrası diğer komutlara geçilmesini engeller.

## Parametreleri ayrı iletme

POSIX shell kullanılan bir Windows ortamında kaynak sözleşmesindeki bağ biçimi:

```sh
printf '%s\n' "$SDP_PASSWORD" | ./StarDataParadiseCLI.exe \
  --profile ./lab.json --password-stdin --format ndjson \
  --command 'SELECT id, ad, stok FROM main.public.urunler WHERE id = :wanted' \
  --bind 'wanted={"t":"i64","v":"101"}'
```

Bu örnekte SQL ile değer farklı argümanlardır. Kullanıcı girdisini SQL metnine ekleyerek tırnak kaçışlarını elle yönetmeyin. NULL için tip bildirimi gerekebilir; CLI sözleşmesi `type` ve `value` içeren bağ biçimini tanımlar.

## Çıktıyı makineyle okuma

JSON tek nesnede olay dizisi verir. NDJSON her satırda ayrı olay üretir; batch sonuçları ve son status olayı birlikte okunur. CSV'de SQL NULL ile boş metni ayırın: NULL tırnaksız `\N` olarak gösterilir. JSON'daki 64 bit tamsayı ve exact decimal değerleri düz kayan noktalı sayıya dönüştürmek hassasiyet kaybına yol açabilir.

| Çıkış kodu | Anlam |
| ---: | --- |
| 0 | Başarı |
| 2 | Seçenek, profil veya girdi hatası |
| 3 | Kimlik doğrulama/yetki |
| 4 | Bağlantı, TLS, timeout veya protokol |
| 5 | SQL/transaction hatası |
| 6 | İptal |
| 7 | İşlem sonucu belirsiz |

Kod 7 geldiğinde aynı betiği otomatik yeniden çalıştırmayın. Token'ı kaydedin, aynı kullanıcıyla yeni bağlantı açın ve outcome sorgulayın. Kod 0 dışındaki bütün durumları tek bir “geçici ağ hatası” olarak ele alan bir otomasyon yazma tekrarlarına neden olabilir.

## Kaynaklar

- [StarDataParadiseCli / CLI.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseCli/blob/95f07c6046662bfc3a49dc2ccced36898b0db07b/CLI.md)
- [StarDataParadiseCli / README.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseCli/blob/95f07c6046662bfc3a49dc2ccced36898b0db07b/README.md)
