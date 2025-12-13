import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:q_master/l10n/l10n.dart';

class ComposeWorkoutModal extends StatelessWidget {
  const ComposeWorkoutModal({super.key});

  Widget _content(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16.0),
    children: [
      Text(L10n.of(context)!.workoutNameFieldLabel),
      PlatformTextField(minLines: 5, maxLines: 5),
      const SizedBox(height: 16.0),
      Text(L10n.of(context)!.workoutWarmupFieldLabel),
      PlatformTextField(minLines: 5, maxLines: 5),
      const SizedBox(height: 16.0),
      Text(L10n.of(context)!.workoutThangFieldLabel),
      PlatformTextField(minLines: 5, maxLines: 5),
      const SizedBox(height: 16.0),
      Text(L10n.of(context)!.workoutMaryFieldLabel),
      PlatformTextField(minLines: 5, maxLines: 5),
    ],
  );

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
          icon: Icon(PlatformIcons(context).checkMark),
        ),
      ],
    ),
    body: SafeArea(child: _content(context)),
  );
}
