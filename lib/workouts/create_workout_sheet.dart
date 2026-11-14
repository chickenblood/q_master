import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../model/workout.dart';
import '../model/workout_list_controller.dart';
import '../theme/theme.dart';
import '../ui/action_button.dart';
import '../ui/adaptive_widgets.dart';
import '../ui/dismissible_row.dart';
import 'exercise_picker_sheet.dart';

final class _SectionDraft {
  _SectionDraft({required this.name, List<String>? exercises})
    : exercises = exercises ?? [];

  String name;
  final List<String> exercises;
}

final class _DraggedExercise {
  const _DraggedExercise({
    required this.section,
    required this.index,
    required this.name,
  });

  final _SectionDraft section;
  final int index;
  final String name;
}

final class CreateWorkoutSheet extends ConsumerStatefulWidget {
  final Workout? originalWorkout;
  final Function(BuildContext context, Workout workout)? onShare;
  final Function(BuildContext context, Workout workout)? onShowBeatdownBrowser;

  const CreateWorkoutSheet({
    super.key,
    this.originalWorkout,
    this.onShare,
    this.onShowBeatdownBrowser,
  });

  @override
  ConsumerState<CreateWorkoutSheet> createState() => _CreateWorkoutSheetState();
}

final class _CreateWorkoutSheetState extends ConsumerState<CreateWorkoutSheet> {
  static const _headerInsets = EdgeInsets.symmetric(horizontal: 16.0);

  final _focusNode = FocusNode();
  final _nameTextController = TextEditingController();

  final _sections = <_SectionDraft>[];

  // For storing the original workout when in edit mode, so we can revert to it
  // if the user cancels out of editing.
  Workout? _storedWorkout;
  Workout? _persistedWorkout;
  var _pickerIsShown = false;

  // The exercise row to scroll into view after the next build.
  ({_SectionDraft section, int index})? _scrollTarget;
  EdgeDraggingAutoScroller? _exerciseAutoScroller;
  Offset? _lastDragPosition;
  late final AppLifecycleListener _appLifecycleListener;

  // --- Lifecycle & State ---
  @override
  void initState() {
    super.initState();
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
      _persistedWorkout = workout;
      _updateUiFromWorkout(workout);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (workout == null) {
        setState(() {
          _sections.add(
            _SectionDraft(name: L10n.of(context)!.warmupSectionTitle),
          );
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
    _exerciseAutoScroller?.stopAutoScroll();
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

  // --- Section & Exercise Manipulation ---
  bool _canAcceptDraggedExercise(_DraggedExercise draggedExercise) {
    final sourceExercises = draggedExercise.section.exercises;
    return _sections.any(
          (section) => identical(section, draggedExercise.section),
        ) &&
        draggedExercise.index >= 0 &&
        draggedExercise.index < sourceExercises.length &&
        sourceExercises[draggedExercise.index] == draggedExercise.name;
  }

  void _moveExerciseToSection({
    required _DraggedExercise draggedExercise,
    required _SectionDraft targetSection,
    required int targetIndex,
  }) {
    if (!_canAcceptDraggedExercise(draggedExercise) ||
        !_sections.any((section) => identical(section, targetSection))) {
      return;
    }

    final sourceSection = draggedExercise.section;
    final sourceIndex = draggedExercise.index;
    final adjustedTargetIndex =
        identical(sourceSection, targetSection) && sourceIndex < targetIndex
        ? targetIndex - 1
        : targetIndex;
    if (identical(sourceSection, targetSection) &&
        sourceIndex == adjustedTargetIndex) {
      return;
    }

    setState(() {
      final exercise = sourceSection.exercises.removeAt(sourceIndex);
      final insertIndex = adjustedTargetIndex.clamp(
        0,
        targetSection.exercises.length,
      );
      targetSection.exercises.insert(insertIndex, exercise);
      _scrollTarget = (section: targetSection, index: insertIndex);
    });
  }

  void _moveSection({required int fromIndex, required int toIndex}) {
    final section = _sections.removeAt(fromIndex);
    _sections.insert(toIndex, section);
  }

  /// Whether [itemContext]'s box lies entirely within its scrollable viewport.
  bool _isFullyVisible(BuildContext itemContext) {
    final box = itemContext.findRenderObject();
    final scrollContext = Scrollable.maybeOf(itemContext)?.context;
    final viewport = scrollContext?.findRenderObject();
    if (box is! RenderBox || viewport is! RenderBox) return false;
    final itemRect = box.localToGlobal(Offset.zero) & box.size;
    final viewportRect = viewport.localToGlobal(Offset.zero) & viewport.size;
    return viewportRect.contains(itemRect.topLeft) &&
        viewportRect.contains(itemRect.bottomRight);
  }

  void _updateExerciseAutoScroll(Offset globalPosition) {
    _lastDragPosition = globalPosition;
    final autoScroller = _exerciseAutoScroller;
    if (autoScroller == null) return;

    final scrollable = autoScroller.scrollable;
    final viewport = scrollable.context.findRenderObject()! as RenderBox;
    final viewportRect = viewport.localToGlobal(Offset.zero) & viewport.size;
    const edgeExtent = 72.0;
    var dragTarget = Rect.fromCenter(
      center: globalPosition,
      width: 1,
      height: 1,
    );

    if (globalPosition.dy < viewportRect.top + edgeExtent) {
      final overscroll = (edgeExtent - (globalPosition.dy - viewportRect.top))
          .clamp(0.0, edgeExtent);
      dragTarget = Rect.fromCenter(
        center: Offset(globalPosition.dx, viewportRect.top - overscroll),
        width: 1,
        height: 1,
      );
    } else if (globalPosition.dy > viewportRect.bottom - edgeExtent) {
      final overscroll =
          (edgeExtent - (viewportRect.bottom - globalPosition.dy)).clamp(
            0.0,
            edgeExtent,
          );
      dragTarget = Rect.fromCenter(
        center: Offset(globalPosition.dx, viewportRect.bottom + overscroll),
        width: 1,
        height: 1,
      );
    }

    autoScroller.startAutoScrollIfNecessary(dragTarget);
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
    return showAlertDialog<String>(
      context: context,
      title: title,
      content: PlatformTextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        hintText: hintText,
        onSubmitted: (_) => Navigator.of(
          context,
          rootNavigator: true,
        ).pop(controller.text.trim()),
      ),
      actions: [
        AdaptiveDialogAction(
          isPrimary: true,
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          title: L10n.of(context)!.cancelAction,
        ),
        AdaptiveDialogAction(
          isDestructive: true,
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(controller.text),
          title: buttonTitle,
        ),
      ],
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
    setState(() {
      _sections.add(_SectionDraft(name: trimmedName));
    });
  }

  Future<void> _pasteExercises({required _SectionDraft section}) async {
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
      section.exercises.addAll(lines);
      _scrollTarget = (section: section, index: section.exercises.length - 1);
    });
  }

  void _editSectionTitle(
    BuildContext context, {
    required _SectionDraft section,
  }) async {
    final updatedTitle = await _showNameChangeDialog(
      context,
      title: L10n.of(context)!.updateSectionDialogTitle,
      buttonTitle: L10n.of(context)!.updateSectionDialogButtonText,
      initialText: section.name,
    );
    final trimmedName = updatedTitle?.trim();
    if (trimmedName == null || trimmedName.isEmpty) return;
    setState(() {
      section.name = trimmedName;
    });
  }

  Widget _addExerciseButton(
    BuildContext context, {
    required _SectionDraft section,
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
            section.exercises.add(exercise);
            _scrollTarget = (
              section: section,
              index: section.exercises.length - 1,
            );
          });
        },
      ).then((_) => setState(() => _pickerIsShown = false));
    },
  );

  void _editExercise(
    BuildContext context, {
    required List<String> exercises,
    required int index,
    required _SectionDraft section,
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
        _scrollTarget = (section: section, index: index);
      });
    }
  }

  Widget _exerciseRow(
    BuildContext context, {
    required _SectionDraft section,
    required int exerciseIndex,
  }) {
    final exercise = section.exercises[exerciseIndex];
    final exercises = section.exercises;
    final draggedExercise = _DraggedExercise(
      section: section,
      index: exerciseIndex,
      name: exercise,
    );
    final row = DismissibleRow(
      key: ValueKey('dismissible_${identityHashCode(section)}_$exerciseIndex'),
      enabled: true,
      onDismissed: (direction) {
        setState(() {
          exercises.removeAt(exerciseIndex);
        });
      },
      child: Builder(
        builder: (itemContext) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final target = _scrollTarget;
            if (target != null &&
                identical(target.section, section) &&
                target.index == exerciseIndex) {
              _scrollTarget = null;
              if (itemContext.mounted && !_isFullyVisible(itemContext)) {
                Scrollable.ensureVisible(
                  itemContext,
                  duration: const Duration(milliseconds: 300),
                  alignment: 0.5,
                  alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
                );
              }
            }
          });
          return GestureDetector(
            onDoubleTap: () => _editExercise(
              context,
              exercises: exercises,
              index: exerciseIndex,
              section: section,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 5, 8, 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: PlatformListTile(
                      key: ValueKey(
                        'exercise_${identityHashCode(section)}_$exerciseIndex',
                      ),
                      title: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          exercise,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: .ellipsis,
                          textAlign: .left,
                        ),
                      ),
                      material: (context, platform) => MaterialListTileData(
                        contentPadding: EdgeInsets.only(left: 0, right: 8),
                      ),
                      cupertino: (context, platform) => CupertinoListTileData(
                        padding: EdgeInsets.only(left: 0, right: 8),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Icon(
                      Icons.drag_handle,
                      color: ThemeColors.dragHandle(context),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final dropTargetKey = GlobalKey();
    return DragTarget<_DraggedExercise>(
      onWillAcceptWithDetails: (details) =>
          _canAcceptDraggedExercise(details.data),
      onAcceptWithDetails: (details) {
        final box =
            dropTargetKey.currentContext!.findRenderObject()! as RenderBox;
        final localPosition = box.globalToLocal(details.offset);
        final targetIndex =
            exerciseIndex + (localPosition.dy >= box.size.height / 2 ? 1 : 0);
        _moveExerciseToSection(
          draggedExercise: details.data,
          targetSection: section,
          targetIndex: targetIndex,
        );
      },
      builder: (context, candidates, rejected) => LongPressDraggable(
        data: draggedExercise,
        onDragStarted: () {
          _exerciseAutoScroller?.stopAutoScroll();
          _exerciseAutoScroller = EdgeDraggingAutoScroller(
            Scrollable.of(context),
            velocityScalar: 10,
            // The scroller keeps its target fixed in scroll space, so refresh
            // it after each step to keep scrolling while the pointer is still.
            onScrollViewScrolled: () {
              final position = _lastDragPosition;
              if (position != null) _updateExerciseAutoScroll(position);
            },
          );
        },
        onDragUpdate: (details) {
          _updateExerciseAutoScroll(details.globalPosition);
        },
        onDragEnd: (_) {
          _exerciseAutoScroller?.stopAutoScroll();
          _exerciseAutoScroller = null;
          _lastDragPosition = null;
        },
        feedback: Material(
          color: Theme.of(context).colorScheme.surface,
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(exercise, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: row),
        child: DecoratedBox(
          key: dropTargetKey,
          decoration: BoxDecoration(
            color: candidates.isNotEmpty
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                : null,
          ),
          child: row,
        ),
      ),
    );
  }

  Widget _exerciseDropTarget({
    required _SectionDraft section,
    required int targetIndex,
  }) => DragTarget<_DraggedExercise>(
    key: ValueKey('exercise_drop_target_${identityHashCode(section)}'),
    onWillAcceptWithDetails: (details) =>
        _canAcceptDraggedExercise(details.data),
    onAcceptWithDetails: (details) => _moveExerciseToSection(
      draggedExercise: details.data,
      targetSection: section,
      targetIndex: targetIndex,
    ),
    builder: (context, candidates, rejected) => SizedBox(
      height: section.exercises.isEmpty ? 44 : 20,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: candidates.isNotEmpty
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
              : null,
        ),
      ),
    ),
  );

  List<Widget> content(BuildContext context) {
    return [
      SliverSafeArea(
        top: false,
        bottom: false,
        sliver: SliverReorderableList(
          itemCount: _sections.length,
          itemBuilder: (context, sectionIndex) {
            final section = _sections[sectionIndex];
            final exercises = section.exercises;
            return Column(
              key: ValueKey(section),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionHeader(
                  context,
                  section: section,
                  sectionIndex: sectionIndex,
                ),
                for (
                  var exerciseIndex = 0;
                  exerciseIndex < exercises.length;
                  exerciseIndex++
                )
                  _exerciseRow(
                    context,
                    section: section,
                    exerciseIndex: exerciseIndex,
                  ),
                _exerciseDropTarget(
                  section: section,
                  targetIndex: exercises.length,
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
      addSectionFooter(context),
    ];
  }

  List<AdaptiveAppBarItem> _rightAppBarButtonItems(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled =
        _nameTextController.text.isNotEmpty &&
        _storedWorkout != _buildWorkoutFromUi();
    final enabledColor = theme.colorScheme.primary;
    final disabledColor = theme.colorScheme.onSurfaceVariant;
    return [
      AdaptiveAppBarItem(
        id: 'right_item',
        icon: Icon(
          PlatformIcons(context).checkMark,
          color: isEnabled ? enabledColor : disabledColor,
        ),
        onPressed: isEnabled
            ? () async {
                final savedWorkout = await _saveWorkout();
                if (!mounted) return;
                setState(() {
                  _storedWorkout = savedWorkout;
                  _dismissEditor();
                });
              }
            : null,
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
                  final trimmedName = newSectionName?.trim();
                  if (trimmedName == null || trimmedName.isEmpty) return;
                  final section = _SectionDraft(name: trimmedName);
                  setState(() => _sections.add(section));
                  _pasteExercises(section: section);
                }
              : null,
        ),
      );
    },
  );

  Widget _sectionHeader(
    BuildContext context, {
    required _SectionDraft section,
    required int sectionIndex,
  }) {
    return DismissibleRow(
      key: ValueKey(section),
      enabled: true,
      onDismissed: (_) {
        setState(() {
          _sections.remove(section);
        });
      },
      child: ReorderableDelayedDragStartListener(
        index: sectionIndex,
        enabled: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
          color: Theme.of(context).colorScheme.surface,
          child: GestureDetector(
            onDoubleTap: () => _editSectionTitle(context, section: section),
            child: Row(
              mainAxisAlignment: .spaceBetween,
              crossAxisAlignment: .center,
              children: [
                Expanded(
                  child: PlatformText(
                    section.name.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: .1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        PlatformIcons(context).edit,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20,
                      ),
                      tooltip: L10n.of(context)!.editSectionTooltip,
                      onPressed: () =>
                          _editSectionTitle(context, section: section),
                    ),
                    _addExerciseButton(context, section: section),
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
        child: SizedBox(
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
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _dismissEditor();
    },
    child: ListenableBuilder(
      listenable: _nameTextController,
      builder: (_, _) => AdaptiveScaffold(
        appBar: AdaptiveAppBar(
          backgroundColor: Colors.transparent,
          leading: [
            AdaptiveAppBarItem(
              id: 'left-item',
              icon: Icon(AdaptiveIcons.close),
              onPressed: _handleClose,
            ),
          ],
          title: _titleForAppBar(context),
          actions: _rightAppBarButtonItems(context),
        ),
        body: SafeArea(
          child: CustomScrollView(
            primary: true,
            slivers: [
              SliverPadding(padding: EdgeInsets.only(top: adaptivePadding.top)),
              ...content(context),
              SliverPadding(
                padding: EdgeInsets.only(bottom: adaptivePadding.bottom),
              ),
              // Add padding when the picker is up, so we can scroll the content
              // above the keyboard and picker without it being obscured
              if (_pickerIsShown)
                SliverFillRemaining(child: SizedBox(height: 800)),
            ],
          ),
        ),
        bottomBar: AdaptiveButtonBar(
          mainAxisAlignment: .end,
          items: [
            AdaptiveButtonBarItem(
              icon: Icon(PlatformIcons(context).playArrowSolid),
              onPressed: () {
                widget.onShowBeatdownBrowser?.call(
                  context,
                  _buildWorkoutFromUi(),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );

  // Returns the title widget for the app bar based on the current display mode.
  Widget _titleForAppBar(BuildContext context) {
    return Padding(
      padding: _headerInsets,
      child: AdaptiveNavTextField(
        controller: _nameTextController,
        enabled: true,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
        focusNode: _focusNode,
        textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Future<Workout> _saveWorkout() async {
    final workoutToSave = _buildWorkoutFromUi().copyWith(date: DateTime.now());
    final listNotifier = ref.read(workoutListControllerProvider.notifier);
    final persistedWorkout = _persistedWorkout;
    if (persistedWorkout == null) {
      await listNotifier.add(workoutToSave);
      _persistedWorkout = workoutToSave;
    } else {
      await listNotifier.replace(persistedWorkout, workoutToSave);
      _persistedWorkout = workoutToSave;
    }
    return workoutToSave;
  }

  Future<void> _handleClose() async {
    if (!(await _confirmDiscardChanges())) {
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<bool> _confirmDiscardChanges() async {
    // Return early if there are no changes to discard
    final editedWorkout = _buildWorkoutFromUi();
    if (editedWorkout == _storedWorkout) {
      return true;
    }

    return await showAlertDialog<bool>(
          context: context,
          title: L10n.of(context)!.confirmDiscardChangesAlertTitle,
          message: L10n.of(context)!.confirmDiscardChangesAlertMessage,
          actions: [
            AdaptiveDialogAction(
              isPrimary: true,
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(false),
              title: L10n.of(context)!.cancelAction,
            ),
            AdaptiveDialogAction(
              isDestructive: true,
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(true),
              title: L10n.of(context)!.confirmDiscardChangesAlertButton,
            ),
          ],
        ) ??
        false;
  }

  Future<void> _dismissEditor() async {
    if (!await _confirmDiscardChanges()) return;
    if (mounted) Navigator.of(context).pop();
  }

  /// Builds a [Workout] object from the current state of the UI fields and
  /// sections.
  Workout _buildWorkoutFromUi() => Workout(
    name: _nameTextController.text.trim(),
    date:
        _storedWorkout?.date ?? widget.originalWorkout?.date ?? DateTime.now(),
    sections: [
      for (final section in _sections)
        WorkoutSection(
          name: section.name,
          exercises: List.of(section.exercises),
        ),
    ],
  );

  void _updateUiFromWorkout(Workout workout) {
    _nameTextController.text = workout.name;
    _sections
      ..clear()
      ..addAll(
        workout.sections.map(
          (section) => _SectionDraft(
            name: section.name,
            exercises: List.of(section.exercises),
          ),
        ),
      );
  }
}
