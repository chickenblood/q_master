import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:q_master/utils/datetime_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:q_master/model/workout.dart';
import 'package:q_master/model/formatted_workout.dart';
import 'package:q_master/workouts/create_workout_modal.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'beatdown_browser.dart';
import 'package:q_master/ui/adaptive_icons.dart';
import 'package:q_master/ui/adaptive_menu.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:share_plus/share_plus.dart';

class WorkoutsTab extends StatelessWidget {
  const WorkoutsTab({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Material(
      child: Consumer(
        builder: (context, ref, _) {
          return FutureBuilder(
            future: ref.watch(workoutListProvider.future),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: PlatformCircularProgressIndicator());
              }
              final workoutList = snapshot.data!;
              return ListView.builder(
                itemExtent: 100,
                itemCount: workoutList.workouts.length,
                itemBuilder: (context, index) => _WorkoutTile(
                  workoutList: workoutList,
                  workout: workoutList.workouts[index],
                  onDelete: workoutList.remove,
                ),
              );
            },
          );
        },
      ),
    ),
  );
}

final class _WorkoutTile extends StatelessWidget {
  final WorkoutList workoutList;
  final Workout workout;
  final void Function(Workout workout) onDelete;

  const _WorkoutTile({
    required this.workoutList,
    required this.workout,
    required this.onDelete,
  });

  void _showBeatdownBrowser(BuildContext context, Workout workout) async {
    // Stop the screen from sleeping while the beatdown browser is shown.
    WakelockPlus.enable();

    await Navigator.push(
      context,
      platformPageRoute(
        context: context,
        fullscreenDialog: true,
        builder: (context) => BeatdownBrowser(workout: workout),
      ),
    );

    WakelockPlus.disable();
  }

  Future<void> _editWorkout(BuildContext context, Workout workout) async {
    Workout? updatedWorkout;
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      updatedWorkout = await showCupertinoSheet<Workout>(
        context: context,
        builder: (context) => CreateWorkoutModal(workout: workout),
      );
    } else {
      updatedWorkout = await Navigator.push(
        context,
        platformPageRoute(
          context: context,
          fullscreenDialog: true,
          builder: (context) => CreateWorkoutModal(workout: workout),
        ),
      );
    }
    if (updatedWorkout != null) {
      workoutList.replace(workout, updatedWorkout);
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

  @override
  Widget build(BuildContext context) => Dismissible(
    direction: .endToStart,
    key: ValueKey(workout),
    background: Container(color: Colors.red),
    onDismissed: (direction) {
      if (direction == .endToStart) onDelete(workout);
    },
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: PlatformListTile(
        title: PlatformText(
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
          onShare: (buttonContext) => _shareWorkout(buttonContext, workout),
          // Needs a confirmation dialog.
          onDelete: () => workoutList.remove(workout),
        ),
        onTap: () => _showBeatdownBrowser(context, workout),
      ),
    ),
  );
}

final class _OverflowMenu extends StatelessWidget {
  final void Function() onEdit;
  final void Function(BuildContext) onShare;
  final void Function() onDelete;

  const _OverflowMenu({
    required this.onEdit,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (menuContext) => AdaptiveMenu(
        icon: Icon(AdaptiveIcons.more),
        menuChildren: [
          AdaptiveMenuItem(
            onPressed: onEdit,
            icon: context.platformIcons.edit,
            text: L10n.of(context)!.editWorkoutText,
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
          ),
        ],
    ),
    );
  }
}
