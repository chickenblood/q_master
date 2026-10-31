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

class NearMeTab extends StatelessWidget {
  late final WebViewController controller = WebViewController()
    ..setJavaScriptMode(.unrestricted)
    ..setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (_) {
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

  NearMeTab({super.key}) {
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

  @override
  Widget build(BuildContext context) => AdaptiveScaffold(
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
