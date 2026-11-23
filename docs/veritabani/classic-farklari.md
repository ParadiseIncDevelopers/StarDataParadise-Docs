---
title: "Original wire SQL ile Classic/native SQL farkları"
slug: "/veritabani/classic-farklari"
---

# Original wire SQL ile Classic/native SQL farkları

StarDataParadise dokümanlarında aynı ürün adı altında birden çok bağlantı ve yürütme yolu görülür. Bir örneği uygulamadan önce hangi yolda olduğunuzu bilmeniz gerekir. Bağlantının başarılı olması, belirli bir SQL sözdiziminin veya yönetim özelliğinin aynı anlama geldiğini tek başına göstermez.

Bu rehberin SQL ve veritabanı öğreticilerinin varsayılanı **original wire v1 motorudur**. SDK'ların native SQL bölümleri ise ayrı bir bağlantı/oturum modelini anlatır.

## Yolların karşılaştırması

| Konu | Original wire v1 SQL | Classic / native SQL yolu |
| --- | --- | --- |
| Yürütme temeli | StarDataParadise original SQL motoru | MySQL tabanlı Classic engine ve ilgili entegrasyon |
| Temel bağlam | main.public | Classic database/schema düzeni |
| Üç parçalı ad | database.schema.table | Aynı ad çözümlemesi varsayılmaz |
| Bağlama sözleşmesi | Wire SQL'de tipli named `:name`; JDBC arayüzü `?` sunabilir | Native API'de positional `?` |
| Transaction kontrolü | SDK/protokol, CLI ters eğik çizgili komutlar | Native transaction/commit API ve Classic davranışı |
| SQL DECIMAL sınırı | Precision en çok 38 | Native sözleşmede precision en çok 65, scale en çok 30 |
| TIME | Gün içindeki saat | Native değer modeli işaretli ve 24 saati aşan süreyi taşıyabilir |
| Yönetim yetenekleri | sql_crud_v1, history_v1 vb. capability'ler | native_sql_v1 ve özelliklere özgü capability'ler |
| AI SQL | Bu öğreticinin CRUD kapsamı değil | Native AI/Knowledge akışının ilgili yolu |

Java JDBC veya .NET gibi bir SDK adı tek başına hangi yolda olunduğunu göstermez. Örneğin aynı pakette normal bağlantı ve `SdpNativeConnection` gibi ayrı native arayüz bulunabilir. Çalışan örneğin import, sınıf ve bağlantı seçeneklerini birlikte izleyin.

## Aynı veritabanı dosyası varsaymayın

`StarDataParadiseServer.exe` ile original engine ve `mysqld.exe` ile Classic engine farklı yürütülebilirlerdir. Native wire köprüsü, ayrı Classic oturumu açan bir erişim yolu olabilir. Aynı ürün çatısı altında bulunmaları birinde oluşturulan `main.public.urunler` tablosunun ötekinde kendiliğinden görünmesi anlamına gelmez.

SDK native örneğinde `sdp_lab.urunler` kullanılıyorsa Classic tarafta buna uygun tablo oluşturulmuş olmalıdır. Original lab dosyasındaki `public.urunler` adını hiç düşünmeden native'e taşımayın.

## Ayrı laboratuvar kurulumu

Original öğretici için [01–03 numaralı dosyaları](laboratuvar.md), Classic/native için [04–06 numaralı dosyaları](native-laboratuvar.md) kullanın. Classic kurulumunda tam ad `sdp_lab.urunler` biçimindedir. DDL ve seed adımları ayrı yürütülür; bütün schema kurulumunun bir kullanıcı transaction'ıyla geri alınacağı varsayılmaz.

## Bir söz dizimini port etmek

Original örnekte:

~~~sql
SELECT id, ad FROM public.urunler WHERE id = :id;
~~~

Native istemci örneği aynı ihtiyacı `sdp_lab.urunler` gibi Classic tarafta mevcut bir nesne ve `?` ile ifade edebilir. Burada yalnız parametre işareti değil, tip eşleme, result yaşam döngüsü, autocommit varsayılanı ve hata modeli de değişir.

Original öğreticide SELECT LIMIT/OFFSET, LIKE, IN veya BETWEEN kullanılmaması, bütün StarDataParadise yürütme yollarının bu komutları reddettiği anlamına gelmez. Bu, original parser'da doğrulanmış sözdizimini öğretme tercihidir. Classic SQL kapsamını o motorun ve kurulu entegrasyon sürümünün kaynaklarıyla doğrulayın.

## Native oturum sınırı

Native SQL sözleşmesi aynı authenticated actor'a bağlı ayrı Classic bağlantısı kullanır. Native oturum açıldıktan sonra eski CRUD statement/result handle'larıyla işlem karıştırılamaz. Bir connection nesnesinde iki API ailesini dönüşümlü çalıştırma varsayımı doğru değildir.

Native API tek SQL ifadesi alır; SDK çağrısına `DELIMITER` komutu eklenmez. Prosedür gövdesi gerekiyorsa tek ifade olarak iletilir. Native SQL metni, parametre sayısı, sonuç seti ve frame/chunk sınırları ayrı sözleşmede tanımlıdır.

## Native dil özellikleriyle devam

İlgili native dil capability\'si açık sürümde [EXCLUDE/REPLACE, QUALIFY, BY NAME ve pipeline](../sql/native-kisa-sql.md) ile [LET, kısa fonksiyon gövdesi ve FOR cursor](../sql/native-kisa-plsql.md) bölümlerini takip edin. Bunlar ertelenmiş HIST/JOB önerilerinden ayrı, native kaynakta kabul kaydı bulunan özelliklerdir.

## Hata ve retry farkı

Original wire commit sonucu token üzerinden sorgulanabilir. Native AI commit işlemi ise SQL değişikliklerini kaydetmiş fakat AI sonucu bekleme aşamasında timeout vermiş olabilir. Native hatada `commit_state`, `run_id` veya `run_state` gibi bilgiler önem taşır. Sırf timeout görüldü diye tüm SQL'i tekrar çalıştırmak güvenli değildir.

Bu nedenle SDK seçerken yalnız “hangi dili kullanıyorum?” sorusunu değil, “hangi motor/oturum yolunu, hangi capability ve commit davranışını kullanıyorum?” sorusunu da cevaplayın. Bu kararın ardından ilgili SDK rehberindeki kurulumu ve örnekleri aynı profil içinde takip edin.

**Kaynaklar:** [Server bileşenleri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/README.md), [native SQL sözleşmesi](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/contracts/sql/native-sql-v1.md), [original SQL grameri](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/sql/SQL.ebnf).
