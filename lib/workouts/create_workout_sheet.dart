import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/model/workout.dart';
import 'package:q_master/ui/adaptive_icons.dart';

import 'workout_auto_completions.dart';

class CreateWorkoutSheet extends StatefulWidget {
  final Workout? workout;

  const CreateWorkoutSheet({super.key, this.workout});

  @override
  State<CreateWorkoutSheet> createState() => _CreateWorkoutSheetState();
}

class _CreateWorkoutSheetState extends State<CreateWorkoutSheet> {
  final _verticalSpacing = const SizedBox(height: 16.0);
  final focusNode = FocusNode();

  final _nameTextController = TextEditingController();
  final _warmupTextController = TextEditingController();
  final _thangTextController = TextEditingController();
  final _maryTextController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final workout = widget.workout;
    if (workout != null) {
      _nameTextController.text = workout.name;
      _warmupTextController.text = workout.warmup.map((e) => e.name).join('\n');
      _thangTextController.text = workout.thang.map((e) => e.name).join('\n');
      _maryTextController.text = workout.mary.map((e) => e.name).join('\n');
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _nameTextController.text = L10n.of(context)!.defaultWorkoutName;
        focusNode.requestFocus();
        _selectNameText();
      });
    }
  }

  @override
  void dispose() {
    _nameTextController.dispose();
    _warmupTextController.dispose();
    _thangTextController.dispose();
    _maryTextController.dispose();
    super.dispose();
  }

  void _selectNameText() {
    // Select all text on focus
    _nameTextController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _nameTextController.value.text.length,
    );
  }

  Widget _content(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.all(16.0),
    child: Column(
    crossAxisAlignment: .stretch,
    children: [
      PlatformText(L10n.of(context)!.workoutNameFieldLabel),
      PlatformTextField(
        controller: _nameTextController,
        textCapitalization: TextCapitalization.sentences,
        maxLines: 2,
        focusNode: focusNode,
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
        optionsViewOpenDirection: .up,
        minLines: 5,
        maxLines: 5,
      ),
    ],
    ),
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

  Widget _rightAppBarButtonAction() => ListenableBuilder(
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
              );

  @override
  Widget build(BuildContext context) => Material(child: CustomScrollView(
      physics: ClampingScrollPhysics(),
        slivers: [ 
          PlatformSliverAppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: PlatformIconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(AdaptiveIcons.close),
            ),
            title: Text(L10n.of(context)!.createWorkoutDialogTitle),
            cupertino: (_, _) =>
                CupertinoSliverAppBarData(
            trailing: _rightAppBarButtonAction(),
                ),
            material: (context, platform) => MaterialSliverAppBarData(
              actions: [
                _rightAppBarButtonAction()
              ]
            ),
          ),
          SliverToBoxAdapter(child: _content(context)),
        ],
  ),
    );
}
