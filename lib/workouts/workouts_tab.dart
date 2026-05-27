import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/l10n.dart';
import '../model/formatted_workout.dart';
import '../model/workout.dart';
import '../model/workout_list.dart';
import '../settings/settings_sheet.dart';
import '../ui/adaptive_icons.dart';
import '../ui/adaptive_menu.dart';
import '../ui/adaptive_modal_sheet.dart';
import '../ui/dismissible_row.dart';
import '../utils/datetime_utils.dart';
import 'beatdown_browser_screen.dart';
import 'create_workout_sheet.dart';
import 'generate_workout_sheet.dart';
import 'workout_creation_picker.dart';

class WorkoutsTab extends ConsumerWidget {
  const WorkoutsTab({super.key});

  Widget _emptyContentPlaceholder(BuildContext context) => SafeArea(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Spacer(),
            Icon(
              AdaptiveIcons.history,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              L10n.of(context)!.noWorkoutsPlaceholderText,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              L10n.of(context)!.noWorkoutsPlaceholderDetailText,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.6),
              textAlign: TextAlign.center,
            ),
            Spacer(),
          ],
        ),
      ),
    ),
  );

  Future<void> _showGenerateWorkoutModal(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    final workout = await showAdaptiveModalSheet(
      context: navigator.context,
      child: GenerateWorkoutSheet(),
    );
    if (!context.mounted) return;

    if (workout != null) {
      // Add the workout to the store before invoking the editor
      final listNotifier = ref.read(workoutListProvider.notifier);
      listNotifier.add(workout);

      await _invokeWorkoutEditor(
        context,
        workout: workout,
        displayMode: DisplayMode.edit,
      );
    }
  }

  Future<void> _showWorkoutCreationPicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final colorScheme = Theme.of(context).colorScheme;

    final result = await showModalBottomSheet<WorkoutCreationType>(
      context: navigator.context,
      clipBehavior: .antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      builder: (context) => const WorkoutCreationPicker(),
    );
    if (!context.mounted) return;

    if (result == .manual) {
      await _invokeWorkoutEditor(context, displayMode: DisplayMode.edit);
    } else if (result == .generate) {
      await _showGenerateWorkoutModal(context, ref);
    }
  }

  void _shareWorkout(BuildContext context, Workout workout) {
    // Get rect of button to present popovers from on iPad.
    final box = context.findRenderObject() as RenderBox;
    final sharePositionRect = box.localToGlobal(Offset.zero) & box.size;

    SharePlus.instance.share(
      ShareParams(
        text: workout.formattedText(context),
        sharePositionOrigin: sharePositionRect,
      ),
    );
  }

  Future<Workout?> _invokeWorkoutEditor(
    BuildContext context, {
    Workout? workout,
    required DisplayMode displayMode,
  }) => Navigator.of(context, rootNavigator: false).push(
    platformPageRoute(
      //fullscreenDialog: true,
      context: context,
      builder: (_) => CreateWorkoutSheet(
        originalWorkout: workout,
        initialDisplayMode: displayMode,
        onShare: _shareWorkout,
        onShowBeatdownBrowser: _showBeatdownBrowser,
      ),
    ),
  );

  Future<void> _showBeatdownBrowser(
    BuildContext context,
    Workout workout,
  ) async {
    // Stop the screen from sleeping while the beatdown browser is shown.
    WakelockPlus.enable();

    await Navigator.of(context).pushReplacement(
      platformPageRoute(
        context: context,
        builder: (context) => BeatdownBrowser(workout: workout),
      ),
    );

    WakelockPlus.disable();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutListProvider);
    final listNotifier = ref.read(workoutListProvider.notifier);
    return SafeArea(
      child: PlatformScaffold(
        appBar: PlatformAppBar(
          leading: SettingsActionButton(),
          title: Text(
            L10n.of(context)!.workoutsTabTitle,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: 1.6),
          ),
          cupertino: (appBarContext, _) => CupertinoNavigationBarData(
            backgroundColor: Colors.transparent,
            trailing: PlatformIconButton(
              icon: Icon(
                PlatformIcons(context).add,
                color: Theme.of(appBarContext).colorScheme.onSurface,
              ),
              cupertino: (context, platform) =>
                  CupertinoIconButtonData(padding: EdgeInsets.only(left: 16)),
              onPressed: () => _showWorkoutCreationPicker(context, ref),
            ),
          ),
        ),
        body: workouts.isNotEmpty
            ? ReorderableListView.builder(
                header: Theme.of(context).platform == .iOS
                    ? SizedBox.fromSize(
                        size: const Size.fromHeight(kToolbarHeight),
                      )
                    : null,
                itemCount: workouts.length,
                itemBuilder: (context, index) => _WorkoutTile(
                  key: ValueKey(workouts[index]),
                  listNotifier: listNotifier,
                  workout: workouts[index],
                  onInvokeWorkoutEditor: _invokeWorkoutEditor,
                  onShareWorkout: _shareWorkout,
                ),
                onReorder: (oldIndex, newIndex) =>
                    listNotifier.move(oldIndex, newIndex),
              )
            : _emptyContentPlaceholder(context),
        material: (innerContext, _) => MaterialScaffoldData(
          floatingActionButton: Builder(
            builder: (fabContext) => FloatingActionButton(
              backgroundColor: Theme.of(fabContext).colorScheme.primary,
              foregroundColor: Theme.of(fabContext).colorScheme.onPrimary,
              child: Icon(
                PlatformIcons(fabContext).add,
                color: Theme.of(fabContext).colorScheme.onPrimary,
              ),
              onPressed: () => _showWorkoutCreationPicker(fabContext, ref),
            ),
          ),
        ),
      ),
    );
  }
}

final class _WorkoutTile extends StatelessWidget {
  final WorkoutList listNotifier;
  final Workout workout;
  final Future<Workout?> Function(
    BuildContext context, {
    Workout? workout,
    required DisplayMode displayMode,
  })
  onInvokeWorkoutEditor;
  final void Function(BuildContext context, Workout workout) onShareWorkout;

  const _WorkoutTile({
    required super.key,
    required this.listNotifier,
    required this.workout,
    required this.onInvokeWorkoutEditor,
    required this.onShareWorkout,
  });

  Future<bool?> _confirmDelete(BuildContext context) => showAdaptiveDialog(
    context: context,
    builder: (BuildContext innerContext) => AlertDialog.adaptive(
      title: PlatformText(L10n.of(context)!.deleteWorkoutAlertTitle),
      content: PlatformText(L10n.of(context)!.deleteWorkoutAlertDescription),
      actions: [
        PlatformDialogAction(
          cupertino: (_, _) =>
              CupertinoDialogActionData(isDestructiveAction: true),
          onPressed: () => Navigator.pop(innerContext, true),
          child: PlatformText(
            L10n.of(innerContext)!.deleteWorkoutConfirmAction,
          ),
        ),
        PlatformDialogAction(
          cupertino: (_, _) => CupertinoDialogActionData(isDefaultAction: true),
          onPressed: () => Navigator.pop(innerContext, false),
          child: PlatformText(L10n.of(innerContext)!.cancelAction),
        ),
      ],
    ),
  );

  void _duplicateWorkout(Workout workout) async {
    listNotifier.duplicate(workout);
  }

  void _deleteWorkout(BuildContext context, Workout workout) async {
    if (await _confirmDelete(context) == true) {
      listNotifier.remove(workout);
    }
  }

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    const maxSectionsToDisplayInTile = 3;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DismissibleRow(
          key: ValueKey(workout),
          backgroundPadding: const EdgeInsets.fromLTRB(36, 0, 36, 0),
          confirmDismiss: (direction) {
            if (direction == .endToStart) return _confirmDelete(context);
            return Future.value(true);
          },
          onDismissed: (direction) {
            if (direction == .endToStart) listNotifier.remove(workout);
          },
          child: PlatformListTile(
            material: (context, platform) =>
                MaterialListTileData(contentPadding: padding),
            cupertino: (context, platform) =>
                CupertinoListTileData(padding: padding),
            title: PlatformText(
              workout.name,
              style: TextTheme.of(context).titleMedium,
              overflow: .ellipsis,
              textScaler: MediaQuery.textScalerOf(
                context,
              ).clamp(maxScaleFactor: 1.3),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (workout.sections.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5, bottom: 3),
                    child: Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        for (final section in workout.sections.take(
                          maxSectionsToDisplayInTile,
                        ))
                          _SectionChip(name: section.name),
                      ],
                    ),
                  ),
                Text(
                  workout.date.formattedForDisplay(),
                  style: TextTheme.of(context).bodyMedium,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OverflowMenu(
                  onDuplicate: () => _duplicateWorkout(workout),
                  onShare: (buttonContext) =>
                      onShareWorkout(buttonContext, workout),
                  onDelete: () => _deleteWorkout(context, workout),
                ),
                if (isIOS) ...[
                  const SizedBox(width: 6),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
            onTap: () => onInvokeWorkoutEditor(
              context,
              workout: workout,
              displayMode: .display,
            ),
          ),
        ),
        const Divider(),
      ],
    );
  }
}

final class _SectionChip extends StatelessWidget {
  final String name;

  const _SectionChip({required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipBg = theme.colorScheme.surfaceContainerHighest;
    final chipBorder =
        theme.colorScheme.outline; // Use outline for lighter border
    final chipFg = theme.colorScheme.onSurfaceVariant;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: chipBg,
        border: Border.all(color: chipBorder),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          name.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: chipFg,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

final class _OverflowMenu extends StatelessWidget {
  final void Function() onDuplicate;
  final void Function(BuildContext) onShare;
  final void Function() onDelete;

  const _OverflowMenu({
    required this.onDuplicate,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (menuContext) => AdaptiveMenu(
        icon: Icon(
          AdaptiveIcons.more,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        menuChildren: [
          AdaptiveMenuItem(
            onPressed: () => onDuplicate(),
            icon: Icons.copy,
            text: L10n.of(context)!.duplicateWorkoutText,
          ),
          AdaptiveMenuItem(
            onPressed: () => onShare(menuContext),
            icon: context.platformIcons.share,
            text: L10n.of(context)!.shareWorkoutText,
          ),
          AdaptiveMenuItem(
            onPressed: onDelete,
            icon: context.platformIcons.delete,
            text: L10n.of(context)!.deleteWorkoutText,
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}
