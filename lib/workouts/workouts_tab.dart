import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../l10n/l10n.dart';
import '../model/formatted_workout.dart';
import '../model/workout.dart';
import '../model/workout_list_controller.dart';
import '../settings/settings_sheet.dart';
import '../slack/slackblast_picker_sheet.dart';
import '../ui/adaptive_route_page.dart';
import '../ui/adaptive_widgets.dart';
import '../ui/dismissible_row.dart';
import '../ui/menu_icons.dart';
import '../utils/datetime_utils.dart';
import 'beatdown_browser_screen.dart';
import 'create_workout_sheet.dart';
import 'generate_workout_sheet.dart';
import 'workout_creation_picker.dart' as creation_picker;
import 'workout_share_picker.dart';

class WorkoutsTab extends ConsumerWidget {
  /// Route name for the beatdown exercise browser.
  static const beatdownBrowserRouteName = 'beatdown-browser';

  /// Routes pushed above the workouts list in its tab branch.
  static List<RouteBase> get routes => [
    GoRoute(
      path: 'beatdown-browser',
      name: beatdownBrowserRouteName,
      pageBuilder: (context, state) {
        final workout = state.extra;
        if (workout is! Workout) {
          throw StateError('Beatdown browser route requires a workout.');
        }
        return adaptiveRoutePage(
          context,
          state,
          _BeatdownBrowserRoute(workout: workout),
        );
      },
    ),
  ];

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
      await invokeWorkoutEditor(context);
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
      final listNotifier = ref.read(workoutListControllerProvider.notifier);
      await listNotifier.add(workout);
      if (!context.mounted) return;

      await invokeWorkoutEditor(context, workout: workout);
    }
  }

  static Future<void> _shareWorkout(
    BuildContext context,
    Workout workout,
  ) async {
    // Get rect of button to present popovers from on iPad.
    final box = context.findRenderObject() as RenderBox;
    final sharePositionRect = box.localToGlobal(Offset.zero) & box.size;

    final shareType = await showWorkoutSharePicker(context: context);
    if (shareType == null) return;

    // Plain text suits Slack; the json file suits another Q Master user.
    final ShareParams params = switch (shareType) {
      WorkoutShareType.plainText => ShareParams(
        text: workout.formattedText,
        sharePositionOrigin: sharePositionRect,
      ),
      WorkoutShareType.beatdownFile => ShareParams(
        files: [
          XFile.fromData(
            utf8.encode(workout.formattedJson),
            mimeType: 'application/json',
          ),
        ],
        fileNameOverrides: ['workout.qmw'],
        sharePositionOrigin: sharePositionRect,
      ),
    };
    await SharePlus.instance.share(params);
  }

  Future<void> _showSlackblastPicker(BuildContext context, Workout workout) =>
      showSlackblastPicker(context, workout: workout);

  static Future<Workout?> invokeWorkoutEditor(
    BuildContext context, {
    Workout? workout,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final beatdown = await showAdaptiveModalSheet<Workout>(
      context: navigator.context,
      child: CreateWorkoutSheet(
        originalWorkout: workout,
        onShare: _shareWorkout,
        onShowBeatdownBrowser: (sheetContext, workout) =>
            Navigator.of(sheetContext, rootNavigator: true).pop(workout),
      ),
    );
    if (beatdown != null && context.mounted) {
      _showBeatdownBrowser(context, beatdown);
    }
    return beatdown;
  }

  static void _showBeatdownBrowser(BuildContext context, Workout workout) =>
      context.pushNamed(beatdownBrowserRouteName, extra: workout);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutListControllerProvider);
    final listNotifier = ref.read(workoutListControllerProvider.notifier);
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
                  onInvokeWorkoutEditor: (context, workout) =>
                      invokeWorkoutEditor(context, workout: workout),
                  onShowBeatdownBrowser: _showBeatdownBrowser,
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

final class _BeatdownBrowserRoute extends StatefulWidget {
  final Workout workout;

  const _BeatdownBrowserRoute({required this.workout});

  @override
  State<_BeatdownBrowserRoute> createState() => _BeatdownBrowserRouteState();
}

final class _BeatdownBrowserRouteState extends State<_BeatdownBrowserRoute> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BeatdownBrowser(workout: widget.workout);
}

final class _WorkoutTile extends StatelessWidget {
  final WorkoutListController listNotifier;
  final Workout workout;
  final Future<Workout?> Function(BuildContext context, Workout workout)
  onInvokeWorkoutEditor;
  final void Function(BuildContext context, Workout workout)
  onShowBeatdownBrowser;
  final void Function(BuildContext context, Workout workout) onShareWorkout;
  final Future<void> Function(BuildContext context, Workout workout)
  onShareToBackblast;

  const _WorkoutTile({
    required super.key,
    required this.listNotifier,
    required this.workout,
    required this.onInvokeWorkoutEditor,
    required this.onShowBeatdownBrowser,
    required this.onShareWorkout,
    required this.onShareToBackblast,
  });

  Future<bool?> _confirmDelete(BuildContext context) => showAlertDialog(
    context: context,
    title: L10n.of(context)!.deleteWorkoutAlertTitle,
    message: L10n.of(context)!.deleteWorkoutAlertDescription,
    actions: [
      AdaptiveDialogAction(
        title: L10n.of(context)!.deleteWorkoutConfirmAction,
        isDestructive: true,
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
      ),
      AdaptiveDialogAction(
        title: L10n.of(context)!.cancelAction,
        isPrimary: true,
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
      ),
    ],
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
              onEdit: (context) => onInvokeWorkoutEditor(context, workout),
              onDuplicate: () => _duplicateWorkout(workout),
              onShare: (buttonContext) =>
                  onShareWorkout(buttonContext, workout),
              onShareToBackblast: (buttonContext) =>
                  onShareToBackblast(buttonContext, workout),
              onDelete: () => _deleteWorkout(context, workout),
            ),
            onTap: () => onShowBeatdownBrowser(context, workout),
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
  final void Function(BuildContext) onEdit;
  final void Function() onDuplicate;
  final void Function(BuildContext) onShare;
  final void Function(BuildContext) onShareToBackblast;
  final void Function() onDelete;

  const _OverflowMenu({
    required this.onEdit,
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
            onPressed: () => onEdit(menuContext),
            icon: Icon(Icons.edit),
            title: L10n.of(context)!.editWorkoutText,
          ),
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
