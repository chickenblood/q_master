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
  bool _invert = false;

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

  // The page only themes itself via `prefers-color-scheme`, i.e. the OS theme.
  // When the in-app theme differs from the OS theme, invert the page and then
  // re-invert media so photos and map tiles keep their original colors.
  void _applyTheme() {
    controller.runJavaScript('''
(function() {
  var id = '__qmInvert';
  var style = document.getElementById(id);
  if (!$_invert) {
    if (style) style.remove();
    return;
  }
  if (style) return;
  style = document.createElement('style');
  style.id = id;
  style.textContent =
    'html { filter: invert(1) hue-rotate(180deg); }' +
    'img, video, canvas, iframe { filter: invert(1) hue-rotate(180deg); }';
  document.head.appendChild(style);
})();
''');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final invert =
        isDark != (MediaQuery.platformBrightnessOf(context) == .dark);
    if (isDark != _isDark) {
      _isDark = isDark;
      controller.setBackgroundColor(isDark ? Colors.black : Colors.white);
    }
    if (invert != _invert) {
      _invert = invert;
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
