import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/l10n.dart';
import '../model/workout.dart';
import '../theme/theme.dart';
import '../ui/action_button.dart';
import '../ui/adaptive_icons.dart';
import '../ui/cupertino_sheet_fork.dart';
import '../ui/dismissible_row.dart';
import '../utils/datetime_utils.dart';
import 'beatdown_browser_screen.dart';
import 'exercise_picker_sheet.dart';

/// The display mode the dialog is initially displayed in.
///
/// In [display] mode, the workout details are shown read-only with options to
/// 1) edit (which switches to [edit] mode),
/// 2) share
/// 3) Start the beatdown.
enum DisplayMode { display, edit }

final class CreateWorkoutSheet extends StatefulWidget {
  final Workout? workout;
  final DisplayMode initialDisplayMode;
  final Function(BuildContext context, Workout workout)? onShare;
  final Function(Workout workout)? onShowBeatdownBrowser;

  const CreateWorkoutSheet({
    super.key,
    this.workout,
    this.initialDisplayMode = DisplayMode.display,
    this.onShare,
    this.onShowBeatdownBrowser,
  });

  @override
  State<CreateWorkoutSheet> createState() => _CreateWorkoutSheetState();
}

final class _CreateWorkoutSheetState extends State<CreateWorkoutSheet> {
  static const _headerInsets = EdgeInsets.only(left: 16.0, right: 8.0);

  final _focusNode = FocusNode();
  final _nameTextController = TextEditingController();
  final _scrollController = ScrollController();

  final _sections = <String, List<String>>{};

  Workout? _workout;
  var _displayMode = DisplayMode.display;

  // Track the group of the most recently added exercise for scrolling
  String? _lastAddedItemGroup;

  @override
  void initState() {
    super.initState();

    // Rebuild when app is resumed to update the UI if the pasteboard contents
    // have changed.
    AppLifecycleListener(onResume: () => setState(() {}));

    _workout = widget.workout;
    if (_workout != null) {
      _nameTextController.text = _workout!.name;
      final sectionMap = {
        for (final s in _workout!.sections) s.name: List.of(s.exercises),
      };
      _sections.clear();
      _sections.addAll(sectionMap);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _displayMode = widget.initialDisplayMode;
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
    //Navigator.pop(context, workout);
    setState(() => _displayMode = .display);
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
            child: PlatformText(L10n.of(innerContext)!.addSectionDialogTitle),
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
    icon: Icon(
      PlatformIcons(context).add,
      color: Theme.of(context).colorScheme.primary,
    ),
    onPressed: () async {
      _focusNode.unfocus();
      final exercise = await showExercisePicker(context);
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
    final updatedExercise = await showExercisePicker(
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

  Future<void> showBeatdownBrowser(
    BuildContext context,
    Workout workout,
  ) async {
    // Stop the screen from sleeping while the beatdown browser is shown.
    WakelockPlus.enable();

    await Navigator.of(context, rootNavigator: true).push(
      platformPageRoute(
        context: context,
        builder: (context) => BeatdownBrowser(workout: workout),
      ),
    );

    WakelockPlus.disable();
  }

  List<Widget> _content(BuildContext context) {
    final sectionOrder = _sections.keys.toList(growable: false);
    return [
      SliverSafeArea(
        top: false,
        bottom: false,
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: _headerInsets,
              child: PlatformTextField(
                controller: _nameTextController,
                enabled: _displayMode == DisplayMode.edit,
                textCapitalization: TextCapitalization.sentences,
                focusNode: _focusNode,
                material: (_, _) => MaterialTextFieldData(
                  decoration: InputDecoration(
                    border: const UnderlineInputBorder(),
                    enabledBorder: const UnderlineInputBorder(),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: -0.3,
                  ),
                  cursorColor: Theme.of(context).colorScheme.primary,
                  textAlign: TextAlign.left,
                ),
                cupertino: (_, _) => CupertinoTextFieldData(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1.5,
                      ),
                    ),
                  ),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: -0.3,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  cursorColor: Theme.of(context).colorScheme.primary,
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            if (_displayMode == .display && widget.workout != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  widget.workout!.date.formattedForDisplay(),
                  style: Theme.of(context).textTheme.bodyMedium,
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
                            child: Container(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 8,
                                top: 5,
                                bottom: 5,
                              ),
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
                                                color: Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge?.color,
                                                fontSize: 16,
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
                                          right: 16.0,
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
      if (_displayMode == DisplayMode.edit) _addSectionFooter(context),
    ];
  }

  List<Widget> _rightAppBarButtonActions(BuildContext context) {
    if (_displayMode == .display) return [];
    return [
      ListenableBuilder(
        listenable: Listenable.merge([_nameTextController]),
        builder: (_, _) => PlatformIconButton(
          padding: Theme.of(context).platform == TargetPlatform.iOS
              ? EdgeInsets.only(right: 26)
              : EdgeInsets.only(right: 16),
          icon: Icon(
            PlatformIcons(context).checkMark,
            color: Theme.of(context).colorScheme.primary, // F3 Red
          ),
          onPressed: _workoutCreationEnabled
              ? () => _createWorkout(context)
              : null,
        ),
      ),
    ];
  }

  Widget _pasteExercisesButton(BuildContext context) => FutureBuilder(
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
    final isEditingMode = _displayMode == DisplayMode.edit;
    return DismissibleRow(
      key: ValueKey('dismissible_$sectionTitle'),
      onDismissed: (_) {
        setState(() {
          _sections.remove(sectionTitle);
        });
      },
      child: ReorderableDelayedDragStartListener(
        index: sectionIndex,
        enabled: !isEditingMode,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          color: Theme.of(context).colorScheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    sectionTitle.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
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
                        Icons.edit,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20,
                      ),
                      tooltip: 'Edit Section',
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
    );
  }

  Widget _addSectionFooter(BuildContext context) => SliverSafeArea(
    top: false,
    sliver: SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
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
            _pasteExercisesButton(context),
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
                    onPressed: () =>
                        setState(() => _displayMode = DisplayMode.edit),
                  ),
                ),
                Expanded(
                  child: ActionButton(
                    label: L10n.of(context)!.shareWorkoutButtonText,
                    icon: PlatformIcons(context).share,
                    outlined: true,
                    onPressed: () =>
                        widget.onShare?.call(context, widget.workout!),
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
                  //Navigator.of(context).pop(null);
                  widget.onShowBeatdownBrowser?.call(_workout!);
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );

  String _titleForAppBar() {
    if (_displayMode == DisplayMode.edit) {
      return widget.workout == null
          ? L10n.of(context)!.createWorkoutDialogTitle
          : L10n.of(context)!.editWorkoutDialogTitle;
    } else {
      return widget.workout?.name ?? '';
    }
  }

  @override
  Widget build(BuildContext context) => PlatformScaffold(
    body: CustomScrollView(
      controller: _scrollController,
      physics: BottomSheetScrollPhysics(),
      slivers: [
        SliverAppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: PlatformIconButton(
            padding: Theme.of(context).platform == TargetPlatform.iOS
                ? EdgeInsets.only(left: 8)
                : EdgeInsets.zero,
            icon: _displayMode == DisplayMode.display
                ? Icon(PlatformIcons(context).back)
                : Icon(AdaptiveIcons.close),
            onPressed: () {
              if (_displayMode == DisplayMode.display) {
                Navigator.of(context).pop();
                return;
              }
              setState(() => _displayMode = DisplayMode.display);
            },
          ),
          title: PlatformText(
            _titleForAppBar(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: 1.5),
          ),
          actions: _rightAppBarButtonActions(context),
          pinned: true,
        ),
        ..._content(context),
        if (_displayMode == DisplayMode.display) _displayFooter(context),
      ],
    ),
  );
}
