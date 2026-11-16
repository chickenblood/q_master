import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/near_me/near_me_tab.dart';
import 'package:q_master/ui/adaptive_icons.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class _WebViewPlatform extends WebViewPlatform {
  late _WebViewController controller;
  late _NavigationDelegate delegate;

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) => controller = _WebViewController(params);

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) => delegate = _NavigationDelegate(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) => _WebViewWidget(params);
}

class _WebViewController extends PlatformWebViewController {
  _WebViewController(super.params) : super.implementation();

  Uri? url;
  Color? backgroundColor;
  int reloadCount = 0;
  final scripts = <String>[];

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    url = params.uri;
  }

  @override
  Future<void> setBackgroundColor(Color color) async {
    backgroundColor = color;
  }

  @override
  Future<void> runJavaScript(String javaScript) async {
    scripts.add(javaScript);
  }

  @override
  Future<void> reload() async {
    reloadCount++;
  }
}

class _NavigationDelegate extends PlatformNavigationDelegate {
  _NavigationDelegate(super.params) : super.implementation();

  late PageEventCallback onPageFinished;

  @override
  Future<void> setOnPageFinished(PageEventCallback callback) async {
    onPageFinished = callback;
  }

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback callback,
  ) async {}
}

class _WebViewWidget extends PlatformWebViewWidget {
  _WebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const Text('WebView');
}

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('Near Me follows the split theme on $platform', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final previousPlatform = WebViewPlatform.instance;
      final webView = _WebViewPlatform();
      WebViewPlatform.instance = webView;
      addTearDown(() {
        if (previousPlatform != null) {
          WebViewPlatform.instance = previousPlatform;
        }
      });
      final brightness = ValueNotifier(Brightness.dark);
      addTearDown(brightness.dispose);

      await tester.pumpWidget(
        legacy.MaterialApp(
          theme: legacy.ThemeData(
            brightness: Brightness.light,
            platform: platform,
          ),
          localizationsDelegates: [
            ...L10n.localizationsDelegates,
            material.GlobalMaterialLocalizations.delegate,
            cupertino.GlobalCupertinoLocalizations.delegate,
          ],
          builder: (_, child) => ValueListenableBuilder<Brightness>(
            valueListenable: brightness,
            builder: (_, value, _) => material.Theme(
              data: material.ThemeData(
                brightness: value,
                platform: platform,
                appBarTheme: const material.AppBarTheme(
                  backgroundColor: Color(0x00000000),
                ),
              ),
              child: child!,
            ),
          ),
          home: const NearMeTab(),
        ),
      );
      await tester.pumpAndSettle();
      expect(webView.controller.url, Uri.parse('https://f3near.me'));
      expect(webView.controller.backgroundColor, const Color(0xff000000));
      expect(webView.controller.scripts.last, contains('if (!true)'));

      webView.delegate.onPageFinished('https://f3near.me');
      expect(
        webView.controller.scripts.last.contains('--ion-safe-area-top'),
        platform == TargetPlatform.android,
      );

      final context = tester.element(find.byType(NearMeTab));
      await tester.tap(find.byIcon(AdaptiveIcons.refresh(context)));
      expect(webView.controller.reloadCount, 1);

      brightness.value = Brightness.light;
      await tester.pumpAndSettle();
      expect(webView.controller.backgroundColor, const Color(0xffffffff));
      expect(webView.controller.scripts.last, contains('if (!false)'));
    });
  }
}
