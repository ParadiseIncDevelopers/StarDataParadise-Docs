---
title: "Konuşma, prompt ve yapılandırılmış yanıt"
slug: "/ai/konusmalar"
---

# Konuşma, prompt ve yapılandırılmış yanıt

**Kapsam:** Native SQL. `sdp_lab` şeması ve kullanılabilir `sdp_lab.asistan_modeli` modelinin önceden hazırlanmış olması gerekir.

Bir konuşma model seçimini, bellek politikasını ve araç izinlerini bir araya getirir. İlk denemede araçsız konuşma kullanmak, sağlayıcı bağlantısını veri değiştirme akışından bağımsız doğrulamanızı sağlar. Aşağıdaki SQL bir çalışma akışıdır; SDK'nın native execute metoduna her ifadeyi ayrı çağrı olarak gönderin. Native API multi-statement kabul etmez.

## Konuşmayı oluşturma

```sql
CREATE AI CONVERSATION sdp_lab.destek
USING MODEL sdp_lab.asistan_modeli
NO FUNCTIONS MEMORY PERSISTENT;
```

Model adı önceki sayfadaki kurulumda sizin oluşturduğunuz nesnedir. `NO FUNCTIONS` bu denemede araç çağrısı açmaz. Persistent bellek, konuşma içeriğinin yalnız geçici uygulama değişkeni olarak ele alınmadığını belirtir; hangi verinin saklandığını uygulamanızın kullanıcı deneyimiyle açıkça ilişkilendirin.

## Basit bir tur

```sql
START AI CONVERSATION sdp_lab.destek;
APPEND PROMPT 'Sipariş durumunu kullanıcıya açıklarken hangi bilgiler gerekir?';
APPEND RESPONSE INTO @yanit AS TEXT RETURNING METADATA INTO @meta;
COMMIT;
SELECT @yanit, @meta;
FINISH;
```

Bu akış konuşmayı seçer, prompt ekler, yanıtın nereye ve hangi biçimde alınacağını belirtir ve turu kaydeder. Yanıtı ancak commit/bekleme sonucu değerlendirildikten sonra kullanın. `FINISH`, tamamlanmamış staging veya yazmaları sessizce atmak için kullanılmaz; kaynak uygulama bu durumları denetler.

## JSON yanıtı bir sözleşmeye bağlama

Serbest metin kullanıcıya gösterilebilir; uygulamanın karar vereceği alanlar için yapılandırılmış çıktı daha uygundur. Native response schema örneği:

```sql
CREATE RESPONSE SCHEMA sdp_lab.ozet_yaniti VERSION 1 AS JSON
'{"type":"object","properties":{"ozet":{"type":"string"}},"required":["ozet"],"additionalProperties":false}';
```

Sonraki bir turda yanıt isteği:

```sql
APPEND RESPONSE INTO @yanit AS JSON
WITH (schema='sdp_lab.ozet_yaniti', schema_version=1)
RETURNING METADATA INTO @meta;
```

İkinci kesit tek başına tam tur değildir; START ve APPEND PROMPT sonrasında, COMMIT öncesinde kullanılır. Şema biçimsel alanları sınırlar; modelin söylediği iş bilgisinin gerçek ve yetkili veriye dayandığını yine Knowledge ve uygulama denetimleri sağlamalıdır. JSON biçimi bir satır güncelleme yetkisi değildir.

## Asenkron sonuç

Native SQL `COMMIT ASYNC` yolu sunar. SDK'ların native commit yardımcıları dönen run bilgisini korur; kendi dilinizin native SQL sayfasındaki `fetchResponse`/`fetch_response` karşılığıyla durumu okuyun. Uzun süren isteği bir HTTP bağlantısında sınırsız bekletmek yerine run kimliğini uygulamanın iş kaydına bağlayıp kullanıcıya işlem durumunu gösterebilirsiniz.

Bekleme timeout'u aldığınızda önce hatanın `commit_state`, `run_id` ve `unknown_outcome` bilgisini inceleyin. `committed` bir tur için yeniden APPEND/COMMIT yapmak yeni iş veya yinelenen kullanıcı mesajı üretebilir. Başarıyla commit edilmiş run, bağlantı kapatıldı diye otomatik iptal edilmez.

## Hangi alanları saklamalısınız?

Uygulama konuşma nesnesini, kendi iş kimliğini, run kimliğini, sonuç durumunu ve gerekli metadata'yı ilişkilendirmelidir. Tüm provider cevabını hata günlüğüne yazmak yerine işin devamı için gereken alanları saklayın. AI `request_key` aynı turun tekilleştirilmesini hedefler; bağımsız sipariş INSERT'lerinin genel tekrar güvenliği değildir.

**Alıştırma:** Kullanıcı “Yanıt gelmedi” diyorsa hangi iki soruyu önce sorarsınız? Tur commit oldu mu, worker/provider işi hangi durumda? Bu iki yanıt olmadan yeniden gönder düğmesini otomatik işletmeyin.

## Kaynaklar

- [StarDataParadiseServer / compatibility/ai/README.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/compatibility/ai/README.md)
- [StarDataParadiseServer / compatibility/tests/ai_context_native.py](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/compatibility/tests/ai_context_native.py)
- [StarDataParadiseServer / compatibility/ai/native/ai-family-next.inc](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/compatibility/ai/native/ai-family-next.inc)
- [StarDataParadiseServer / contracts/sql/native-sql-v1.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/contracts/sql/native-sql-v1.md)
