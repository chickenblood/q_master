import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../l10n/l10n.dart';
import '../model/workout.dart';
import '../ui/adaptive_icons.dart';
import '../ui/adaptive_modal_sheet.dart';
import '../ui/scroll_physics.dart';
import 'workout_auto_completions.dart';

enum WorkoutGroup { warmup, thang, mary }

class CreateWorkoutSheet extends StatefulWidget {
  final Workout? workout;

  const CreateWorkoutSheet({super.key, this.workout});

  @override
  State<CreateWorkoutSheet> createState() => _CreateWorkoutSheetState();
}

class _CreateWorkoutSheetState extends State<CreateWorkoutSheet> {
  final _focusNode = FocusNode();
  final _nameTextController = TextEditingController();
  final _scrollController = ScrollController();

  final _warmup = <String>[];
  final _thang = <String>[];
  final _mary = <String>[];

  // Track the group of the most recently added exercise for scrolling
  WorkoutGroup? _lastAddedItemGroup;

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
    _scrollController.dispose();
    super.dispose();
  }

  void _selectNameText() {
    // Select all text on focus
    _nameTextController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _nameTextController.value.text.length,
    );
  }

  Future<String?> _showExercisePicker(
    BuildContext context, {
    String? text,
  }) async {
    final controller = TextEditingController(text: text);
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: text?.length ?? 0,
    );
    return showAdaptiveModalSheet<String>(
      context: context,
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
              L10n.of(context)!.exerciseEntryPromptText,
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
    final exercise = exercises.removeAt(fromIndex);
    exercises.insert(toIndex > fromIndex ? toIndex - 1 : toIndex, exercise);
  }

  Widget _addExerciseButton(
    BuildContext context, {
    required List<String> exercises,
    required WorkoutGroup sectionGroup,
  }) => PlatformIconButton(
    icon: Icon(PlatformIcons(context).add),
    onPressed: () async {
      final exercise = await _showExercisePicker(context);
      // Maybe add new empty exercise
      if (exercise?.trim().isNotEmpty ?? false) {
        setState(() {
          exercises.add(exercise!);
          _lastAddedItemGroup = sectionGroup;
        });
      }
    },
  );

  void _editExercise(
    BuildContext context, {
    required List<String> exercises,
    required int index,
    required WorkoutGroup sectionGroup,
  }) async {
    final existingExercise = exercises[index];
    final updatedExercise = await _showExercisePicker(
      context,
      text: existingExercise,
    );
    // Maybe update exercise
    if (updatedExercise?.trim().isNotEmpty ?? false) {
      setState(() {
        exercises[index] = updatedExercise!;
        _lastAddedItemGroup = sectionGroup;
      });
    }
  }

  static const _headerInsets = EdgeInsets.only(left: 16.0, right: 8.0);

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    required List<String> exercises,
    required WorkoutGroup sectionGroup,
  }) => PlatformListTile(
    material: (context, platform) =>
        MaterialListTileData(contentPadding: _headerInsets),
    cupertino: (context, platform) =>
        CupertinoListTileData(padding: _headerInsets),
    title: PlatformText(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    trailing: _addExerciseButton(
      context,
      exercises: exercises,
      sectionGroup: sectionGroup,
    ),
  );

  static const _itemInsets = EdgeInsets.only(left: 32.0, right: 24.0);

  List<Widget> _content(BuildContext context) {
    final groupedExercises = [
      (WorkoutGroup.warmup, L10n.of(context)!.workoutWarmupFieldLabel, _warmup),
      (WorkoutGroup.thang, L10n.of(context)!.workoutThangFieldLabel, _thang),
      (WorkoutGroup.mary, L10n.of(context)!.workoutMaryFieldLabel, _mary),
    ];
    return [
      SliverSafeArea(
        bottom: false,
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: _headerInsets,
              child: PlatformText(
                L10n.of(context)!.workoutNameFieldLabel,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Padding(
              padding: _headerInsets,
              child: PlatformTextField(
                controller: _nameTextController,
                textCapitalization: TextCapitalization.sentences,
                focusNode: _focusNode,
              ),
            ),
          ]),
        ),
      ),
      for (final (sectionGroup, sectionTitle, exercises)
          in groupedExercises) ...[
        SliverSafeArea(
          bottom: false,
          sliver: SliverToBoxAdapter(
            child: _sectionHeader(
              context,
              title: sectionTitle,
              exercises: exercises,
              sectionGroup: sectionGroup,
            ),
          ),
        ),
        SliverSafeArea(
          top: false,
          bottom: sectionGroup == WorkoutGroup.mary,
          sliver: SliverReorderableList(
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              final isLastItem = index == (exercises.length - 1);
              return Dismissible(
                key: ValueKey('dismissible_$exercise$index'),
                background: Container(color: Colors.red),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  setState(() {
                    exercises.removeAt(index);
                  });
                },
                child: Builder(
                  builder: (itemContext) {
                    // Scroll to the newly added item after the frame is rendered
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (isLastItem && _lastAddedItemGroup == sectionGroup) {
                        Scrollable.ensureVisible(
                          itemContext,
                          duration: const Duration(milliseconds: 300),
                          alignment: 0.5,
                          alignmentPolicy: .explicit,
                        );
                        _lastAddedItemGroup = null;
                      }
                    });
                    return GestureDetector(
                      child: ReorderableDelayedDragStartListener(
                        index: index,
                        child: PlatformListTile(
                          key: ValueKey('exercise_$exercise$index'),
                          title: Text(exercise),
                          trailing: exercises.length > 1
                              ? Icon(Icons.drag_handle)
                              : null,
                          material: (context, platform) =>
                              MaterialListTileData(contentPadding: _itemInsets),
                          cupertino: (context, platform) =>
                              CupertinoListTileData(padding: _itemInsets),
                        ),
                      ),
                      onDoubleTap: () => _editExercise(
                        context,
                        exercises: exercises,
                        index: index,
                        sectionGroup: sectionGroup,
                      ),
                    );
                  },
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
        ),
      ],
    ];
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
      controller: _scrollController,
      physics: dismissibleSheetScrollPhysics(context),
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
            widget.workout == null
                ? L10n.of(context)!.createWorkoutDialogTitle
                : L10n.of(context)!.editWorkoutDialogTitle,
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
        ..._content(context),
      ],
    ),
  );
}
