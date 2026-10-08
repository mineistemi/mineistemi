# UcuzGetir iOS uygulaması

Uygulama, web sitesini tek ekranda sarmalamak yerine mağazanın ürün RSS kataloğundan beslenen yerel bir Flutter mağaza arayüzü sunar. Ürün arama, ürün ayrıntıları, cihazda saklanan favoriler ve yerel barkod tarama uygulama içindedir. Sepet, hesap girişi ve ödeme mevcut UcuzGetir web akışında tamamlanır; ödeme fiziksel ürünler içindir.

## Geliştirme

- Flutter ve Dart sürümleri `C:\flutter` toolchain’iyle eşleşmelidir.
- Paketleri kurmak için `flutter pub get` çalıştırın.
- Analiz ve test için `flutter analyze` ve `flutter test` çalıştırın.
- iOS bundle ID `com.ucuzgetir.app`; bu App Store Connect kaydıyla eşleşmelidir.
- Sürüm ve derleme numarası `pubspec.yaml` içindeki `version` alanından yönetilir; App Store’a her yüklemede derleme numarasını artırın.

## Appcircle ve iOS imzalama

1. Appcircle iş akışını Flutter proje köküne (`ucuzgetir_app`) bağlayın.
2. iOS scheme olarak `Runner`, hedef olarak iOS cihazı seçin.
3. App Store Connect’e gönderilecek her derlemede Apple Distribution sertifikası (`.p12`) ve `com.ucuzgetir.app` için App Store provisioning profile kullanın.
4. `.p12` parolasını, App Store Connect API anahtarını ve diğer sırları Appcircle’ın güvenli değişken/kimlik bilgisi alanlarında tutun; kaynak depoya veya bu uygulama paketine koymayın.
5. İmzalı `.ipa` dosyasını gerçek iPhone’da ve TestFlight üzerinden doğrulayın; hesap girişi, mağaza araması, barkod izni, sepet ve banka 3-D Secure ödeme dönüşlerini test edin.

## App Store gönderim kontrolü

- Kamera izni yalnızca kullanıcı barkod taramasını başlattığında istenir. Uygulama görüntüyü kaydetmez.
- Favoriler yalnızca cihazda saklanır; favorileri senkronize etmek için kullanıcı hesabı oluşturulmaz.
- Ürün kataloğu UcuzGetir sunucusundan HTTPS üzerinden okunur. Sepet, hesap ve ödeme mevcut mağazada tamamlanır; vergi/fatura/teslimat için gerekli kayıtlar fiziksel ürün siparişlerine aittir.
- Canlı Merchant akışı şu anda 1.272 ürünün tamamı için `resim_yok.svg` döndürüyor; ürün sayfaları ise `ResimKucult.ashx` üzerinden gerçek JPEG görseller sunuyor. Sunucu tarafındaki Merchant görsel eşlemesi bu aynı görsel uç noktasını kullanacak şekilde düzeltildi; backend güncellemesini yayınlayıp feed'deki görsel URL'lerini yeniden kontrol edin.
- Gizlilik politikası: `https://www.ucuzgetir.com/gizlilik-politikasi.aspx`.
- App Store Connect’te veri toplama/gizlilik beyanını uygulamanın gerçek davranışıyla eşleştirin ve mağaza ekran görüntülerini hazırlayın.
- Uygulamadaki Hesabım bölümünden oturum açmış kullanıcı `/HesapSil.aspx` üzerinden hesap silme talebini başlatabilir. Sunucu talebi müşteri hizmetlerine e-posta ile iletir; destek ekibi profili silme/anonimleştirme işlemini tamamlar ve yalnızca yasal olarak saklanması gereken sipariş/fatura kayıtlarını korur. Site ortamında `ORDER_ADMIN_EMAIL` veya `FIRMA_MAIL` alıcısı tanımlanmalı; SMTP gönderimi ve talebin destek ekibine ulaşıp işlendiği gerçek bir test hesabıyla doğrulanmalıdır.

Yerel katalog, ürün ayrıntıları, favoriler, arama ve barkod tarama, uygulamayı yalnızca web sitesini açan bir sarmalayıcı olmaktan çıkarır; yine de Apple inceleme kararı garanti edilemez. Özellikle hesap silme, gizlilik beyanı, fiyat/stok doğruluğu, ürün fotoğrafları ve ödeme dönüşleri gerçek hesap ve cihazlarla doğrulanmalıdır.
