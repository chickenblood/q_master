import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:q_master/utils/formatted_date.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/model/workout.dart';

class WorkoutsTab extends StatelessWidget {
  const WorkoutsTab({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Material(
      child: Consumer(
        builder: (context, ref, child) {
          final workoutList = ref.watch(workoutListProvider);
          return FutureBuilder(
            future: workoutList,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: PlatformCircularProgressIndicator());
              }
              return ListView.builder(
                itemCount: snapshot.data!.workouts.length,
                itemBuilder: (context, index) => ListTile(
                  title: PlatformListTile(
                    title: PlatformText(snapshot.data!.workouts[index].name),
                    subtitle: PlatformText(formattedDateTime(DateTime.now())),
                    trailing: Row(
                      children: [
                        Text(L10n.of(context)!.startWorkoutButtonText),
                        PlatformIconButton(
                          icon: Icon(PlatformIcons(context).playArrow),
                          onPressed: () {},
                        ),
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
