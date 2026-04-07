import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../l10n/l10n.dart';
import '../ui/adaptive_icons.dart';

final class GenerateWorkoutSheet extends StatelessWidget {
  const GenerateWorkoutSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        cupertino: (appBarContext, _) => CupertinoNavigationBarData(
          backgroundColor: Colors.transparent,

          leading: PlatformIconButton(
            padding: EdgeInsets.only(right: 22),
            icon: Icon(AdaptiveIcons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            L10n.of(context)!.generateWorkoutDialogTitle,
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: 1.6),
          ),
        ),
      ),
      body: const Center(child: Text('Generate Workout Sheet Content')),
    );
  }
}
