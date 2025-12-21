import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'timer/timer_tab.dart';
import 'workouts/create_workout_sheet.dart';
import 'workouts/workouts_tab.dart';
import 'ui/adaptive_icons.dart';
import 'theme/theme.dart';
import 'games/games_tab.dart';
import 'model/workout.dart';
import 'model/workout_list.dart';
import 'l10n/l10n.dart';

enum Tab { workouts, games, timer }

void main() {
  runApp(ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  MainApp({super.key});

  final _navigatorKey = GlobalKey<NavigatorState>();
  final tabController = PlatformTabController(initialIndex: Tab.workouts.index);
  final List<Widget> _tabPages = [WorkoutsTab(), GamesTab(), TimerTab()];

  void _showComposeWorkoutModal(WidgetRef ref) async {
    final context = _navigatorKey.currentContext;
    assert(context != null);
    if (context == null) return;

    Workout? workout;
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      workout = await showCupertinoSheet<Workout>(
        context: context,
        builder: (context) => CreateWorkoutSheet(),
      );
    } else {
      workout = await Navigator.push(
        _navigatorKey.currentContext!,
        platformPageRoute(
          context: context,
          fullscreenDialog: true,
          builder: (context) => CreateWorkoutSheet(),
        ),
      );
    }
    if (workout != null) {
      final workoutList = await ref.read(workoutListProvider);
      workoutList.add(workout);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => PlatformApp(
    title: 'Q Master',
    localizationsDelegates: L10n.localizationsDelegates,
    supportedLocales: L10n.supportedLocales,
    navigatorKey: _navigatorKey,
    material: (_, _) => MaterialAppData(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
    ),
    cupertino: (context, _) => CupertinoAppData(
      theme: MaterialBasedCupertinoThemeData(
        materialTheme:
            MediaQuery.platformBrightnessOf(context) == Brightness.light
            ? lightTheme
            : darkTheme,
      ),
    ),
    home: Builder(
      builder: (context) => PlatformTabScaffold(
        appBarBuilder: (_, index) => PlatformAppBar(
          cupertino: (_, _) =>
              CupertinoNavigationBarData(backgroundColor: Colors.transparent),
          title: Text(L10n.of(context)!.appBarTitle),
          trailingActions: [
            if (index == Tab.workouts.index)
              PlatformIconButton(
                icon: Icon(PlatformIcons(context).add),
                onPressed: () => _showComposeWorkoutModal(ref),
              ),
          ],
        ),
        tabController: tabController,
        bodyBuilder: (_, index) => _tabPages[index],
        items: [
          BottomNavigationBarItem(
            icon: Icon(AdaptiveIcons.history),
            label: L10n.of(context)!.workoutsTabTitle,
          ),
          BottomNavigationBarItem(
            icon: Icon(AdaptiveIcons.sports),
            label: L10n.of(context)!.gamesTabTitle,
          ),
          BottomNavigationBarItem(
            icon: Icon(AdaptiveIcons.timer),
            label: L10n.of(context)!.timerTabTitle,
          ),
        ],
      ),
    ),
  );
}
