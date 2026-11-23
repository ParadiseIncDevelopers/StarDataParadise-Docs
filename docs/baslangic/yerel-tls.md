---
title: "Yerel eğitim için TLS sertifikaları"
slug: "/baslangic/yerel-tls"
---

# Yerel eğitim için TLS sertifikaları

**Kapsam:** Yeni, yalnız localhost üzerinde çalışan eğitim instance'ı. OpenSSL 3.5 komutları.

Sunucu `server-chain.pem` ve `server-key.pem` dosyalarına, istemci ise CA sertifikasına ihtiyaç duyar. Yönetilen bir ortamda bunları yöneticinizden alın. Aşağıdaki akış kendi bilgisayarınızdaki boş eğitim dizini için ayrı bir CA oluşturur; mevcut sertifikaları değiştirmez. OpenSSL kurulu ve PATH'te erişilebilir olmalıdır.

## Dizini ve anahtarları hazırlayın

PowerShell'de yeni eğitim dizininde çalışın. Komutlardan biri hata verirse sonraki adıma geçmeyin.

```powershell
New-Item -ItemType Directory -Path C:\SDP\lab\tls
Set-Location C:\SDP\lab\tls
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out ca-key.pem
if ($LASTEXITCODE -ne 0) { throw 'CA anahtari olusturulamadi' }
openssl req -new -x509 -key ca-key.pem -sha256 -days 30 -out ca.pem -subj '/CN=SDP Egitim CA' -addext 'basicConstraints=critical,CA:TRUE' -addext 'keyUsage=critical,keyCertSign,cRLSign'
if ($LASTEXITCODE -ne 0) { throw 'CA sertifikasi olusturulamadi' }
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -out server-key.pem
if ($LASTEXITCODE -ne 0) { throw 'Server anahtari olusturulamadi' }
openssl req -new -key server-key.pem -out server.csr -subj '/CN=localhost'
if ($LASTEXITCODE -ne 0) { throw 'Sertifika istegi olusturulamadi' }
```

`ca-key.pem` CA'nın özel anahtarıdır; istemciye verilmez. `server-key.pem` Server'ın özel anahtarıdır. Dosya erişimini bu eğitim ortamını işleten kullanıcıyla sınırlandırın. Bu örnek kısa süreli, 30 günlük sertifikalar üretir; sona erdiğinde aynı güvenlik kontrollerini koruyarak yenileyin.

## Sunucu adını sertifikaya ekleyin

```powershell
@'
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:localhost,IP:127.0.0.1
'@ | Set-Content -Encoding ascii server-ext.ini

openssl x509 -req -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-chain.pem -days 30 -sha256 -extfile server-ext.ini
if ($LASTEXITCODE -ne 0) { throw 'Server sertifikasi imzalanamadi' }
openssl verify -CAfile ca.pem -verify_hostname localhost server-chain.pem
if ($LASTEXITCODE -ne 0) { throw 'Sertifika dogrulanamadi' }
Copy-Item ca.pem C:\SDP\lab\ca.pem
```

Beklenen doğrulama `server-chain.pem: OK` sonucudur. Bu kontrol dosyanın verilen CA ve adla eşleşmesini sınar; gerçek Server bağlantısı ayrıca CLI ile denenir. Üretilen dosyalar [kurulumdaki](kurulum.md) `tls/server-chain.pem` ve `tls/server-key.pem` yollarıyla eşleşir.

## İstemci ayarları

Bu yerel örnekte ağ adresi `127.0.0.1`, port `7443`, TLS adı `localhost`, CA dosyası `C:/SDP/lab/ca.pem` olarak kullanılabilir. Farklı DNS adıyla uzak bağlantı kuracaksanız sertifikayı o dağıtımın adı ve güven politikası için hazırlamanız gerekir. İstemciye özel anahtar vermeyin; yalnız CA sertifikası yeterlidir.

## Harici komut belgeleri

- [OpenSSL genpkey](https://docs.openssl.org/3.5/man1/openssl-genpkey/)
- [OpenSSL req](https://docs.openssl.org/3.5/man1/openssl-req/)
- [OpenSSL x509](https://docs.openssl.org/3.5/man1/openssl-x509/)
- [OpenSSL verify](https://docs.openssl.org/3.5/man1/openssl-verify/)

## Kaynaklar

- [StarDataParadiseServer / RUN.md](https://github.com/ParadiseIncDevelopers/StarDataParadiseServer/blob/f3cc7b2d3b3beb334706eef7cb3ad1b0b9e72242/RUN.md)
