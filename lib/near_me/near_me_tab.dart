import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../l10n/l10n.dart';
import '../settings/settings_sheet.dart';
import '../ui/adaptive_app_bar.dart';
import '../ui/adaptive_scaffold.dart';

class NearMeTab extends StatefulWidget {
  const NearMeTab({super.key});

  @override
  State<NearMeTab> createState() => _NearMeTabState();
}

class _NearMeTabState extends State<NearMeTab> {
  bool? _isDark;

  late final WebViewController controller = WebViewController()
    ..setJavaScriptMode(.unrestricted)
    ..setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (_) => _applyTheme(),
        onPageFinished: (_) {
          // The page is Ionic and pads itself by env(safe-area-inset-top),
          // which Android WebView reports on phones with a status bar/cutout.
          // Flutter's SafeArea already accounts for it, so zero it out.
          _applyTheme();
          if (defaultTargetPlatform == TargetPlatform.android) {
            controller.runJavaScript(
              "document.documentElement.style.setProperty("
              "'--ion-safe-area-top', '0px');",
            );
          }
        },
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.startsWith('https://f3near.me/') ||
              request.url.startsWith('https://map.f3nation.com/') ||
              request.url.startsWith('https://f3-workout.firebaseapp.com/')) {
            return NavigationDecision.navigate;
          }
          // Don't follow external links inside the webview.
          debugPrint('Launching external URL: ${request.url}');
          launchUrl(
            Uri.parse(request.url),
            mode: LaunchMode.externalApplication,
          );
          return NavigationDecision.prevent;
        },
      ),
    )
    ..loadRequest(Uri.parse('https://f3near.me'));

  @override
  void initState() {
    super.initState();
    if (controller.platform is AndroidWebViewController) {
      (controller.platform as AndroidWebViewController)
          .setGeolocationPermissionsPromptCallbacks(
            onShowPrompt: (GeolocationPermissionsRequestParams request) async {
              return const GeolocationPermissionsResponse(
                allow: true,
                retain: true,
              );
            },
          );
    }
  }

  // The page is Ionic and its SPA can re-render and reset the theme after
  // load (and WKWebView follows the OS theme, not the app's), so enforce the
  // `ion-palette-dark` class with an observer rather than setting it once.
  void _applyTheme() {
    final isDark = _isDark ?? false;
    controller.runJavaScript('''
(function() {
  window.__qmDark = $isDark;
  var apply = function() {
    var dark = window.__qmDark;
    [document.documentElement, document.body].forEach(function(el) {
      if (el && el.classList.contains('ion-palette-dark') !== dark) {
        el.classList.toggle('ion-palette-dark', dark);
      }
    });
    document.documentElement.style.colorScheme = dark ? 'dark' : 'light';
  };
  window.__qmApplyTheme = apply;
  apply();
  if (!window.__qmThemeObserver) {
    window.__qmThemeObserver = new MutationObserver(function() {
      window.__qmApplyTheme();
    });
    window.__qmThemeObserver.observe(document.documentElement, {
      attributes: true, attributeFilter: ['class'], subtree: false,
    });
    document.addEventListener('DOMContentLoaded', function() {
      if (document.body) {
        window.__qmThemeObserver.observe(document.body, {
          attributes: true, attributeFilter: ['class'],
        });
      }
      window.__qmApplyTheme();
    });
  }
})();
''');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark != _isDark) {
      _isDark = isDark;
      controller.setBackgroundColor(isDark ? Colors.black : Colors.white);
      _applyTheme();
    }
    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) => AdaptiveScaffold(
    appBar: AdaptiveAppBar(
      leading: [settingsGlassBarItem(id: 'left-item', context: context)],
      title: Text(
        L10n.of(context)!.nearMeTabTitle,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.6),
      ),
      actions: [
        AdaptiveAppBarItem(
          icon: Icon(PlatformIcons(context).refresh),
          onPressed: () => controller.reload(),
        ),
      ],
    ),
    body: SafeArea(
      child: Padding(
        padding: adaptivePadding + const EdgeInsets.only(bottom: 4),
        child: WebViewWidget(controller: controller),
      ),
    ),
  );
}
