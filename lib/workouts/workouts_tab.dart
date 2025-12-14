import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:q_master/utils/formatted_date.dart';
import 'package:q_master/l10n/l10n.dart';

class WorkoutsTab extends StatelessWidget {
  const WorkoutsTab({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Material(
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => ListTile(
          title: PlatformListTile(
            title: PlatformText('Workout ${index + 1}'),
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
      ),
    ),
  );
}
