import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../l10n/l10n.dart';
import '../model/workout.dart';
import '../ui/adaptive_icons.dart';
import '../ui/adaptive_modal_sheet.dart';
import '../ui/cupertino_sheet_fork.dart';
import '../ui/dismissible_row.dart';
import 'workout_auto_completions.dart';

final class CreateWorkoutSheet extends StatefulWidget {
  final Workout? workout;

  const CreateWorkoutSheet({super.key, this.workout});

  @override
  State<CreateWorkoutSheet> createState() => _CreateWorkoutSheetState();
}

final class _CreateWorkoutSheetState extends State<CreateWorkoutSheet> {
  static final _footerButtonInsets = EdgeInsets.only(
    left: 16.0,
    top: 16.0,
    right: 16.0,
    bottom: 16.0,
  );
  static const _headerInsets = EdgeInsets.only(left: 16.0, right: 8.0);
  static const _itemInsets = EdgeInsets.only(left: 32.0, right: 24.0);

  final _focusNode = FocusNode();
  final _nameTextController = TextEditingController();
  final _scrollController = ScrollController();

  final _sections = <String, List<String>>{};

  // Track the group of the most recently added exercise for scrolling
  String? _lastAddedItemGroup;

  @override
  void initState() {
    super.initState();

    // Rebuild when app is resumed to update the UI if the pasteboard contents
    // have changed.
    AppLifecycleListener(onResume: () => setState(() {}));

    final workout = widget.workout;
    if (workout != null) {
      _nameTextController.text = workout.name;
      final sectionMap = {
        for (final s in workout.sections) s.name: List.of(s.exercises),
      };
      _sections.clear();
      _sections.addAll(sectionMap);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.workout == null) {
        setState(() {
          _sections[L10n.of(context)!.warmupSectionTitle] = [];
        });
        _nameTextController.text = L10n.of(context)!.defaultWorkoutName;
        _focusNode.requestFocus();
        _selectNameText();
      }
    });
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

  void _moveExercise(
    List<String> exercises, {
    required int fromIndex,
    required int toIndex,
  }) {
    final exercise = exercises.removeAt(fromIndex);
    exercises.insert(toIndex > fromIndex ? toIndex - 1 : toIndex, exercise);
  }

  void _moveSection({required int fromIndex, required int toIndex}) {
    final sectionEntries = _sections.entries.toList(growable: true);
    final section = sectionEntries.removeAt(fromIndex);
    sectionEntries.insert(toIndex > fromIndex ? toIndex - 1 : toIndex, section);

    _sections
      ..clear()
      ..addEntries(sectionEntries);
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
            title: PlatformText(
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

  /// Shows a dialog for editing the title of a section.
  Future<String?> _showSectionTitleDialog(
    BuildContext context, {
    required String title,
    String? initialText,
  }) async {
    final controller = TextEditingController(text: initialText);
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: initialText?.length ?? 0,
    );
    return showAdaptiveDialog<String>(
      context: context,
      builder: (innerContext) => AlertDialog.adaptive(
        title: PlatformText(title),
        content: PlatformTextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          hintText: L10n.of(innerContext)!.addSectionFieldHint,
          onSubmitted: (_) =>
              Navigator.of(innerContext).pop(controller.text.trim()),
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
            child: PlatformText(title),
          ),
        ],
      ),
    );
  }

  Future<void> _addSection(BuildContext context) async {
    _focusNode.unfocus();
    final sectionName = await _showSectionTitleDialog(
      context,
      title: L10n.of(context)!.addSectionDialogTitle,
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

  Future<void> _pasteExercises({required String sectionGroup}) async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (text == null || text.trim().isEmpty) return;
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return;
    final exercises = _sections[sectionGroup]!;
    setState(() {
      exercises.addAll(lines);
      _lastAddedItemGroup = sectionGroup;
    });
  }

  void _editSectionTitle(
    BuildContext context, {
    required String sectionTitle,
  }) async {
    final updatedTitle = await _showSectionTitleDialog(
      context,
      title: L10n.of(context)!.updateSectionDialogTitle,
      initialText: sectionTitle,
    );
    final trimmedName = updatedTitle?.trim();
    if (trimmedName == null || trimmedName.isEmpty) return;

    // Copy sections in the order they were created, but with the updated title
    // for the edited section.
    final updatedSections = <String, List<String>>{};
    for (final name in _sections.keys) {
      if (name == sectionTitle) {
        updatedSections[trimmedName] = _sections[name] ?? [];
      } else {
        updatedSections[name] = _sections[name] ?? [];
      }
    }
    setState(() {
      _sections.clear();
      _sections.addAll(updatedSections);
    });
  }

  Widget _addExerciseButton(
    BuildContext context, {
    required List<String> exercises,
    required String sectionTitle,
  }) => PlatformIconButton(
    icon: Icon(PlatformIcons(context).add),
    onPressed: () async {
      _focusNode.unfocus();
      final exercise = await _showExercisePicker(context);
      // Maybe add new empty exercise
      if (exercise?.trim().isNotEmpty ?? false) {
        setState(() {
          exercises.add(exercise!);
          _lastAddedItemGroup = sectionTitle;
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
      SliverSafeArea(
        top: false,
        bottom: false,
        sliver: SliverReorderableList(
          itemCount: sectionOrder.length,
          itemBuilder: (context, sectionIndex) {
            final sectionGroup = sectionOrder[sectionIndex];
            final exercises = _sections[sectionGroup]!;
            return Column(
              key: ValueKey('section_$sectionGroup'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionHeader(
                  context,
                  sectionTitle: sectionGroup,
                  exercises: exercises,
                  sectionIndex: sectionIndex,
                ),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: exercises.length,
                  itemBuilder: (context, exerciseIndex) {
                    final exercise = exercises[exerciseIndex];
                    final isLastItem = exerciseIndex == (exercises.length - 1);
                    return DismissibleRow(
                      key: ValueKey('dismissible_$exercise$exerciseIndex'),
                      onDismissed: (direction) {
                        setState(() {
                          exercises.removeAt(exerciseIndex);
                        });
                      },
                      child: Builder(
                        builder: (itemContext) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (isLastItem &&
                                _lastAddedItemGroup == sectionGroup) {
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
                            onDoubleTap: () => _editExercise(
                              context,
                              exercises: exercises,
                              index: exerciseIndex,
                              sectionGroup: sectionGroup,
                            ),
                            child: ReorderableDelayedDragStartListener(
                              index: exerciseIndex,
                              child: PlatformListTile(
                                key: ValueKey(
                                  'exercise_$exercise$exerciseIndex',
                                ),
                                title: PlatformText(
                                  exercise,
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: exercises.length > 1
                                    ? Icon(Icons.drag_handle)
                                    : null,
                                material: (context, platform) =>
                                    MaterialListTileData(
                                      contentPadding: _itemInsets,
                                    ),
                                cupertino: (context, platform) =>
                                    CupertinoListTileData(padding: _itemInsets),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
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
            );
          },
          onReorder: (startIndex, endIndex) {
            setState(() {
              _moveSection(fromIndex: startIndex, toIndex: endIndex);
            });
          },
        ),
      ),
      _addSectionFooter(context),
    ];
  }

  Widget _rightAppBarButtonAction(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([_nameTextController]),
    builder: (_, _) => PlatformIconButton(
      onPressed: _workoutCreationEnabled ? () => _createWorkout(context) : null,
      icon: Icon(PlatformIcons(context).checkMark),
    ),
  );

  Widget _addSectionButton(BuildContext context) => PlatformTextButton(
    onPressed: () => _addSection(context),
    child: DecoratedBox(
      position: .foreground,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: _footerButtonInsets,
        child: Row(
          children: [
            Icon(PlatformIcons(context).add),
            SizedBox(width: 8),
            PlatformText(
              L10n.of(context)!.addSectionButtonText,
              style: Theme.of(
                context,
              ).textTheme.labelLarge!.copyWith(fontWeight: .w500),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _pasteExercisesButton(BuildContext context) => FutureBuilder(
    future: Clipboard.hasStrings(),
    builder: (context, snapshot) {
      final hasStrings = snapshot.data ?? false;
      return PlatformTextButton(
        onPressed: hasStrings
            ? () async {
                _focusNode.unfocus();
                final sectionTitle = L10n.of(context)!.addSectionDialogTitle;
                final newSectionName = await _showSectionTitleDialog(
                  context,
                  title: sectionTitle,
                  initialText: L10n.of(context)!.pasteSectionInitialText,
                );
                if (newSectionName == null) return;
                setState(() => _sections[newSectionName] = []);
                _pasteExercises(sectionGroup: newSectionName);
              }
            : null,
        child: DecoratedBox(
          position: .foreground,
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withAlpha(hasStrings ? 255 : 135),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: _footerButtonInsets,
            child: Row(
              children: [
                Icon(AdaptiveIcons.paste),
                SizedBox(width: 8),
                PlatformText(
                  L10n.of(context)!.pasteSectionButtonText,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    fontWeight: .w500,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(hasStrings ? 255 : 135),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _sectionHeader(
    BuildContext context, {
    required String sectionTitle,
    required List<String> exercises,
    required int sectionIndex,
  }) => DismissibleRow(
    key: ValueKey('dismissible_$sectionTitle'),
    onDismissed: (_) {
      setState(() {
        _sections.remove(sectionTitle);
      });
    },
    child: GestureDetector(
      onDoubleTap: () => _editSectionTitle(context, sectionTitle: sectionTitle),
      child: ReorderableDelayedDragStartListener(
        index: sectionIndex,
        child: PlatformListTile(
          material: (context, platform) =>
              MaterialListTileData(contentPadding: _headerInsets),
          cupertino: (context, platform) =>
              CupertinoListTileData(padding: _headerInsets),
          title: PlatformText(
            sectionTitle,
            style: Theme.of(context).textTheme.headlineSmall,
            maxLines: 2,
            overflow: .ellipsis,
          ),
          trailing: _addExerciseButton(
            context,
            exercises: exercises,
            sectionTitle: sectionTitle,
          ),
        ),
      ),
    ),
  );

  Widget _addSectionFooter(BuildContext context) => SliverSafeArea(
    top: false,
    sliver: SliverToBoxAdapter(
      child: Row(
        mainAxisAlignment: .spaceEvenly,
        children: [
          Expanded(child: _addSectionButton(context)),
          Expanded(child: _pasteExercisesButton(context)),
        ],
      ),
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
          title: PlatformText(
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
