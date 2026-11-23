---
title: ".NET SDK: native SQL, Knowledge ve AI"
slug: "/sdk/dotnet/native-sql-ai"
---

# .NET SDK: native SQL, Knowledge ve AI

> **Kapsam:** Drive 2.1.0 / Framework paketi 2.0.0 içindeki `SdpNativeConnection`; Server'ın `native_sql_v1` capability'sini ilan etmesi gerekir. Kod örnekleri modern C# sözdizimi kullanır.

Native SQL bağlantısı `SdpConnection` ADO.NET oturumundan bağımsızdır. Burada `SdpCommand` ve isimli `:parametre` koleksiyonu kullanılmaz. `SdpNativeConnection.ExecuteAsync` tek SQL metni ve sıralı `?` parametreleri alır; sonuç tüm kümeleri içeren bir `SdpNativeResult` nesnesidir.

## Açılış ve parametreler

Native bağlantılar özel oturum kullanır; `Pooling=true` reddedilir. [SdpAyarlar](baglanti.md) sınıfının bağlantı metnini alıp native akış için timeout'u açıkça ayarlayabilirsiniz:

```csharp
using StarDataParadise.SDK;

var b = SdpFactory.Instance.CreateConnectionStringBuilder();
b.ConnectionString = SdpAyarlar.BaglantiMetni();
b["Timeout"] = 75;
b["Pooling"] = false;

using var db = await SdpNativeConnection.OpenAsync(
    b.ConnectionString, autocommit: true);

var sonuc = await db.ExecuteAsync(
    "SELECT CAST(? AS UNSIGNED), CAST(? AS JSON)",
    new object?[]
    {
        ulong.MaxValue,
        new SdpNativeJson("{\"id\":9007199254740993}")
    });
var satir = sonuc.Sets[0].Rows[0];
Console.WriteLine((ulong)satir[0]!);
Console.WriteLine(((SdpNativeJson)satir[1]!).Text);
```

Bağlantı açılırken capability doğrulanır. TLS ve kullanıcı kimliği aynı ayar biçiminden gelse bile ADO.NET oturumunun transaction'ı bu oturuma devredilmez. Açılıştaki `autocommit` varsayılanı `true` değeridir.

## Sonuçlar ve kesin değerler

`SdpNativeResult.Sets` her sonuç kümesini içerir. Kümenin `Columns`, `Rows`, `AffectedRows` ve `LastInsertId` alanları vardır. Son başarılı yanıttan alınan transaction bayrakları `InTransaction` ve `Autocommit` olarak korunur. Bunlar başarısız bir çağrıdan sonra sunucunun yeni durumunu garanti eden bağımsız sorgular değildir.

| Native değer | .NET karşılığı |
| --- | --- |
| Signed BIGINT | `long` |
| Unsigned BIGINT | `ulong` |
| DECIMAL | `SdpNativeDecimal` |
| JSON | `SdpNativeJson` |
| Binary | `byte[]` |
| SQL NULL | `null` |
| DATE/DATETIME/TIMESTAMP/TIME | `SdpNativeTemporal` |

Native decimal 65 katsayı basamağı ve en çok 30 scale için tasarlanmıştır. Wire `SdpDecimal` ile aynı sınırları paylaşmaz. `SdpNativeJson.Text` JSON sayılarının basamaklarını korur. `SdpNativeTemporal.SqlType` ile `Text` birlikte yorumlanır; native TIME negatif veya 24 saatten uzun süre taşıyabilir.

`ExecuteAsync` tek SQL ifadesi, en fazla 128 parametre ve 1–10.000 arasında `maxRows` kabul eder; varsayılan satır sınırı 1.000'dir. SQL metni 65.536 UTF-8 byte sınırındadır ve NUL içeremez. Prosedür gövdesini tek metin olarak gönderin; `DELIMITER` SDK çağrısının parçası değildir. Büyük yanıtlar sunucu bütçesi içinde parçalara ayrılır ve SDK tarafından SHA-256 ile denetlenerek birleştirilir.

## Native transaction ve AI turn

Normal native işlem için `BeginAsync()`, `CommitAsync()` ve `RollbackAsync()` kullanılır. AI konuşmasında sunucuda mevcut bir konuşma ve kullanılabilir model/worker gerekir. Aşağıdaki örnek `sdp_lab.assistant` konuşmasının hazır ve kullanıcı için izinli olduğunu varsayar:

```csharp
await db.ExecuteAsync("START AI CONVERSATION sdp_lab.assistant");
await db.ExecuteAsync("APPEND PROMPT ?",
    new object?[] { "Onaylanmış müşteri siparişini özetle." });
await db.ExecuteAsync(
    "APPEND RESPONSE INTO @answer AS JSON RETURNING METADATA INTO @meta");
await db.CommitAsync(waitTimeoutMs: 20000);

var cevap = await db.ExecuteAsync("SELECT @answer, @meta");
var answer = (SdpNativeJson)cevap.Sets[0].Rows[0][0]!;
Console.WriteLine(answer.Text);
```

API anahtarı SQL metnine veya prompt parametresine konmaz. Provider anahtarı/model dosyası sunucu ve worker yapılandırmasının konusudur. SDK kullanıcısı hazırlanmış model ve konuşmayı yetkileri dahilinde kullanır. Knowledge ile erişilen veri ve kullanılabilecek araçlar da sunucu tarafında tanımlanır; model çıktısından gelen serbest SQL uygulama tarafından doğrudan çalıştırılmaz.

Asenkron akış için `CommitAsync(requestKey: ..., asynchronous: true)` kullanılır. Bu çağrıda `waitTimeoutMs` verilmez. Dönen run belgesindeki kimliği saklayıp `FetchResponseAsync(runId)` ile izleyebilir veya `CancelRunAsync(runId)` ile iptal isteyebilirsiniz. Native `requestKey` AI deduplication kapsamındadır; wire CRUD receipt token'ı değildir.

## Hata alanları

`SdpException` üzerindeki `NativeErrno`, `Phase`, `CommitState`, `RunState`, `RunId` ve `Details` alanlarını koruyun. `CommitState=committed` ilk turn'ün kaydedildiğini anlatabilir; `ActionCommitState=rolled_back` aynı run içindeki araç işleminin ayrı bir sonucu olabilir. Bu iki sonucu tek "başarısız" bayrağına indirgemek uygulamanın yanlış tekrar yapmasına neden olur.

Native execute/fetch yanıtı kaybolduğunda `UnknownOutcome=true` olabilir ve `RequestToken` bulunmayabilir. Genel çözüm olarak `GetOutcomeAsync` çağrısı varsaymayın. SDK native ifadeyi otomatik tekrarlamaz. Bilinen `RunId` ve `CallId` üzerinden durum incelemesi yapın; belirsiz sonucu yeni yazma isteğiyle örtmeyin.

## Kaynaklar

- [Native .NET API ve tipler](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/src/SdpNativeConnection.cs)
- [Native hata alanları](https://github.com/ParadiseIncDevelopers/StarDataParadise.SDK.NET/blob/979b3f9905be3e08a6fac5d85198dd97aa180302/src/SdpException.cs)
- [Server native SQL sözleşmesi](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/contracts/sql/native-sql-v1.md)

