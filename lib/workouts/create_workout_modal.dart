import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:q_master/l10n/l10n.dart';

class ComposeWorkoutModal extends StatelessWidget {
  const ComposeWorkoutModal({super.key});

  @override
  Widget build(BuildContext context) => PlatformScaffold(
    appBar: PlatformAppBar(
      title: Text(L10n.of(context)!.createWorkoutDialogTitle),
      leading: PlatformIconButton(
        onPressed: () => Navigator.pop(context),
        materialIcon: Icon(Icons.close),
        cupertinoIcon: Icon(CupertinoIcons.xmark),
      ),
      trailingActions: [
        PlatformIconButton(
          onPressed: () {
            // Handle save action
            Navigator.pop(context);
          },
          materialIcon: Icon(Icons.check),
          cupertinoIcon: Icon(CupertinoIcons.check_mark),
        ),
      ],
    ),
    body: Center(child: Text('Workout composition UI goes here')),
  );
}
