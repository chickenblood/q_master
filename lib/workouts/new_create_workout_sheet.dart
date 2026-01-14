import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/model/workout.dart';
import 'package:q_master/ui/adaptive_icons.dart';
import 'package:q_master/ui/adaptive_modal_sheet.dart';
import 'package:q_master/workouts/workout_auto_completions.dart';

class NewCreateWorkoutSheet extends StatefulWidget {
  final Workout? workout;

  const NewCreateWorkoutSheet({super.key, this.workout});

  @override
  State<NewCreateWorkoutSheet> createState() => _NewCreateWorkoutSheetState();
}

class _NewCreateWorkoutSheetState extends State<NewCreateWorkoutSheet> {
  final _focusNode = FocusNode();
  final _nameTextController = TextEditingController();

  final _warmup = <String>[];
  final _thang = <String>[];
  final _mary = <String>[];

  @override
  void initState() {
    super.initState();

    final workout = widget.workout;
    if (workout != null) {
      _nameTextController.text = workout.name;
      for (final exercise in workout.warmup) {
        _warmup.add(exercise.name);
      }
      for (final exercise in workout.thang) {
        _thang.add(exercise.name);
      }
      for (final exercise in workout.mary) {
        _mary.add(exercise.name);
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _nameTextController.text = L10n.of(context)!.defaultWorkoutName;
        _focusNode.requestFocus();
        _selectNameText();
      });
    }
  }

  @override
  void dispose() {
    _nameTextController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _selectNameText() {
    // Select all text on focus
    _nameTextController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _nameTextController.value.text.length,
    );
  }

  Future<String?> _showExercisePicker(BuildContext context) async {
    final controller = TextEditingController();
    return showAdaptiveModalSheet<String>(
      context: context,
      dismissible: false,
      child: PlatformScaffold(
        appBar: PlatformAppBar(
          cupertino: (appBarContext, _) => CupertinoNavigationBarData(
            backgroundColor: Colors.transparent,

            leading: PlatformIconButton(
              padding: EdgeInsets.only(right: 22),
              icon: Icon(AdaptiveIcons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              L10n.of(context)!.appBarTitle,
              textScaler: MediaQuery.textScalerOf(
                context,
              ).clamp(maxScaleFactor: 1.6),
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                WorkoutAutocompleteTextField(
                  textEditingController: controller,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 1,
                  onSubmitted: () => Navigator.of(context).pop(controller.text),
                ),
                Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _moveExercise(
    List<String> exercises, {
    required int fromIndex,
    required int toIndex,
  }) {
    final exercise = exercises[fromIndex];
    exercises.insert(min(toIndex, exercises.length), exercise);
    exercises.removeAt(fromIndex > toIndex ? fromIndex + 1 : fromIndex);
  }

  Widget _addExerciseButton(
    BuildContext context, {
    required List<String> exercises,
  }) => PlatformIconButton(
    icon: Icon(PlatformIcons(context).add),
    onPressed: () async {
      final exercise = await _showExercisePicker(context);
      // Maybe add new empty exercise
      if (exercise?.trim().isNotEmpty ?? false) {
        setState(() {
          exercises.add(exercise!);
        });
      }
    },
  );

  static const _headerInsets = EdgeInsets.symmetric(vertical: 8.0);

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    required List<String> exercises,
  }) => PlatformListTile(
    material: (context, platform) =>
        MaterialListTileData(contentPadding: _headerInsets),
    cupertino: (context, platform) =>
        CupertinoListTileData(padding: _headerInsets),
    title: PlatformText(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    trailing: _addExerciseButton(context, exercises: exercises),
  );

  Widget _content(BuildContext context) {
    final groupedExercises = [
      (L10n.of(context)!.workoutWarmupFieldLabel, _warmup),
      (L10n.of(context)!.workoutThangFieldLabel, _thang),
      (L10n.of(context)!.workoutMaryFieldLabel, _mary),
    ];
    return SliverSafeArea(
      minimum: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          PlatformText(L10n.of(context)!.workoutNameFieldLabel),
          PlatformTextField(
            controller: _nameTextController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            focusNode: _focusNode,
          ),
          for (final (sectionTitle, exercises) in groupedExercises) ...[
            ReorderableListView.builder(
              header: _sectionHeader(
                context,
                title: sectionTitle,
                exercises: exercises,
              ),
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return Dismissible(
                  key: ValueKey('dismissible_$exercise$index'),
                  background: Container(color: Colors.red),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    setState(() {
                      exercises.removeAt(index);
                    });
                  },
                  child: PlatformListTile(
                    key: ValueKey('exercise_$exercise$index'),
                    title: Text(exercise),
                    trailing: exercises.length > 1
                        ? Icon(Icons.drag_handle)
                        : null,
                  ),
                );
              },
              itemCount: exercises.length,
              onReorder: (startIndex, endIndex) {
                setState(() {
                  _moveExercise(
                    exercises,
                    fromIndex: startIndex,
                    toIndex: endIndex,
                  );
                });
              },
            ),
          ],
        ]),
      ),
    );
  }

  bool get _workoutCreationEnabled {
    return _nameTextController.text.trim().isNotEmpty &&
        (_warmup.isNotEmpty || _thang.isNotEmpty || _mary.isNotEmpty);
  }

  void _createWorkout(BuildContext context) {
    final workout = Workout(
      name: _nameTextController.text.trim(),
      date: DateTime.now(),
      warmup: _warmup.map((e) => Exercise(name: e)).toList(),
      thang: _thang.map((e) => Exercise(name: e)).toList(),
      mary: _mary.map((e) => Exercise(name: e)).toList(),
    );
    Navigator.pop(context, workout);
  }

  Widget _rightAppBarButtonAction(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_nameTextController]),
    builder: (_, _) => PlatformIconButton(
      onPressed: _workoutCreationEnabled ? () => _createWorkout(context) : null,
      icon: Icon(PlatformIcons(context).checkMark),
    ),
  );

  @override
  Widget build(BuildContext context) => PlatformScaffold(
    body: CustomScrollView(
      physics: ClampingScrollPhysics(),
      slivers: [
        PlatformSliverAppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: PlatformIconButton(
            padding: Theme.of(context).platform == TargetPlatform.iOS
                ? EdgeInsets.only(left: 8)
                : EdgeInsets.zero,
            icon: Icon(AdaptiveIcons.close),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            L10n.of(context)!.createWorkoutDialogTitle,
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: 1.5),
          ),
          cupertino: (_, _) => CupertinoSliverAppBarData(
            trailing: _rightAppBarButtonAction(context),
            padding: EdgeInsetsDirectional.only(end: 8),
          ),
          material: (_, _) => MaterialSliverAppBarData(
            actions: [_rightAppBarButtonAction(context)],
          ),
        ),
        _content(context),
      ],
    ),
  );
}
