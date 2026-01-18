import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/settings/settings_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class NearMeTab extends StatelessWidget {
  final controller = WebViewController()
    ..setJavaScriptMode(.unrestricted)
    ..setNavigationDelegate(
      NavigationDelegate(
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
  Widget build(BuildContext context) => PlatformScaffold(
    appBar: PlatformAppBar(
      leading: SettingsActionButton(),
      title: Text(
        L10n.of(context)!.nearMeTabTitle,
        textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.6),
      ),
      cupertino: (appBarContext, _) =>
          CupertinoNavigationBarData(backgroundColor: Colors.transparent),
    ),
    body: SafeArea(child: WebViewWidget(controller: controller)),
  );
}
