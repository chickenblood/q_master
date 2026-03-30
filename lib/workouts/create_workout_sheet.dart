import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../l10n/l10n.dart';
import '../model/workout.dart';
import '../ui/adaptive_icons.dart';
import '../ui/adaptive_modal_sheet.dart';
import '../ui/cupertino_sheet_fork.dart';
import 'workout_auto_completions.dart';

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

  final _sections = <String, List<String>>{'warmup': []};

  // Track the group of the most recently added exercise for scrolling
  String? _lastAddedItemGroup;

  @override
  void initState() {
    super.initState();

    final workout = widget.workout;
    if (workout != null) {
      _nameTextController.text = workout.name;
      final sectionMap = {
        for (final s in workout.sections) s.name: List.of(s.exercises),
      };
      _sections.clear();
      _sections.addAll(sectionMap);
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

  Future<void> _addSection(BuildContext context) async {
    _focusNode.unfocus();
    final controller = TextEditingController();
    final sectionName = await showAdaptiveDialog<String>(
      context: context,
      builder: (innerContext) => AlertDialog.adaptive(
        title: PlatformText(L10n.of(innerContext)!.addSectionDialogTitle),
        content: PlatformTextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          hintText: L10n.of(innerContext)!.addSectionFieldHint,
          onSubmitted: (_) => Navigator.of(innerContext).pop(controller.text),
        ),
        actions: [
          PlatformDialogAction(
            onPressed: () => Navigator.of(innerContext).pop(),
            child: PlatformText(L10n.of(innerContext)!.cancelAction),
          ),
          PlatformDialogAction(
            cupertino: (_, _) =>
                CupertinoDialogActionData(isDefaultAction: true),
            onPressed: () => Navigator.of(innerContext).pop(controller.text),
            child: PlatformText(L10n.of(innerContext)!.addSectionDialogTitle),
          ),
        ],
      ),
    );
    final trimmedName = sectionName?.trim();
    if (trimmedName == null || trimmedName.isEmpty) return;
    final alreadyExists = _sections.keys.any(
      (name) => name.toLowerCase() == trimmedName.toLowerCase(),
    );
    if (alreadyExists) return;

    setState(() {
      _sections[trimmedName] = [];
    });
  }

  void _moveExercise(
    List<String> exercises, {
    required int fromIndex,
    required int toIndex,
  }) {
    final exercise = exercises.removeAt(fromIndex);
    exercises.insert(toIndex > fromIndex ? toIndex - 1 : toIndex, exercise);
  }

  Future<void> _pasteExercises({
    required List<String> exercises,
    required String sectionGroup,
  }) async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (text == null || text.trim().isEmpty) return;
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return;
    setState(() {
      exercises.addAll(lines);
      _lastAddedItemGroup = sectionGroup;
    });
  }

  Widget _pasteExercisesButton(
    BuildContext context, {
    required List<String> exercises,
    required String sectionGroup,
  }) => PlatformIconButton(
    icon: Icon(AdaptiveIcons.paste),
    onPressed: () {
      _focusNode.unfocus();
      _pasteExercises(exercises: exercises, sectionGroup: sectionGroup);
    },
  );

  Widget _addExerciseButton(
    BuildContext context, {
    required List<String> exercises,
    required String sectionGroup,
  }) => PlatformIconButton(
    icon: Icon(PlatformIcons(context).add),
    onPressed: () async {
      _focusNode.unfocus();
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
    required String sectionGroup,
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
    required String sectionGroup,
  }) => PlatformListTile(
    material: (context, platform) =>
        MaterialListTileData(contentPadding: _headerInsets),
    cupertino: (context, platform) =>
        CupertinoListTileData(padding: _headerInsets),
    title: PlatformText(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _pasteExercisesButton(
          context,
          exercises: exercises,
          sectionGroup: sectionGroup,
        ),
        _addExerciseButton(
          context,
          exercises: exercises,
          sectionGroup: sectionGroup,
        ),
      ],
    ),
  );

  static const _itemInsets = EdgeInsets.only(left: 32.0, right: 24.0);

  Widget _addSectionFooter(BuildContext context) => SliverSafeArea(
    top: false,
    sliver: SliverToBoxAdapter(
      child: Padding(
        padding: _headerInsets,
        child: DecoratedBox(
          position: .foreground,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PlatformListTile(
              material: (context, platform) => MaterialListTileData(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              cupertino: (context, platform) => CupertinoListTileData(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              leading: Icon(PlatformIcons(context).add, weight: 700),
              title: PlatformText(
                L10n.of(context)!.addSectionButtonText,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              onTap: () => _addSection(context),
            ),
          ),
        ),
      ),
    ),
  );

  String _sectionTitle(BuildContext context, String sectionName) {
    switch (sectionName.toLowerCase()) {
      case 'warmup':
        return L10n.of(context)!.workoutWarmupFieldLabel;
      case 'thang':
        return L10n.of(context)!.workoutThangFieldLabel;
      case 'mary':
        return L10n.of(context)!.workoutMaryFieldLabel;
      default:
        return sectionName;
    }
  }

  List<Widget> _content(BuildContext context) {
    final sectionOrder = _sections.keys.toList(growable: false);
    return [
      SliverSafeArea(
        bottom: false,
        sliver: SliverList(
          delegate: SliverChildListDelegate([
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
      for (final sectionGroup in sectionOrder) ...[
        SliverSafeArea(
          bottom: false,
          sliver: SliverToBoxAdapter(
            child: _sectionHeader(
              context,
              title: _sectionTitle(context, sectionGroup),
              exercises: _sections[sectionGroup]!,
              sectionGroup: sectionGroup,
            ),
          ),
        ),
        SliverSafeArea(
          top: false,
          bottom: false,
          sliver: SliverReorderableList(
            itemBuilder: (context, index) {
              final exercise = _sections[sectionGroup]![index];
              final isLastItem = index == (_sections[sectionGroup]!.length - 1);
              return Dismissible(
                key: ValueKey('dismissible_$exercise$index'),
                background: Container(color: Colors.red),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  setState(() {
                    _sections[sectionGroup]!.removeAt(index);
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
                          trailing: _sections[sectionGroup]!.length > 1
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
                        exercises: _sections[sectionGroup]!,
                        index: index,
                        sectionGroup: sectionGroup,
                      ),
                    );
                  },
                ),
              );
            },
            itemCount: _sections[sectionGroup]!.length,
            onReorder: (startIndex, endIndex) {
              setState(() {
                _moveExercise(
                  _sections[sectionGroup]!,
                  fromIndex: startIndex,
                  toIndex: endIndex,
                );
              });
            },
          ),
        ),
      ],
      _addSectionFooter(context),
    ];
  }

  bool get _workoutCreationEnabled {
    return _nameTextController.text.trim().isNotEmpty &&
        _sections.values.any((exercises) => exercises.isNotEmpty);
  }

  void _createWorkout(BuildContext context) {
    final workout = Workout(
      name: _nameTextController.text.trim(),
      date: DateTime.now(),
      sections: [
        for (final entry in _sections.entries)
          WorkoutSection(name: entry.key, exercises: List.of(entry.value)),
      ],
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
      physics: BottomSheetScrollPhysics(),
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
