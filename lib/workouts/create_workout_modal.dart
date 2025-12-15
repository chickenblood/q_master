import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/model/workout.dart';
import 'workout_auto_completions.dart';

class ComposeWorkoutModal extends StatelessWidget {
  final _verticalSpacing = const SizedBox(height: 16.0);
  final _nameTextController = TextEditingController();
  final _warmupTextController = TextEditingController();
  final _thangTextController = TextEditingController();
  final _maryTextController = TextEditingController();

  ComposeWorkoutModal({super.key});

  Widget _content(BuildContext context) => ListView(
    shrinkWrap: true,
    physics: ClampingScrollPhysics(), // To allow drag-dismiss.
    padding: const EdgeInsets.all(16.0),
    children: [
      PlatformText(L10n.of(context)!.workoutNameFieldLabel),
      PlatformTextField(
        controller: _nameTextController,
        minLines: null,
        maxLines: null,
        // For some reason, expands = true crashes on Android.
        cupertino: (context, platform) =>
            CupertinoTextFieldData(expands: true, minLines: null),
      ),
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

  List<Exercise> _convertTextToExerciseList(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => Exercise(name: line))
        .toList();
  }

  bool get _workoutCreationEnabled {
    return _nameTextController.text.isNotEmpty &&
        (_warmupTextController.text.isNotEmpty ||
            _thangTextController.text.isNotEmpty ||
            _maryTextController.text.isNotEmpty);
  }

  void _createWorkout(BuildContext context) {
    final workout = Workout(
      name: _nameTextController.text,
      date: DateTime.now(),
      warmup: _convertTextToExerciseList(_warmupTextController.text),
      thang: _convertTextToExerciseList(_thangTextController.text),
      mary: _convertTextToExerciseList(_maryTextController.text),
    );
    Navigator.pop(context, workout);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameTextController.text = L10n.of(context)!.defaultWorkoutName;
    });
    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(L10n.of(context)!.createWorkoutDialogTitle),
        cupertino: (_, _) =>
            CupertinoNavigationBarData(backgroundColor: Colors.transparent),
        leading: PlatformIconButton(
          onPressed: () => Navigator.pop(context),
          materialIcon: Icon(Icons.close),
          cupertinoIcon: Icon(CupertinoIcons.xmark),
        ),
        trailingActions: [
          ListenableBuilder(
            listenable: Listenable.merge([
              _nameTextController,
              _warmupTextController,
              _thangTextController,
              _maryTextController,
            ]),
            builder: (_, _) => PlatformIconButton(
              onPressed: _workoutCreationEnabled
                  ? () => _createWorkout(context)
                  : null,
              icon: Icon(PlatformIcons(context).checkMark),
            ),
          ),
        ],
      ),
      body: SafeArea(child: _content(context)),
    );
  }
}
