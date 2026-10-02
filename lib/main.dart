import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UcuzGetirApp());
}

class UcuzGetirApp extends StatelessWidget {
  const UcuzGetirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ucuzgetir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const WebViewHome(),
    );
  }
}

class WebViewHome extends StatefulWidget {
  const WebViewHome({super.key});

  @override
  State<WebViewHome> createState() => _WebViewHomeState();
}

class _WebViewHomeState extends State<WebViewHome> {
  late final WebViewController _controller;
  bool _isLoading = true;

  static const String _homeUrl = 'https://www.ucuzgetir.com';

  static const List<String> _externalSchemes = [
    'tel',
    'mailto',
    'sms',
    'whatsapp',
    'intent',
  ];

  static const List<String> _externalHosts = ['wa.me', 'api.whatsapp.com'];

  static const String _mobileSearchSubmitFixScript = '''
    (function() {
      var input = document.querySelector('#txturunadi');
      if (!input || !input.form) return;

      var form = input.form;
      if (form.dataset.mobileSearchSubmitFixAttached === 'true') return;
      form.dataset.mobileSearchSubmitFixAttached = 'true';
      var navigationStarted = false;

      function openSearch(event) {
        var query = input.value;
        if (!query.trim()) return;

        event.preventDefault();
        event.stopImmediatePropagation();
        if (navigationStarted) return;

        navigationStarted = true;
        window.location.assign('/?urunadi=' + encodeURIComponent(query));
      }

      document.addEventListener('click', function(event) {
        var target = event.target;
        var button = target && target.closest ? target.closest('#btnara') : null;
        if (button && button.form === form) openSearch(event);
      }, true);

      form.addEventListener('submit', openSearch, true);
    })();
  ''';

  // Görselleri hızlandırma scripti (ASP.NET PostBack uyumlu)
  static const String _imageSpeedOptimizerScript = '''
    (function() {
      function loadAllImagesFast() {
        const images = document.querySelectorAll('img[data-src], img[loading="lazy"]');
        images.forEach(img => {
          if (img.dataset.src) {
            img.src = img.dataset.src;
            img.removeAttribute('data-src');
          }
          img.setAttribute('loading', 'eager');
        });
      }
      loadAllImagesFast();
      
      // AJAX güncellemelerinde de tekrar tetikle
      if (typeof Sys !== 'undefined' && Sys.WebForms && Sys.WebForms.PageRequestManager) {
        var prm = Sys.WebForms.PageRequestManager.getInstance();
        if (prm && !prm._imgOptAttached) {
          prm._imgOptAttached = true;
          prm.add_endRequest(function () {
            loadAllImagesFast();
          });
        }
      }
    })();
  ''';

  void _injectScripts() {
    _controller.runJavaScript(_mobileSearchSubmitFixScript);
    _controller.runJavaScript(_imageSpeedOptimizerScript);
  }

  @override
  void initState() {
    super.initState();

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }

            // Sayfa yüklendiğinde script'leri çalıştır
            _injectScripts();

            // ASP.NET Session / Auth Cookie'lerini diske yaz
            _flushCookies();
          },
          onNavigationRequest: (NavigationRequest request) {
            final decodedUrl = Uri.decodeFull(request.url);
            final uri = Uri.tryParse(decodedUrl);

            if (uri == null) return NavigationDecision.navigate;

            final scheme = uri.scheme.toLowerCase();
            final host = uri.host.toLowerCase();

            final isExternalScheme = _externalSchemes.contains(scheme);
            final isExternalHost = _externalHosts.any((h) => host.contains(h));

            if (isExternalScheme || isExternalHost) {
              _openExternally(Uri.parse(request.url));
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    // Android Özel Konfigürasyonları
    if (controller.platform is AndroidWebViewController) {
      final androidController = controller.platform as AndroidWebViewController;

      // 1. Medya Otomatik Oynatma
      androidController.setMediaPlaybackRequiresUserGesture(false);

      // 2. Platform İzinleri (Kamera / Dosya Yükleme Desteği)
      androidController.setOnPlatformPermissionRequest((
        PlatformWebViewPermissionRequest request,
      ) {
        request.grant();
      });
    }

    _controller = controller;
    _controller.loadRequest(Uri.parse(_homeUrl));
  }

  // Çerezlerin Android diskiyle senkronizasyonu
  Future<void> _flushCookies() async {
    try {
      final cookieManager = WebViewCookieManager();
      await cookieManager.setCookie(
        const WebViewCookie(
          name: 'app_sync',
          value: '1',
          domain: 'ucuzgetir.com',
          path: '/',
        ),
      );
    } catch (e) {
      debugPrint('Cookie sync hatası: $e');
    }
  }

  Future<void> _openExternally(Uri uri) async {
    try {
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
      );

      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Harici URL açılamadı: $e');
    }
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              // Ana WebView Katmanı
              WebViewWidget(controller: _controller),

              // Yumuşak Geçişli Yüklenme Göstergesi
              IgnorePointer(
                ignoring: !_isLoading,
                child: AnimatedOpacity(
                  opacity: _isLoading ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    color: Colors.white,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
