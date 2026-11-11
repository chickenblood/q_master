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
  bool _isDark = false;

  late final WebViewController controller = WebViewController()
    ..setJavaScriptMode(.unrestricted)
    ..setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (_) {
          _applyTheme();
          // The page is Ionic and pads itself by env(safe-area-inset-top),
          // which Android WebView reports on phones with a status bar/cutout.
          // Flutter's SafeArea already accounts for it, so zero it out.
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

  // WKWebView evaluates `prefers-color-scheme` against the OS theme, not the
  // app's. Rewrite those media rules (and matchMedia) so the page follows the
  // in-app theme; also set the Ionic dark class for class-driven palettes.
  void _applyTheme() {
    controller.runJavaScript('''
(function() {
  var dark = $_isDark;
  var re = /prefers-color-scheme:\\s*(dark|light)/;
  var walk = function(rules) {
    for (var i = 0; i < rules.length; i++) {
      var r = rules[i];
      if (r.media && re.test(r.media.mediaText)) {
        var wantsDark = /dark/.test(r.media.mediaText);
        if (!r.__qmOrig) r.__qmOrig = r.media.mediaText;
        r.media.mediaText = (wantsDark === dark) ? 'all' : 'not all';
      }
      if (r.cssRules) walk(r.cssRules);
    }
  };
  window.__qmDark = dark;
  if (!window.__qmMatchMedia) {
    window.__qmMatchMedia = window.matchMedia.bind(window);
    window.matchMedia = function(q) {
      var m = /prefers-color-scheme:\\s*(dark|light)/.exec(q);
      var res = window.__qmMatchMedia(q);
      if (!m) return res;
      var matches = (m[1] === 'dark') === window.__qmDark;
      return new Proxy(res, {
        get: function(t, k) {
          if (k === 'matches') return matches;
          var v = t[k];
          return typeof v === 'function' ? v.bind(t) : v;
        }
      });
    };
  }
  var run = function() {
    for (var i = 0; i < document.styleSheets.length; i++) {
      try { walk(document.styleSheets[i].cssRules); } catch (e) {}
    }
    document.documentElement.classList.toggle('ion-palette-dark', dark);
    document.documentElement.style.colorScheme = dark ? 'dark' : 'light';
  };
  window.__qmApplyTheme = run;
  run();
  if (!window.__qmObserver) {
    window.__qmObserver = new MutationObserver(function() {
      window.__qmApplyTheme();
    });
    window.__qmObserver.observe(document.head || document.documentElement, {
      childList: true, subtree: true,
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
