import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:q_master/utils/formatted_date.dart';
import 'package:q_master/model/workout.dart';
import 'package:q_master/l10n/l10n.dart';
import 'beatdown_browser.dart';

class WorkoutsTab extends StatelessWidget {
  const WorkoutsTab({super.key});

  void _showBeatdownBrowser(BuildContext context, Workout workout) {
    Navigator.push(
      context,
      platformPageRoute(
        context: context,
        fullscreenDialog: true,
        builder: (context) => BeatdownBrowser(workout: workout),
      ),
    );
  }

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
                itemCount: workoutList.workouts.length,
                itemBuilder: (context, index) => PlatformListTile(
                  title: PlatformText(workoutList.workouts[index].name),
                  subtitle: PlatformText(
                    formattedDateTime(workoutList.workouts[index].date),
                  ),
                  trailing: PlatformTextButton(
                    onPressed: () => _showBeatdownBrowser(
                      context,
                      workoutList.workouts[index],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlatformText(L10n.of(context)!.startWorkoutButtonText),
                        SizedBox(width: 8),
                        Icon(PlatformIcons(context).playArrow),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}
