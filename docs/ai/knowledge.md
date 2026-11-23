---
title: "Knowledge ile veriyi kontrollü sunma"
slug: "/ai/knowledge"
---

# Knowledge ile veriyi kontrollü sunma

**Kapsam:** Native Knowledge; Classic/native `sdp_lab` tabloları ve çağıranın gerekli SELECT/EXECUTE izinleri.

Knowledge, uygulamanın belirli bir soruya karşılık gelen veriyi tipli ve tekrar kullanılabilir bir okuma arayüzüne dönüştürmesidir. SQL kaynağı tanımın içinde sabittir; çağrı parametreleri SQL metnine yapıştırılmaz. Böylece uygulama “sipariş 1001'in özeti” gibi dar bir veri ihtiyacını açıkça tanımlar.

## Sipariş özeti tanımı

Bu örnekte `sdp_lab.siparisler` tablosunda `id BIGINT`, `durum` metin alanı ve `toplam DECIMAL(12,2)` bulunduğu varsayılır:

```sql
CREATE KNOWLEDGE sdp_lab.siparis_ozeti(p_id BIGINT NOT NULL)
RETURNS TABLE (
    siparis_id BIGINT NOT NULL,
    durum TEXT NOT NULL,
    toplam DECIMAL(12,2) NOT NULL
)
READ ONLY SQL SECURITY INVOKER AS
SELECT id, durum, toplam
FROM sdp_lab.siparisler
WHERE id = :p_id;
```

Tanım, dışarıya hangi sütunların çıkacağını ve bunların tipini sabitler. Tabloda daha sonra özel not veya ödeme bilgisi sütunu eklense bile bu kaynak yalnız belirtilen üç alanı seçer. Bu, uygulamanın veri paylaşım sınırını gözden geçirmeyi kolaylaştırır.

## Doğrudan çağırma ve tablo kaynağı

```sql
EXECUTE KNOWLEDGE sdp_lab.siparis_ozeti(1001);

SELECT k.siparis_id, k.durum, k.toplam
FROM KNOWLEDGE sdp_lab.siparis_ozeti(1001) AS k;
```

İlk biçim sonucu doğrudan alır, ikinci biçim kaynağı bir native SELECT içinde kullanır. Parametre değeri tanımdaki `p_id` türüne göre bağlanır. SDK'da kullanıcıdan gelen sipariş kimliğini native `?` parametresiyle iletin; yukarıdaki 1001 yalnız ortak eğitim verisidir.

## Konuşmaya bağlam ekleme

```sql
START AI CONVERSATION sdp_lab.destek;
APPEND CONTEXT AS siparis_verisi
FROM KNOWLEDGE sdp_lab.siparis_ozeti(1001);
APPEND PROMPT 'Yalnız verilen sipariş durumuna dayanarak kısa bir açıklama yaz.';
APPEND RESPONSE INTO @yanit AS TEXT RETURNING METADATA INTO @meta;
COMMIT;
SELECT @yanit, @meta;
FINISH;
```

Bu akışta Knowledge sonucu yapılandırılmış bağlam verisidir. İçeriği yüksek öncelikli sistem talimatı gibi sunmayın. Sonuç boşsa uygulama önce “sipariş bulunamadı veya erişilebilir değil” durumunu ele almalıdır; modelin eksik sipariş hakkında tahmin üretmesini istememelisiniz.

## Yetki neden iki katmanlıdır?

Knowledge EXECUTE izni, alttaki tablolara SELECT hakkını kendiliğinden vermez. `SQL SECURITY INVOKER` çağıranın güncel haklarını kullanır. Tablo hakkı sonradan kaldırılmışsa önceden oluşturulmuş Knowledge tanımı bu kaldırmayı aşan kalıcı bir kapı olmamalıdır. Kaynakta native yürütme bu hakları çağrı sırasında denetler.

Tablo aynı adla silinip yeniden oluşturulursa onun iç DD kimliği değişir. Saklanan bağımlılığın yalnız adı eşleşti diye aynı kabul edilmesi doğru değildir. Şema migration'ında bağlı Knowledge tanımlarını yeniden doğrulayın ve gerektiğinde sürümlü ALTER akışını kullanın.

## Sınırlamalar ve veri tipleri

Bu profil salt okunur SELECT, desteklenen CTE/derived kaynaklar, temel tablolar ve izinli işlevlerle sınırlıdır. View, UDF/stored function, SELECT INTO, dosya erişimi, kilitleme ve sleep gibi kaynaklar destek kapsamı dışında tutulur. Sonuçta 10.000 satır üst sınırı vardır; bir Knowledge tanımını tüm veri ambarını tek çağrıda taşıyan bir araç olarak kurmayın.

NULL kurallarını açık yazın. Knowledge parametreleri ve sonuç sütunları varsayılan olarak non-null kabul edilir. SQL NULL kabul edecek parametre veya sonuç sütunu için bildirimde `NULL` açıkça yazılmalıdır. SQL NULL ile JSON null birbirinden farklıdır. Decimal ve 64 bit kimliklerin JSON veya dil katmanında yuvarlanmaması için ilgili SDK'nın native exact türlerini kullanın.

**Tasarım sorusu:** “Bütün siparişleri getir” kaynağı yerine neden parametreli sipariş özeti iyi bir başlangıçtır? Daha dar yetki, sınırlı veri çıkışı, öngörülebilir boyut ve işlevin amacını anlatan net bir sözleşme sağlar.

## Kaynaklar

- [StarDataParadiseServer / compatibility/ai/README.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/compatibility/ai/README.md)
- [StarDataParadiseServer / compatibility/tests/knowledge_native.py](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/compatibility/tests/knowledge_native.py)
- [StarDataParadiseServer / compatibility/tests/ai_context_native.py](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/compatibility/tests/ai_context_native.py)
