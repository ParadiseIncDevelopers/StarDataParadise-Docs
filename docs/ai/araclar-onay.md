---
title: "Araç çağrıları ve onaylanan eylemler"
slug: "/ai/araclar-onay"
---

# Araç çağrıları ve onaylanan eylemler

**Kapsam:** Native AI araç/onay profili; eşleşen binary, kataloglar ve açık actions özelliği gerekir.

Bir modelin cevap üretmesiyle veriyi değiştiren bir prosedürü çağırması farklı sorumluluklardır. Araç listesi, modelin erişebileceği Knowledge, function ve procedure tanımlarını açıkça sınırlar. Sipariş iptali gibi bir işlem ayrıca insan onayı gerektirebilir.

## Araç listesini açık tanımlayın

Önceden oluşturulmuş model, Knowledge ve yordamlar için kaynakta tanımlanan biçim:

```sql
CREATE AI CONVERSATION sdp_lab.aracli_destek
USING MODEL sdp_lab.asistan_modeli
WITH FUNCTIONS (
    KNOWLEDGE sdp_lab.siparis_ozeti,
    FUNCTION sdp_lab.tutar_hesapla,
    PROCEDURE sdp_lab.siparis_iptal
);
```

Bu örnek yalnız ilişkilendirme sözdizimini gösterir; `tutar_hesapla` ve `siparis_iptal` iş kurallarınıza göre önceden tanımlanmalıdır. Modelin gönderdiği keyfi SQL kaynağı çalıştırılmaz. Araç tanımı ve çağrı parametreleri izinli, kimliği/sürümü bağlanmış nesnelere karşı doğrulanır.

Bir iptal prosedürü uygulama yetkilerini, siparişin güncel durumunu ve gerekli iş koşullarını denetlemelidir. “Model iptal et dedi” bilgisi tek başına yetki veya geçerli iş kuralı değildir. İstemci tarafında yapılan bir kontrol, prosedür içindeki transaction denetiminin yerine geçmez.

## Onay akışının parçaları

Korunacak prosedürün approval policy'si ve onay rolü önceden kurulmuşsa:

```sql
REQUIRE APPROVAL ON PROCEDURE sdp_lab.siparis_iptal;
GRANT APPROVE ON PROCEDURE sdp_lab.siparis_iptal TO ROLE siparis_onaylayan;
PREPARE ACTION CALL sdp_lab.siparis_iptal(1001) RETURNING ID INTO @eylem;
APPROVE ACTION @eylem;
EXECUTE ACTION @eylem;
```

Bu komutlar görevleri gösteren bir akıştır. **FK/cascade içermeyen ve action profilini karşılayan ayrı bir örnek tablo/yordam hazırlanmasını gerektirir; ortak ilişkisel sipariş laboratuvarına doğrudan uygulanmış kabul edilmez.** Gerçek uygulamada hazırlayan, yetkili onaylayan ve uygulayan oturumlar ürünün rol politikasına göre ayrılır. `@eylem` bir oturum değişkenidir: ayrı bağlantıya geçildiğinde uygulama gerçek `action_id` değerini aktarır; önceki bağlantının değişkeni yeni bağlantıda bulunmaz. Sıradan bir kullanıcıya approve rolü verilmiş gibi varsayarak örneği çalıştırmayın.

Modelden gelen bekleyen çağrıyı onay sürecine bağlamak için kaynak `PREPARE ACTION FOR TOOL CALL '<call_id>' RETURNING ID INTO ...` biçimini tanımlar. Buradaki kimlik gerçek bekleyen çağrıdan alınır. Uygulama keyfi bir hedef/argüman snapshot'ı oluşturup onaylanmış gibi göndermez.

## Onay ile uygulama arasındaki değişiklik

Onay, hedefi, argümanları, policy/aktif yetkileri ve kaynak bağımlılıklarını içeren snapshot'a bağlıdır. Kullanıcı ekrandaki siparişi onayladıktan sonra ilgili bağımlılık değişmişse snapshot stale olabilir. Uygulama tekrar güncel planı göstermeli ve yeni onay sürecini işletmelidir; eski onayı yeni veriye sessizce taşımamalıdır.

İlk kaynak profili InnoDB, primary key ve desteklenen kayıpsız türler ister. FK/cascade kaynakları bu action snapshot profilinde sınırlıdır. Bu sınırlama genel Classic veritabanı tasarımında bütün foreign key'lerin yasak olduğu anlamına gelmez; belirli native action yürütme profilinin kapsamıdır.

## Sonucun iki transaction'ı

AI turunun `commit_state` alanı ile aracın `action_commit_state` alanı farklıdır. AI konuşması kaydedilmiş olabilir, fakat araç kendi transaction'ında rollback edilmiş olabilir. Bu durumda kullanıcıya “konuşma geri alındı” demek veya aynı aracı otomatik tekrar çalıştırmak doğru değildir. Hata bilgisi `run_id`, `call_id`, public/native kod ve varsa asıl neden alanlarıyla korunmalıdır.

## Uygulama arayüzünde gösterilecekler

Onay ekranı hedef işlemi, ilgili kayıt kimliğini, değişecek alanları ve kararın dayandığı güncel veriyi göstermelidir. Ham veritabanı izinleri veya iç SQL logları son kullanıcı için gerekli değildir. Uygulama sonrası kesin başarı, kesin rollback ve belirsiz sonuç ayrı durumlar olmalıdır. Bu ayrım, müşterinin aynı eylemi iki kez istemesini ve işletmenin yanlış başarı mesajı vermesini azaltır.

## Kaynaklar

- [StarDataParadiseServer / compatibility/ai/README.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/compatibility/ai/README.md)
- [StarDataParadiseServer / contracts/sql/native-sql-v1.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/contracts/sql/native-sql-v1.md)
