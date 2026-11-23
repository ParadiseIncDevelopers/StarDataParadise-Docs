---
title: "C/C++ SDK — Bağlantı ve bellek sahipliği"
slug: "/sdk/c-cpp/02-baglanti-bellek"
---

# C/C++ SDK — Bağlantı ve bellek sahipliği

**Kapsam:** C ABI 1; TLS wire v1.

C ABI çağrıları uzunlukla tanımlanmış UTF-8 alanlar kullanır. `sdp_text` içindeki `size`, sonlandırıcı NUL'ı içermez. SDK çağrı sürerken giriş belleğinin geçerli kalmasını bekler. Çıktı belleği ise DLL tarafından ayrılır; uygulamanın `free` veya `delete` işleviyle bırakılmaz.

## Bağlantı seçenekleri

```cpp
using sdp::client::text;
sdp_open_options options{};
options.struct_size = sizeof(options);
options.abi_version = SDP_ABI_VERSION;
options.address = text("127.0.0.1");
options.port = 7443;
options.server_name = text("localhost");
options.ca_file = text("C:/SDP/lab/ca.pem");
options.username = text(user);
options.password = text(password);
options.timeout_ms = 5000;
sdp::client::Connection connection(options);
connection.health();
std::cout << connection.capabilities().view() << '\n';
```

Bu kesitte `user` ve `password` çağrı boyunca yaşayan uygulama girdileridir. Yapıyı sıfırlamak ayrılmış alanların rastgele değer taşımamasını sağlar. `struct_size` ve `abi_version` zorunlu uyumluluk bilgileridir. `address` C ABI'de sayısal IPv4/IPv6 adresidir; `server_name` TLS doğrulamasında kullanılan DNS adı veya IP'dir. CLI'ın DNS kabul eden host seçeneğiyle C ABI alanını karıştırmayın.

## C tarafında temel kontrol

```c
sdp_connection connection = 0;
sdp_error error = {0};
sdp_buffer capabilities = {0};
sdp_status status = sdp_open(&options, &connection, &error);
if (status != SDP_OK) {
    fprintf(stderr, "code=%d sqlstate=%s\n", error.code, error.sqlstate);
    return 1;
}
status = sdp_get_capabilities(connection, &capabilities, &error);
if (status == SDP_OK) {
    fwrite(capabilities.data, 1, capabilities.size, stdout);
}
sdp_buffer_free(&capabilities);
sdp_close(connection, NULL);
```

Tam derlenebilir bağlantı örneği [main.c](/downloads/ornekler/c/main.c) dosyasındadır. Buffer'ın NUL ile bitmesi beklenmez; `printf("%s", ...)` yerine uzunlukla yazmak gerekir. Hata mesajını incelerken durum kodu, SQLSTATE, konum ve correlation alanlarını koruyun; yalnız serbest metin üzerinden karar vermeyin.

## C++ RAII'nin sınırı

`Buffer::view()` sahip olunan buffer'ın içindeki belleğe bakar. Buffer yok olduğunda view geçersizleşir. Örneğin geçici bir `connection.capabilities()` sonucundan `string_view` alıp daha sonra kullanmak doğru değildir; önce Buffer nesnesini saklayın veya veriyi kendi string'inize kopyalayın.

Benzer biçimde `Statement` nesnesi bağlantıdan önce bitirilmelidir. Transaction ve açık sonuçların bağlantının yaşam süresinden daha uzun yaşamasına izin vermeyin. C++ scope sıralaması, kaynakların ters sırada bırakılması için doğal bir düzen sağlar.

## Eşzamanlılık ve iptal

Bağlantı başına ağ çağrılarını sıralayın. Bir bağlantıyı iki thread'de sorgu için paylaşmak yerine her işçi için ayrı bağlantı açın. Farklı bağlantılar bağımsızdır. `sdp_cancel` yerel devam eden ağ işinin iptalini ister; istek zaten tamamlandıysa başarılı sonuç korunur. Timeout, iptal veya taşıma kopmasından sonra mevcut stream yeniden kullanılmaz; yeni bağlantı açılır.

`sdp_health_async` callback'i SDK worker thread'inde çağrılır. Callback içindeki `error` işaretçisi yalnız callback süresince geçerlidir; gerekiyorsa içeriği kopyalayın. Callback içinde bağlantıyı kapatmak veya bir sonraki ağ işlemini başlatmak kaynak sözleşmesine uygun değildir. Kütüphaneyi unload etmeden önce tüm bağlantıların, callback'lerin ve buffer'ların yaşam döngüsü tamamlanmalıdır.

## Kaynaklar

- [StarDataParadiseDLLler / ABI.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseDLLler/blob/3199235c9641733332e9b8c82f9e875170c4eedb/ABI.md)
- [StarDataParadiseDLLler / include/StarDataParadiseDLLler.h](https://github.com/ParadiseIncDevelopers/StarDataParadiseDLLler/blob/3199235c9641733332e9b8c82f9e875170c4eedb/include/StarDataParadiseDLLler.h)
- [StarDataParadiseDLLler / include/StarDataParadiseDLLler.hpp](https://github.com/ParadiseIncDevelopers/StarDataParadiseDLLler/blob/3199235c9641733332e9b8c82f9e875170c4eedb/include/StarDataParadiseDLLler.hpp)
