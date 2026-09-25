import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../l10n/l10n.dart';
import '../model/workout.dart';
import '../model/workout_list.dart';
import '../theme/theme.dart';
import '../ui/action_button.dart';
import '../ui/adaptive_icons.dart';
import '../ui/dismissible_row.dart';
import '../utils/datetime_utils.dart';
import 'exercise_picker_sheet.dart';

/// The display mode the dialog is initially displayed in.
///
/// In [display] mode, the workout details are shown read-only with options to
/// 1) edit (which switches to [edit] mode),
/// 2) share
/// 3) Start the beatdown.
enum DisplayMode { display, edit }

final class CreateWorkoutSheet extends ConsumerStatefulWidget {
  final Workout? originalWorkout;
  final DisplayMode initialDisplayMode;
  final Function(BuildContext context, Workout workout)? onShare;
  final Function(BuildContext context, Workout workout)? onShowBeatdownBrowser;

  const CreateWorkoutSheet({
    super.key,
    this.originalWorkout,
    this.initialDisplayMode = DisplayMode.display,
    this.onShare,
    this.onShowBeatdownBrowser,
  });

  @override
  ConsumerState<CreateWorkoutSheet> createState() => _CreateWorkoutSheetState();
}

final class _CreateWorkoutSheetState extends ConsumerState<CreateWorkoutSheet> {
  static const _headerInsets = EdgeInsets.only(left: 16.0, right: 16.0);

  final _focusNode = FocusNode();
  final _nameTextController = TextEditingController();

  final _sections = <String, List<String>>{};

  // For storing the original workout when in edit mode, so we can revert to it
  // if the user cancels out of editing.
  Workout? _storedWorkout;
  var _displayMode = DisplayMode.display;
  var _pickerIsShown = false;

  // Track the group of the most recently added exercise for scrolling
  String? _lastAddedItemGroup;
  late final AppLifecycleListener _appLifecycleListener;

  // --- Lifecycle & State ---
  @override
  void initState() {
    super.initState();
    _displayMode = widget.initialDisplayMode;
    _appLifecycleListener = AppLifecycleListener(
      onResume: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
    final workout = widget.originalWorkout;
    if (workout != null) {
      _storedWorkout = workout;
      _updateUiFromWorkout(workout);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (workout == null) {
        setState(() {
          _sections[L10n.of(context)!.warmupSectionTitle] = [];
        });
        _nameTextController.text = L10n.of(context)!.defaultWorkoutName;
        _selectNameText();
        _focusNode.requestFocus();
      }
      _storedWorkout = _buildWorkoutFromUi();
    });
  }

  @override
  void dispose() {
    _appLifecycleListener.dispose();
    _nameTextController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // --- UI State Helpers ---
  void _selectNameText() {
    _nameTextController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _nameTextController.value.text.length,
    );
  }

  bool get _workoutCreationEnabled {
    return _nameTextController.text.trim().isNotEmpty &&
        _sections.values.any((exercises) => exercises.isNotEmpty);
  }

  String _titleForAppBar() {
    if (_displayMode == DisplayMode.edit) {
      return widget.originalWorkout == null
          ? L10n.of(context)!.createWorkoutDialogTitle
          : L10n.of(context)!.editWorkoutDialogTitle;
    } else {
      final currentName = _nameTextController.text.trim();
      return currentName.isEmpty
          ? L10n.of(context)!.defaultWorkoutName
          : currentName;
    }
  }

  // --- Section & Exercise Manipulation ---
  void _moveExercise(
    List<String> exercises, {
    required int fromIndex,
    required int toIndex,
  }) {
    final exercise = exercises.removeAt(fromIndex);
    exercises.insert(toIndex, exercise);
  }

  void _moveSection({required int fromIndex, required int toIndex}) {
    final sectionEntries = _sections.entries.toList(growable: true);
    final section = sectionEntries.removeAt(fromIndex);
    sectionEntries.insert(toIndex, section);
    _sections
      ..clear()
      ..addEntries(sectionEntries);
  }

  Future<String?> _showNameChangeDialog(
    BuildContext context, {
    required String title,
    required String buttonTitle,
    String? initialText,
    String? hintText,
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
          hintText: hintText,
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
                CupertinoDialogActionData(isDestructiveAction: true),
            onPressed: () => Navigator.of(innerContext).pop(controller.text),
            child: PlatformText(buttonTitle),
          ),
        ],
      ),
    );
  }

  Future<void> _addSection(BuildContext context) async {
    _focusNode.unfocus();
    final sectionName = await _showNameChangeDialog(
      context,
      title: L10n.of(context)!.addSectionDialogTitle,
      buttonTitle: L10n.of(context)!.addSectionDialogButtonText,
      hintText: L10n.of(context)!.addSectionFieldHint,
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
    final updatedTitle = await _showNameChangeDialog(
      context,
      title: L10n.of(context)!.updateSectionDialogTitle,
      buttonTitle: L10n.of(context)!.updateSectionDialogButtonText,
      initialText: sectionTitle,
    );
    final trimmedName = updatedTitle?.trim();
    if (trimmedName == null || trimmedName.isEmpty) return;
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
    icon: Icon(
      PlatformIcons(context).add,
      color: Theme.of(context).colorScheme.primary,
    ),
    cupertino: (context, platform) =>
        CupertinoIconButtonData(padding: EdgeInsets.only(right: 8)),
    onPressed: () async {
      _focusNode.unfocus();
      setState(() => _pickerIsShown = true);
      showExercisePicker(
        context,
        onExerciseAdded: (exercise) {
          setState(() {
            exercises.add(exercise);
            _lastAddedItemGroup = sectionTitle;
          });
        },
      ).then((_) => setState(() => _pickerIsShown = false));
    },
  );

  void _editExercise(
    BuildContext context, {
    required List<String> exercises,
    required int index,
    required String sectionGroup,
  }) async {
    final existingExercise = exercises[index];
    final updatedExercise = await _showNameChangeDialog(
      context,
      title: L10n.of(context)!.updateExerciseDialogTitle,
      buttonTitle: L10n.of(context)!.updateExerciseButtonTitle,
      initialText: existingExercise,
    );
    if (updatedExercise?.trim().isNotEmpty ?? false) {
      setState(() {
        exercises[index] = updatedExercise!;
        _lastAddedItemGroup = sectionGroup;
      });
    }
  }

  List<Widget> content(BuildContext context) {
    final sectionOrder = _sections.keys.toList(growable: false);
    return [
      SliverSafeArea(
        top: false,
        bottom: false,
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            if (_displayMode == DisplayMode.edit)
              Padding(
                padding: _headerInsets,
                child: GlassTextField(
                  controller: _nameTextController,
                  enabled: _displayMode == DisplayMode.edit,
                  //textCapitalization: TextCapitalization.sentences,
                  focusNode: _focusNode,
                  textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: -0.3,
                  ),
                  suffixIcon: Icon(
                    PlatformIcons(context).clear,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onSuffixTap: () {
                    _nameTextController.clear();
                    _focusNode.requestFocus();
                  },
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
                      enabled: _displayMode == DisplayMode.edit,
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
                                alignment: 0.0,
                                alignmentPolicy: .explicit,
                              );
                              _lastAddedItemGroup = null;
                            }
                          });
                          return GestureDetector(
                            onDoubleTap: () => _displayMode == .edit
                                ? _editExercise(
                                    context,
                                    exercises: exercises,
                                    index: exerciseIndex,
                                    sectionGroup: sectionGroup,
                                  )
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 5, 8, 5),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: PlatformListTile(
                                      key: ValueKey(
                                        'exercise_$exercise$exerciseIndex',
                                      ),
                                      title: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          exercise,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                          maxLines: 2,
                                          overflow: .ellipsis,
                                          textAlign: .left,
                                        ),
                                      ),
                                      material: (context, platform) =>
                                          MaterialListTileData(
                                            contentPadding: EdgeInsets.only(
                                              left: 0,
                                              right: 8,
                                            ),
                                          ),
                                      cupertino: (context, platform) =>
                                          CupertinoListTileData(
                                            padding: EdgeInsets.only(
                                              left: 0,
                                              right: 8,
                                            ),
                                          ),
                                    ),
                                  ),
                                  if (_displayMode == DisplayMode.edit)
                                    ReorderableDelayedDragStartListener(
                                      index: exerciseIndex,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 6.0,
                                        ),
                                        child: Icon(
                                          Icons.drag_handle,
                                          color: ThemeColors.dragHandle(
                                            context,
                                          ),
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  onReorderItem: (startIndex, endIndex) {
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
          onReorderItem: (startIndex, endIndex) {
            setState(() {
              _moveSection(fromIndex: startIndex, toIndex: endIndex);
            });
          },
        ),
      ),
      if (_displayMode == DisplayMode.edit) addSectionFooter(context),
    ];
  }

  List<GlassBarItem> _rightAppBarButtonItems(BuildContext context) {
    if (_displayMode == .display) {
      return [
        GlassBarItem.icon(
          icon: Icon(PlatformIcons(context).edit),
          onTap: () => setState(() => _displayMode = .edit),
        ),
        GlassBarItem.icon(
          id: 'right_item',
          icon: Icon(PlatformIcons(context).playArrowSolid),
          onTap: () => widget.onShowBeatdownBrowser?.call(
            context,
            _buildWorkoutFromUi(),
          ),
        ),
      ];
    }
    final theme = Theme.of(context);
    final isEnabled =
        _nameTextController.text.isNotEmpty &&
        _storedWorkout != _buildWorkoutFromUi();
    final enabledColor = theme.colorScheme.primary;
    final disabledColor = theme.colorScheme.onSurfaceVariant;
    return [
      GlassBarItem.icon(
        id: 'right_item',
        icon: Icon(
          PlatformIcons(context).checkMark,
          color: isEnabled ? enabledColor : disabledColor,
        ),
        enabled: isEnabled,
        onTap: isEnabled
            ? () async {
                final savedWorkout = await _saveWorkout();
                if (!mounted) return;
                setState(() {
                  _storedWorkout = savedWorkout;
                  _displayMode = .display;
                });
              }
            : () {},
      ),
    ];
  }

  Widget pasteExercisesButton(BuildContext context) => FutureBuilder(
    future: Clipboard.hasStrings(),
    builder: (context, snapshot) {
      final hasStrings = snapshot.data ?? false;
      return Opacity(
        opacity: hasStrings ? 1.0 : 0.4,
        child: ActionButton(
          outlined: true,
          icon: Icons.content_paste,
          label: L10n.of(context)!.pasteSectionButtonText,
          onPressed: hasStrings
              ? () async {
                  _focusNode.unfocus();
                  final sectionTitle = L10n.of(
                    context,
                  )!.addSectionForPasteDialogTitle;
                  final newSectionName = await _showNameChangeDialog(
                    context,
                    title: sectionTitle,
                    buttonTitle: L10n.of(context)!.pasteExercisesButtonLabel,
                    initialText: L10n.of(context)!.pasteSectionInitialText,
                  );
                  if (newSectionName == null) return;
                  setState(() => _sections[newSectionName] = []);
                  _pasteExercises(sectionGroup: newSectionName);
                }
              : null,
        ),
      );
    },
  );

  Widget _sectionHeader(
    BuildContext context, {
    required String sectionTitle,
    required List<String> exercises,
    required int sectionIndex,
  }) {
    final isEditingMode = _displayMode == .edit;
    return DismissibleRow(
      key: ValueKey('dismissible_$sectionTitle'),
      enabled: isEditingMode,
      onDismissed: (_) {
        setState(() {
          _sections.remove(sectionTitle);
        });
      },
      child: ReorderableDelayedDragStartListener(
        index: sectionIndex,
        enabled: isEditingMode,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
          color: Theme.of(context).colorScheme.surface,
          child: GestureDetector(
            onDoubleTap: () => isEditingMode
                ? _editSectionTitle(context, sectionTitle: sectionTitle)
                : null,
            child: Row(
              mainAxisAlignment: .spaceBetween,
              crossAxisAlignment: .center,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      sectionTitle.toUpperCase(),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: .1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                if (isEditingMode)
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          PlatformIcons(context).edit,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 20,
                        ),
                        tooltip: L10n.of(context)!.editSectionTooltip,
                        onPressed: () => _editSectionTitle(
                          context,
                          sectionTitle: sectionTitle,
                        ),
                      ),
                      _addExerciseButton(
                        context,
                        exercises: exercises,
                        sectionTitle: sectionTitle,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget addSectionFooter(BuildContext context) => SliverSafeArea(
    top: false,
    sliver: SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            ActionButton(
              label: L10n.of(context)!.addSectionButtonText,
              icon: PlatformIcons(context).add,
              iconColor: Theme.of(context).colorScheme.primary,
              outlined: true,
              onPressed: () => _addSection(context),
            ),
            pasteExercisesButton(context),
          ],
        ),
      ),
    ),
  );

  Widget _displayFooter(BuildContext context) => SliverSafeArea(
    top: false,
    sliver: SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          spacing: 12,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: ActionButton(
                    label: L10n.of(context)!.editWorkoutButtonText,
                    icon: PlatformIcons(context).edit,
                    outlined: true,
                    onPressed: () => setState(() => _displayMode = .edit),
                  ),
                ),
                Expanded(
                  child: ActionButton(
                    label: L10n.of(context)!.shareWorkoutButtonText,
                    icon: PlatformIcons(context).share,
                    outlined: true,
                    onPressed: () =>
                        widget.onShare?.call(context, _buildWorkoutFromUi()),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 62,
              child: ActionButton(
                label: L10n.of(context)!.startBeatdownButtonText,
                icon: PlatformIcons(context).playArrowSolid,
                onPressed: () {
                  widget.onShowBeatdownBrowser?.call(
                    context,
                    _buildWorkoutFromUi(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => GlassScaffold(
    appBar: ListenableBuilder(
      listenable: _nameTextController,
      builder: (_, _) => GlassAppBar.pinned(
        backgroundColor: Colors.transparent,
        leading: [
          GlassBarItem.icon(
            id: 'left-item',
            icon: Icon(
              _displayMode == .display
                  ? PlatformIcons(context).back
                  : AdaptiveIcons.close,
            ),
            onTap: _handleCancel,
          ),
        ],
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlatformText(
              _titleForAppBar(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              textScaler: MediaQuery.textScalerOf(
                context,
              ).clamp(maxScaleFactor: 1.5),
            ),
            if (_displayMode == .display && _storedWorkout != null)
              PlatformText(
                _storedWorkout!.date.formattedForDisplay(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: _rightAppBarButtonItems(context),
      ),
    ),
    body: SafeArea(
      child: CustomScrollView(
        primary: true,
        slivers: [
          SliverPadding(padding: const EdgeInsets.only(top: kToolbarHeight)),
          ...content(context),
          if (_displayMode == .display) _displayFooter(context),
          // Add padding when the picker is up, so we can scroll the content
          // above the keyboard and picker without it being obscured
          SliverPadding(
            padding: const EdgeInsets.only(bottom: kTextTabBarHeight),
          ),
          if (_pickerIsShown) SliverFillRemaining(child: SizedBox(height: 800)),
        ],
      ),
    ),
  );

  Future<Workout> _saveWorkout() async {
    final workoutToSave = _buildWorkoutFromUi().copyWith(date: DateTime.now());
    final listNotifier = ref.read(workoutListProvider.notifier);
    if (widget.originalWorkout == null) {
      await listNotifier.add(workoutToSave);
    } else if (_storedWorkout != null) {
      await listNotifier.replace(_storedWorkout!, workoutToSave);
    } else {
      assert(false, 'Unable to save workout: _storedWorkout is null');
    }
    return workoutToSave;
  }

  Future<void> _handleCancel() async {
    if (_displayMode == .display) {
      Navigator.of(context).pop();
      return;
    }
    if (!(await _confirmDiscardChanges())) {
      return;
    }

    final storedWorkout = _storedWorkout;
    setState(() {
      _displayMode = .display;
      if (storedWorkout != null) {
        _updateUiFromWorkout(storedWorkout);
      }
    });
  }

  Future<bool> _confirmDiscardChanges() async {
    // Return early if there are no changes to discard
    final editedWorkout = _buildWorkoutFromUi();
    if (editedWorkout == _storedWorkout) {
      return true;
    }

    return (await showAdaptiveDialog(
          context: context,
          builder: (BuildContext innerContext) => AlertDialog.adaptive(
            title: PlatformText(
              L10n.of(innerContext)!.confirmDiscardChangesAlertTitle,
            ),
            content: PlatformText(
              L10n.of(innerContext)!.confirmDiscardChangesAlertMessage,
            ),
            actions: [
              PlatformDialogAction(
                cupertino: (_, _) =>
                    CupertinoDialogActionData(isDefaultAction: true),
                onPressed: () => Navigator.of(innerContext).pop(false),
                child: PlatformText(L10n.of(innerContext)!.cancelAction),
              ),
              PlatformDialogAction(
                cupertino: (_, _) =>
                    CupertinoDialogActionData(isDestructiveAction: true),
                onPressed: () => Navigator.of(innerContext).pop(true),
                child: PlatformText(
                  L10n.of(innerContext)!.confirmDiscardChangesAlertButton,
                ),
              ),
            ],
          ),
        ) ??
        false);
  }

  /// Builds a [Workout] object from the current state of the UI fields and
  /// sections.
  Workout _buildWorkoutFromUi() => Workout(
    name: _nameTextController.text.trim(),
    date:
        _storedWorkout?.date ?? widget.originalWorkout?.date ?? DateTime.now(),
    sections: [
      for (final entry in _sections.entries)
        WorkoutSection(name: entry.key, exercises: List.of(entry.value)),
    ],
  );

  void _updateUiFromWorkout(Workout workout) {
    _nameTextController.text = workout.name;
    _sections
      ..clear()
      ..addEntries(
        workout.sections.map((s) => MapEntry(s.name, List.of(s.exercises))),
      );
  }
}
