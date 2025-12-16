import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:q_master/model/workout.dart';

final class BeatdownBrowser extends StatelessWidget {
  final Workout workout;
  const BeatdownBrowser({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(title: PlatformText('Beatdown Browser')),
      body: Center(child: PlatformText('Beatdown Browser Content Here')),
    );
  }
}
