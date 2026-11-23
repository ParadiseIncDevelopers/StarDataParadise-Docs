---
title: "C/C++ SDK — Paket ve derleme"
slug: "/sdk/c-cpp/01-kurulum"
---

# C/C++ SDK — Paket ve derleme

**Kapsam:** Native SDK 0.4.1, C ABI 1, Windows x64, özgün wire v1.

Bu SDK'nın adındaki “Native”, C/C++ DLL dağıtımını ifade eder. Managed SDK'lardaki ayrı `native SQL` bağlantı ailesiyle aynı kavram değildir. 0.4.1 C başlığında bulunmayan bir native AI bağlantı metodunu, ürün adından hareketle var saymayın. Bu rehber yayımlanan C ABI ve C++20 sarmalayıcıyı anlatır.

## Dağıtımın içeriği

Kaynak README, Windows x64 Release arşivini `StarDataParadiseDLLler-0.4.1-win-x64.zip` olarak tanımlar. Paket DLL, import library, C/C++ başlıkları, CMake yapılandırması, wire sözleşmesi ve C++ örneği içerir. EXE'nin 64 bit mimarisi ile DLL ve MSVC çalışma zamanı uyumlu olmalıdır. Yalnız `.h` dosyasını projeye kopyalamak link ve çalışma zamanı bağımlılığını tamamlamaz.

ZIP bütünlük değerini teslim kaydıyla karşılaştırın. Başlık ve binary'yi farklı sürümlerden birleştirmeyin. Ürün sürümü `sdp_library_version()`, ABI sürümü `sdp_abi_version()` ile ayrı okunur; 0.4.1 ürün sürümü ile ABI 1 farklı numaralandırmalardır.

## CMake tüketici projesi

```cmake
cmake_minimum_required(VERSION 3.24)
project(sdp_cpp_lab LANGUAGES CXX)
find_package(StarDataParadiseDLLler 0.4.1 EXACT CONFIG REQUIRED)
add_executable(sdp_cpp_lab main.cpp)
target_compile_features(sdp_cpp_lab PRIVATE cxx_std_20)
target_link_libraries(sdp_cpp_lab PRIVATE StarDataParadise::StarDataParadiseDLLler)
```

Buradaki CMake asgari değeri eğitim tüketicisinin seçimidir. Aşağıda gösterilen Visual Studio 2026 generator akışı için kaynak README'deki **CMake 4.2.2** ve uygun Visual Studio 2026 araç zincirini kullanın; dosyadaki 3.24 asgarisi bu yeni generator'ın o sürümde bulunduğu iddiası değildir. Örnek tüketiciyi paketle derleme:

```powershell
cmake -S . -B build -G "Visual Studio 18 2026" -A x64 -DCMAKE_PREFIX_PATH="C:/SDP/native-sdk"
cmake --build build --config Release
```

Çalıştırırken `bin/StarDataParadiseDLLler.dll` EXE'nin yanında veya uygulamanızın güvenilir DLL arama yolunda bulunmalıdır. Bir geliştirme makinesinde PATH sayesinde çalışan uygulama, hedef makinede aynı bağımlılığı bulamayabilir; dağıtımın parçası olarak ele alın.

## C ile C++ arasındaki seçim

C arayüzü durum kodu, çağıranın ayırdığı `sdp_error`, bağlantı handle'ı ve DLL'in ürettiği buffer'larla çalışır. Her başarılı tahsisin ne zaman bırakıldığını sizin kodunuz takip eder. C++ başlığı `Connection`, `Statement`, `Transaction` ve `Buffer` sınıflarıyla bu sahipliği scope'a bağlar. Sınıflar kopyalanabilir kaynaklar gibi kullanılmaz; move desteği vardır.

| Kaynak | C'de bitirme | C++ karşılığı |
| --- | --- | --- |
| Bağlantı | `sdp_close` | `Connection::close` / destructor |
| Yanıt tamponu | `sdp_buffer_free` | `Buffer` |
| Hazır ifade | `sdp_statement_close` | `Statement` |
| Açık transaction | commit veya rollback | `Transaction`; scope çıkışında rollback denemesi |
| Sonuç okuyucusu | Sonuna kadar fetch veya `sdp_result_cancel` | C API üzerinden açık sonuç yaşam döngüsü |

## İlk doğrulama

Önce sağlık, oturum ve capability çağrılarını çalıştırın. Bağlantı oluşmadan SQL hatası aramayın. Sonra eğitim şemasında salt okunur sorguya geçin; yazma akışı için transaction sayfasını tamamlayın. Tam C bağlantı örneği ve C++ transaction örneği paket içindeki `ornekler/c` ve `ornekler/cpp` dizinlerinde bulunur. Bu dosyalar ürün SDK paketini içermeyen tüketici örnekleridir.

## Kaynaklar

- [StarDataParadiseDLLler / README.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseDLLler/blob/3199235c9641733332e9b8c82f9e875170c4eedb/README.md)
- [StarDataParadiseDLLler / ABI.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseDLLler/blob/3199235c9641733332e9b8c82f9e875170c4eedb/ABI.md)
- [StarDataParadiseDLLler / include/StarDataParadiseDLLler.hpp](https://github.com/ParadiseIncDevelopers/StarDataParadiseDLLler/blob/3199235c9641733332e9b8c82f9e875170c4eedb/include/StarDataParadiseDLLler.hpp)
