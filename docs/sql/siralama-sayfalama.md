---
title: "Sıralama, sonuç parçaları ve sayfalama"
slug: "/sql/siralama-sayfalama"
---

# Sıralama, sonuç parçaları ve sayfalama

**Kapsam:** original wire v1 SQL; native/Classic LIMIT davranışı bu sayfanın dışında.

Bir SELECT ifadesinde ORDER BY yoksa uygulama satırların belirli bir sırada geleceğine güvenmemelidir. Aynı veri iki farklı yürütme planında farklı sırada okunabilir. Kullanıcıya “ilk ürün” göstermek, sayfalar arasında devam etmek veya dışa aktarmayı karşılaştırmak için açık sıralama gerekir.

## Birden çok sıralama anahtarı

~~~sql
SELECT id, ad, fiyat
FROM public.urunler
ORDER BY fiyat ASC, id ASC;
~~~

Başlangıçta sıra 102, 101, 104, 103 olur. `ASC` artan, `DESC` azalan sıralamadır. İki ürünün fiyatı eşitse ikinci anahtar olan `id` sıralamayı kesinleştirir. Yalnız `ORDER BY fiyat` kullanmak, eşit fiyatların kendi aralarındaki sırasını tanımlamaz.

~~~sql
SELECT id, ad, fiyat
FROM public.urunler
ORDER BY fiyat DESC, id ASC;
~~~

Bu kez en pahalı ürün ilk sıraya gelir. Uygulama kullanıcıya sıralama seçtirecekse kolon adını bağlama parametresi yapmayın. “fiyat artan”, “fiyat azalan”, “kimlik” gibi önceden belirlenmiş SQL parçalarını seçin; filtre değerlerini parametre olarak bırakın.

## Türkçe karşılaştırma

Original SQL motorunun varsayılan metin sıralaması UTF-8 bayt sırasına dayanır. Türkçe sözlük sırası istenirse desteklenen collation açıkça seçilebilir:

~~~sql
SELECT id, ad
FROM public.musteriler
ORDER BY ad COLLATE turkish, id;
~~~

Türkçe collation Windows NLS sıralama bilgilerini kullanır. İlgili index oluşturulmuşsa onun collation tercihi ve sürümü de bakımın parçasıdır. İşletim sistemi sıralama bilgisi değiştiğinde eski bir index için REINDEX gerekebilir. İnsan adlarının ekranda sıralanmasıyla bir kimliğin eşitlik karşılaştırmasını aynı tasarım kararı olarak düşünmeyin.

## Fetch, SQL LIMIT değildir

Bu motorun incelenen SELECT grameri `LIMIT` veya `OFFSET` tanımlamaz. History komutunda görülen LIMIT sözdizimi SELECT'e genellenemez.

İstemci sonuçları küçük parçalar halinde alabilir. Python'da cursor fetch, Java'da ResultSet, .NET'te reader, Node.js'te async iterator bu okuma sürecinin farklı arayüzleridir. İlk 20 satırı aldıktan sonra sonuç kapatılabilir. Bu davranış uygulama belleğini sınırlar; tek başına sunucu tarafındaki sıralama ve join maliyetini ortadan kaldırmaz. Özellikle ORDER BY veya GROUP BY işlemi çıktıdan önce daha fazla satır inceleyebilir.

## Son kimlikle devam etmek

Kararlı bir anahtar üzerinde devam etmek için son gösterilen kimliği saklayın:

~~~sql
SELECT id, ad, fiyat
FROM public.urunler
WHERE id > :son_id
ORDER BY id;
~~~

Uygulama ilk sayfada `son_id = 0` kullanır, uygun sayıda satırı alır, sonucu kapatır ve son kimliği bir sonraki isteğe taşır. Bu yöntem önceki sayfalardaki bütün satırları tekrar okumayı azaltabilir. Ancak ilk N satırın istemcide alınması, N satırlık bir SQL yürütme sınırı tanımlandığı anlamına gelmez.

Fiyata göre sıralamada devam anahtarı iki alandan oluşur:

~~~sql
SELECT id, ad, fiyat
FROM public.urunler
WHERE fiyat > :son_fiyat
   OR (fiyat = :son_fiyat AND id > :son_id)
ORDER BY fiyat, id;
~~~

Fiyatların sayfalar arasında değişmesi bir ürünün yerini değiştirebilir. Uzun süre açık transaction tutarak kullanıcı gezinmesini sabitlemek, transaction lease süresini ve diğer oturumları etkiler. Raporun aynı veri anına ait olması gerekiyorsa kısa ve kontrollü bir export işlemi tasarlayın; ekran gezinmesinde güncel veri davranışını kabul edin ve kullanıcıya buna uygun sonuç verin.

**Kaynaklar:** [SQL grameri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/sql/SQL.ebnf), [sıralama ve kaynak sınırları](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/SQL_COMPATIBILITY.md), [fetch sözleşmesi](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/contracts/sql/SQL_RPC_V1.md).
