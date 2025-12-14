import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:q_master/l10n/l10n.dart';
import 'workout_auto_completions.dart';

class ComposeWorkoutModal extends StatelessWidget {
  final _verticalSpacing = const SizedBox(height: 16.0);
  final _warmupTextController = TextEditingController();
  final _thangTextController = TextEditingController();
  final _maryTextController = TextEditingController();

  ComposeWorkoutModal({super.key});

  Widget _content(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16.0),
    children: [
      PlatformText(L10n.of(context)!.workoutNameFieldLabel),
      PlatformTextField(expands: true, minLines: null, maxLines: null),
      _verticalSpacing,
      PlatformText(L10n.of(context)!.workoutWarmupFieldLabel),
      WorkoutAutocompleteTextField(
        textEditingController: _warmupTextController,
        minLines: 5,
        maxLines: 5,
      ),
      _verticalSpacing,
      PlatformText(L10n.of(context)!.workoutThangFieldLabel),
      WorkoutAutocompleteTextField(
        textEditingController: _thangTextController,
        minLines: 5,
        maxLines: 5,
      ),
      _verticalSpacing,
      PlatformText(L10n.of(context)!.workoutMaryFieldLabel),
      WorkoutAutocompleteTextField(
        textEditingController: _maryTextController,
        minLines: 5,
        maxLines: 5,
      ),
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
