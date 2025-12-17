import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:q_master/utils/formatted_date.dart';
import 'package:q_master/model/workout.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'beatdown_browser.dart';
import 'package:q_master/icons/adaptive_icons.dart';

class WorkoutsTab extends StatelessWidget {
  const WorkoutsTab({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Material(
      child: Consumer(
        builder: (context, ref, _) {
          return FutureBuilder(
            future: ref.watch(workoutListProvider),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: PlatformCircularProgressIndicator());
              }
              final workoutList = snapshot.data!;
              return ListView.builder(
                itemExtent: 100,
                itemCount: workoutList.workouts.length,
                itemBuilder: (context, index) => _WorkoutTile(
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
  final Workout workout;
  final void Function(Workout workout) onDelete;

  const _WorkoutTile({required this.workout, required this.onDelete});

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
          formattedDateTime(workout.date),
          style: TextTheme.of(context).bodyLarge,
        ),
        trailing: PlatformIconButton(
          icon: Icon(AdaptiveIcons.more),
          onPressed: () {},
        ),

        onTap: () => _showBeatdownBrowser(context, workout),
      ),
    ),
  );
}
