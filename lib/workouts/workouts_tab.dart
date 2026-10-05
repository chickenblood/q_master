import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/l10n.dart';
import '../model/formatted_workout.dart';
import '../model/workout.dart';
import '../model/workout_list.dart';
import '../settings/settings_sheet.dart';
import '../slack/slackblast_picker_sheet.dart';
import '../ui/adaptive_app_bar.dart';
import '../ui/adaptive_icons.dart';
import '../ui/adaptive_menu.dart';
import '../ui/adaptive_modal_sheet.dart';
import '../ui/adaptive_scaffold.dart';
import '../ui/dismissible_row.dart';
import '../ui/menu_icons.dart';
import '../utils/datetime_utils.dart';
import 'beatdown_browser_screen.dart';
import 'create_workout_sheet.dart';
import 'generate_workout_sheet.dart';
import 'workout_creation_picker.dart' as creation_picker;

class WorkoutsTab extends ConsumerWidget {
  final ScrollController? _scrollController;
  const WorkoutsTab({super.key, ScrollController? scrollController})
    : _scrollController = scrollController;

  /// Shows the workout creation picker modal sheet.
  ///
  /// [context] the build context.
  /// [ref] the widget reference for accessing providers.
  static Future<void> showWorkoutCreationPicker({
    required BuildContext context,
    required WidgetRef ref,
    required GlassMorphAnchor? anchor,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    final result = await creation_picker.showWorkoutCreationPicker(
      context: navigator.context,
      anchor: anchor,
    );
    if (!context.mounted) return;

    if (result == .manual) {
      await invokeWorkoutEditor(context, displayMode: DisplayMode.edit);
    } else if (result == .generate) {
      await showGenerateWorkoutModal(context, ref: ref);
    }
  }

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

  static Future<void> showGenerateWorkoutModal(
    BuildContext context, {
    required WidgetRef ref,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    final workout = await showAdaptiveModalSheet(
      context: navigator.context,
      child: GenerateWorkoutSheet(),
    );
    if (!context.mounted) return;

    if (workout != null) {
      // Add the workout to the store before invoking the editor
      final listNotifier = ref.read(workoutListProvider.notifier);
      await listNotifier.add(workout);
      if (!context.mounted) return;

      await invokeWorkoutEditor(
        context,
        workout: workout,
        displayMode: DisplayMode.edit,
      );
    }
  }

  static Future<void> _shareWorkout(
    BuildContext context,
    Workout workout,
  ) async {
    // Get rect of button to present popovers from on iPad.
    final box = context.findRenderObject() as RenderBox;
    final sharePositionRect = box.localToGlobal(Offset.zero) & box.size;

    // Share as plain text (for Slack) and json (for another Q Master user on
    // Airdrop)
    final plainText = workout.formattedText;
    //final text = XFile.fromData(utf8.encode(plainText), mimeType: 'text/plain');

    final jsonText = workout.formattedJson;
    final json = XFile.fromData(
      utf8.encode(jsonText),
      mimeType: 'application/json',
    );
    await SharePlus.instance.share(
      ShareParams(
        text: plainText,
        files: [json],
        fileNameOverrides: ['workout.qmw'],
        sharePositionOrigin: sharePositionRect,
      ),
    );
  }

  Future<void> _showSlackblastPicker(BuildContext context, Workout workout) =>
      showSlackblastPicker(context, workout: workout);

  static Future<Workout?> invokeWorkoutEditor(
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
  static Future<void> _showBeatdownBrowser(
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
    return AdaptiveScaffold(
      appBar: AdaptiveAppBar(
        leading: [settingsGlassBarItem(id: 'left-item', context: context)],
        title: Text(
          L10n.of(context)!.workoutsTabTitle,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(maxScaleFactor: 1.6),
        ),
      ),
      body: workouts.isNotEmpty
          ? SafeArea(
              child: ReorderableListView.builder(
                scrollController: _scrollController,
                header: SizedBox.fromSize(
                  size: Size.fromHeight(adaptivePadding.top),
                ),
                footer: SizedBox.fromSize(
                  size: Size.fromHeight(adaptivePadding.bottom),
                ),
                itemCount: workouts.length,
                itemBuilder: (context, index) => _WorkoutTile(
                  key: ValueKey(workouts[index]),
                  listNotifier: listNotifier,
                  workout: workouts[index],
                  onInvokeWorkoutEditor: invokeWorkoutEditor,
                  onShareWorkout: _shareWorkout,
                  onShareToBackblast: _showSlackblastPicker,
                ),
                onReorderItem: listNotifier.move,
              ),
            )
          : _emptyContentPlaceholder(context),
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
  final Future<void> Function(BuildContext context, Workout workout)
  onShareToBackblast;

  const _WorkoutTile({
    required super.key,
    required this.listNotifier,
    required this.workout,
    required this.onInvokeWorkoutEditor,
    required this.onShareWorkout,
    required this.onShareToBackblast,
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
          child: GlassListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
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
            trailing: _OverflowMenu(
              onDuplicate: () => _duplicateWorkout(workout),
              onShare: (buttonContext) =>
                  onShareWorkout(buttonContext, workout),
              onShareToBackblast: (buttonContext) =>
                  onShareToBackblast(buttonContext, workout),
              onDelete: () => _deleteWorkout(context, workout),
            ),
            onTap: () => onInvokeWorkoutEditor(
              context,
              workout: workout,
              displayMode: .display,
            ),
          ),
        ),
        Divider(indent: 16, endIndent: isIOS ? 16 : 24),
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
  final void Function(BuildContext) onShareToBackblast;
  final void Function() onDelete;

  const _OverflowMenu({
    required this.onDuplicate,
    required this.onShare,
    required this.onShareToBackblast,
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
            onPressed: () => onShareToBackblast(menuContext),
            icon: Icon(Menu.slack),
            title: L10n.of(context)!.postToBackblastText,
          ),
          AdaptiveMenuItem(
            onPressed: () => onDuplicate(),
            icon: Icon(Icons.copy),
            title: L10n.of(context)!.duplicateWorkoutText,
          ),
          AdaptiveMenuItem(
            onPressed: () => onShare(menuContext),
            icon: Icon(context.platformIcons.share),
            title: L10n.of(context)!.shareWorkoutText,
          ),
          AdaptiveMenuItem(
            onPressed: onDelete,
            icon: Icon(context.platformIcons.delete),
            title: L10n.of(context)!.deleteWorkoutText,
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}
