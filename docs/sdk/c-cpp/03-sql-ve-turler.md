---
title: "C/C++ SDK — Parametreli SQL ve sonuç okuma"
slug: "/sdk/c-cpp/03-sql-ve-turler"
---

# C/C++ SDK — Parametreli SQL ve sonuç okuma

**Kapsam:** Özgün wire SQL; `sql_crud_v1` desteği ve uygun nesne izinleri gerekir.

C ABI SQL kaynağını, parametre tipi bildirimlerini ve gerçek değerleri ayrı girdiler olarak taşır. Bu ayrım hem SQL injection'ı önlemek hem büyük tamsayı ve exact decimal değerlerini kaybetmemek için önemlidir. Parametre adları SQL'de `:id`, JSON nesnesinde `id` olarak görünür.

## Hazırlama ve çalıştırma

```cpp
sdp::client::Statement statement(
    connection,
    "SELECT id, ad, fiyat, stok FROM main.public.urunler WHERE id = :id",
    R"({"id":{"type":"BIGINT"}})"
);
auto execution = statement.execute(R"({"id":{"t":"i64","v":"101"}})");
std::cout << execution.view() << '\n';
```

`execution` satırların tamamı değildir. SELECT yanıtındaki `result_id` açık okuyucuyu tanımlar; `columns` metadata'sı da gelebilir. Bu JSON'u uygulamanızdaki JSON ayrıştırıcısıyla okuyun. SDK'nın C++ sarmalayıcısına kaynakta bulunmayan bir `fetchAll()` yöntemi eklenmiş gibi davranmayın; açık sonuç `sdp_fetch` ile tüketilir.

## Kayıpsız değer temsili

| SQL değeri | Tip bildirimi | Değer JSON'u |
| --- | --- | --- |
| BIGINT 101 | `{"type":"BIGINT"}` | `{"t":"i64","v":"101"}` |
| TEXT | `{"type":"TEXT"}` | `{"t":"text","v":"Klavye"}` |
| DECIMAL(12,2) 750.00 | `{"type":"DECIMAL","precision":12,"scale":2}` | `{"t":"decimal","unscaled":"75000","scale":2}` |
| SQL NULL | Hedefin gerçek SQL tipi | `{"t":"null"}` |

Decimal `unscaled` katsayısı ile scale birlikte anlamlıdır. `75000 / 10^2 = 750.00` olur. Özellikle parasal değerlerde önce `double` üretip sonra JSON'a çevirmek yerine ondalık metinden veya uygulamanın exact decimal türünden bu temsili oluşturun. JSON'u kullanıcı metniyle elle birleştirmek yerine bir serializer kullanın.

## Fetch döngüsünün sözleşmesi

1. Execute yanıtındaki opak `result_id` değerini çıkarın; onun baytlarını uzunlukla saklayın.
2. `sdp_fetch(connection, result_id, batch_rows, &buffer, &error)` çağırın. Batch boyutu 1–1024 aralığındadır.
3. Yanıttaki tipli satırları okuyun. Her result set'in ilk batch'inde sütun ve varsa set adı bilgisi bulunur.
4. `end_of_set` geldiğinde o set biter; PL/SQL çağrısında başka set olabilir.
5. `end_of_results` true olduğunda okuyucu serbest bırakılır. Daha erken çıkıyorsanız `sdp_result_cancel` çağırın.
6. Her batch buffer'ını `sdp_buffer_free` ile bırakın. Sonra statement'ı kapatın.

`batch_index` her set'te sıfırdan başlar; `result_set` setler arasında artar. Bu alanları korumak, OUT parametreleri ile cursor sonuçlarını yanlışlıkla tek tablo gibi birleştirmeyi engeller. Aynı bağlantıda aynı anda bir açık okuyucu bulunduğunu hesaba katın.

## Yazma ve affected_rows

INSERT/UPDATE/DELETE yanıtında `affected_rows` iş sonucunu yorumlamanıza yardım eder. Koşullu stok azaltma örneğinde sıfır satır değişmesi “ürün yok” veya “yeterli stok yok” durumlarını ifade edebilir. İş kuralınızı bu sonuca bağlayın. Açık transaction içindeki execute çağrısı için request token boş bırakılır; token commit çağrısına verilir. Bağımsız autocommit yazmasında her yazmaya özel token gerekir.

## Bileşik PL/SQL türleri

RECORD alanları sıralı `fields`, COLLECTION öğeleri `items` dizisiyle kodlanır. İç tür bilgisi korunur; bütün record'u metne dönüştürmek eşdeğer değildir. ABI belgesi bileşik değer için 64 KiB, en fazla sekiz bileşik katman ve toplam 2048 tipli düğüm gibi sınırlar tanımlar. Büyük veri aktarımında bu sözleşmeyi aşıp tek dev parametre göndermek yerine işi uygun parçalara bölün.

## Kaynaklar

- [StarDataParadiseDLLler / ABI.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseDLLler/blob/3199235c9641733332e9b8c82f9e875170c4eedb/ABI.md)
- [StarDataParadiseDLLler / include/StarDataParadiseDLLler.hpp](https://github.com/ParadiseIncDevelopers/StarDataParadiseDLLler/blob/3199235c9641733332e9b8c82f9e875170c4eedb/include/StarDataParadiseDLLler.hpp)
