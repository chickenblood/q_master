import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/model/formatted_workout.dart';
import 'package:q_master/model/workout.dart';
import 'package:q_master/model/workout_list.dart';
import 'package:q_master/ui/adaptive_icons.dart';
import 'package:q_master/ui/adaptive_menu.dart';
import 'package:q_master/ui/adaptive_modal_sheet.dart';
import 'package:q_master/utils/datetime_utils.dart';
import 'package:q_master/workouts/create_workout_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'beatdown_browser.dart';

class WorkoutsTab extends StatelessWidget {
  const WorkoutsTab({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: PlatformScaffold(
      body: Consumer(
        builder: (context, ref, _) {
          final workouts = ref.watch(workoutListProvider);
          final listNotifier = ref.read(workoutListProvider.notifier);
          return ListView.builder(
            itemExtent: 100,
            itemCount: workouts.length,
            itemBuilder: (context, index) => _WorkoutTile(
              listNotifier: listNotifier,
              workout: workouts[index],
            ),
          );
        },
      ),
    ),
  );
}

final class _WorkoutTile extends StatelessWidget {
  final WorkoutList listNotifier;
  final Workout workout;

  const _WorkoutTile({required this.listNotifier, required this.workout});

  Future<void> _showBeatdownBrowser(
    BuildContext context,
    Workout workout,
  ) async {
    // Stop the screen from sleeping while the beatdown browser is shown.
    WakelockPlus.enable();

    await Navigator.of(context, rootNavigator: true).push(
      platformPageRoute(
        context: context,
        fullscreenDialog: true,
        builder: (context) => BeatdownBrowser(workout: workout),
      ),
    );

    WakelockPlus.disable();
  }

  Future<void> _editWorkout(BuildContext context, Workout workout) async {
    Workout? updatedWorkout = await showAdaptiveModalSheet(
      context: context,
      child: CreateWorkoutSheet(workout: workout),
    );
    if (updatedWorkout != null) {
      listNotifier.replace(workout, updatedWorkout);
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
    const padding = EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0);
    return Dismissible(
      direction: .endToStart,
      key: ValueKey(workout),
      background: Container(color: Colors.red),
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
        title: AutoSizeText(
          workout.name,
          style: TextTheme.of(
            context,
          ).headlineLarge!.copyWith(fontWeight: .bold),
          overflow: .ellipsis,
        ),
        subtitle: PlatformText(
          workout.date.formattedForDisplay(),
          style: TextTheme.of(context).bodyLarge,
        ),
        trailing: _OverflowMenu(
          onEdit: () => _editWorkout(context, workout),
          onDuplicate: () => _duplicateWorkout(workout),
          onShare: (buttonContext) => _shareWorkout(buttonContext, workout),
          onDelete: () => _deleteWorkout(context, workout),
        ),
        onTap: () => _showBeatdownBrowser(context, workout),
      ),
    );
  }
}

final class _OverflowMenu extends StatelessWidget {
  final void Function() onEdit;
  final void Function() onDuplicate;
  final void Function(BuildContext) onShare;
  final void Function() onDelete;

  const _OverflowMenu({
    required this.onEdit,
    required this.onDuplicate,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (menuContext) => AdaptiveMenu(
        icon: Icon(AdaptiveIcons.more),
        menuChildren: [
          AdaptiveMenuItem(
            onPressed: onEdit,
            icon: context.platformIcons.edit,
            text: L10n.of(context)!.editWorkoutText,
          ),
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
