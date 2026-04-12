import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../ui/adaptive_icons.dart';

final class CaptureVoiceInputDialog extends StatelessWidget {
  const CaptureVoiceInputDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        cupertino: (appBarContext, _) => CupertinoNavigationBarData(
          backgroundColor: Colors.transparent,
          leading: PlatformIconButton(
            padding: const EdgeInsets.only(right: 22),
            icon: Icon(AdaptiveIcons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: PlatformText('Capture Voice Input'),
        ),
        material: (appBarContext, _) => MaterialAppBarData(
          leading: PlatformIconButton(
            icon: Icon(AdaptiveIcons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: PlatformText('Capture Voice Input'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AdaptiveIcons.microphone,
              color: Colors.red.shade700,
              size: 72,
            ),
            const SizedBox(height: 20),
            PlatformText('Voice capture is coming next.'),
          ],
        ),
      ),
    );
  }
}
