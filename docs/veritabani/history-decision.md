---
title: "History, geri yükleme ve Decision kuralları"
slug: "/veritabani/history-decision"
---

# History, geri yükleme ve Decision kuralları

**Kapsam:** original motorun mevcut `history_v1` ve Decision özellikleri. Server 0.5.2 release kaydında ertelenmiş olan yeni `sql_hist` ve `sql_jobs` özellikleri bunlarla aynı şey değildir.

Normal CRUD, verinin şu anki durumunu yönetir. History geçmiş commit'lerdeki satır ve katalog imajlarını incelemeyi; Decision ise önerilen bir yazmayı kayıtlı kurallara göre değerlendirmeyi sağlar. Her iki özellik de temel tablo tasarımının, transaction'ın ve backup'ın yanında kullanılır.

## History neyi kaydeder?

History revision'ları artan WAL LSN değerleriyle ilişkilidir. Commit edilen değişiklikler actor ve UTC bilgisiyle gösterilebilir. Eski kayıtlarda actor/UTC bilinmiyorsa NULL bulunabilir.

~~~sql
HISTORY LOG FOR public.urunler LIMIT 25;
HISTORY STATUS;
HISTORY VERIFY;
~~~

Bu komutları açık kullanıcı transaction'ı ve sonuç kümesi yokken çalıştırın; History kendi bağımsız salt okunur transaction'ını alır. Aksi durumda INVALID_STATE alınabilir.

Log sonucundan uygun revision'ı seçerek o andaki tabloyu okuyabilirsiniz. Aşağıdaki `<revizyon>` yer tutucusunu logdan gelen sayı ile değiştirin:

~~~text
HISTORY READ public.urunler AS OF REVISION <revizyon>;
~~~

History'nin `ROW` seçicisi stable internal row ID ister. Bu kimlik `urunler.id = 101` gibi uygulama PK'siyle aynı değildir. PK güncellense de stable row ID korunabilir. Bu ayrımı atlamak yanlış satırın incelenmesine yol açar.

## Geri yükleme önce planlanır

~~~text
HISTORY RESTORE public.urunler AS OF REVISION <revizyon>;
~~~

Bu komut doğrudan yazma yapmaz; değişecek, eklenecek veya silinecek satırları gösteren bir önizleme planı döndürür. Etkileri inceleyin. Aynı bağlantıda planı uygulamak için:

~~~text
HISTORY RESTORE APPLY '<plan_id>' REQUEST '<request_token>';
~~~

Token 32 küçük harfli hexadecimal karakterdir. CLI/RPC akışında alınan gerçek değerleri kullanın. Önizleme sonrası güncel revision değişmişse `stale_preview` alınır ve yeni plan gerekir.

Uygulama eski dosyayı doğrudan yerleştirmez; güncel yetki, FK, UNIQUE, CHECK ve trigger kurallarını denetleyerek yeni commit oluşturur. Tarihsel veri güncel kurallarla çelişiyorsa restore reddedilebilir. Başarılı geri yükleme de History'de yeni bir revision'dır.

History apply için belgelenmiş receipt/replay davranışı özel bir akıştır. Bu özellikten hareketle normal INSERT veya SDK commit'inin aynı tokenla serbestçe tekrar gönderilebileceğini varsaymayın.

## History ile backup farkı

History, aynı sistemin okunabilir geçmişini sunar. Retention sınırı ilerletildiyse eski revision erişilemeyebilir. Fiziksel WAL'ın recovery için saklanması, kullanıcıya her eski revision'ın sürekli açık olacağı anlamına gelmez.

`HISTORY VERIFY` CRC ve hash zincirini denetler; bağımsız güven kökü olmadığı için dışarıdan doğrulanmış değiştirilemezlik garantisi vermez. Disk kaybına karşı ayrı backup gerekir. Backup belgelerinde PITR capability kapalı olarak belirtilmiştir; “istediğim saniyeye sürekli geri dönerim” varsayımı yapılmamalıdır.

## Decision ile durum geçişi

Laboratuvardaki CHECK yalnız durum değerlerini sınırlar. Aşağıdaki örnek UPDATE kuralı, hazırlanan siparişin tamamlanmasına/iptaline ve durum değişmeden yapılan güncellemeye izin verir:

~~~sql
CREATE DECISION RULE siparis_durum_gecisi
ON public.siparisler FOR UPDATE PRIORITY 100
WHEN (
    OLD.durum = NEW.durum
    OR (
        OLD.durum = 'hazirlaniyor'
        AND (NEW.durum = 'tamamlandi' OR NEW.durum = 'iptal')
    )
)
THEN ALLOW;
~~~

Bu kuralı yönetici oluşturur. Aynı tablodaki diğer kuralların önceliklerini de değerlendirin. Guard kuralları büyük öncelikten küçüğe işlenir; daha yüksek öncelikte UNKNOWN veya hiçbir guard'ın eşleşmemesi yazmayı reddeder. Bu yüzden yalnız “negatif durumda DENY” kuralı ekleyip bütün diğer durumların otomatik geçeceğini sanmayın.

Decision BEFORE trigger'dan sonra, integrity kontrolleri ve yazmadan önce değerlendirilir. Kurala bağlı schema veya rutin sürümü değişirse yeniden değerlendirme gerekir. Decision modülü kapatıldığında kurallı tabloya yazmanın otomatik serbest kaldığı varsayılmaz; kaynakta `module_unavailable` davranışı tanımlıdır.

**Kaynaklar:** [History v1 ve restore](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/HISTORY.md), [Decision değerlendirme kuralları](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/DECISION.md), [backup kapsamı](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/BACKUP.md), [release özellikleri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/release.json).
