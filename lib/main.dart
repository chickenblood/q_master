import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'timer/timer_tab.dart';
import 'workouts/create_workout_modal.dart';
import 'workouts/workouts_tab.dart';
import 'icons/adaptive_icons.dart';
import 'theme/theme.dart';
import 'games/games_tab.dart';
import 'model/workout.dart';
import 'l10n/l10n.dart';

enum Tab { workouts, games, timer }

void main() {
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  Tab _sectedTab = Tab.workouts;

  final List<Widget> _tabPages = [WorkoutsTab(), GamesTab(), TimerTab()];

  void _itemChanged(int index) {
    setState(() {
      _sectedTab = Tab.values[index];
    });
  }

  void _showComposeWorkoutModal() async {
    final context = _navigatorKey.currentContext;
    assert(context != null);
    if (context == null) return;

    Workout? workout;
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      workout = await showCupertinoSheet<Workout>(
        context: context,
        builder: (context) => CreateWorkoutModal(),
      );
    } else {
      workout = await Navigator.push(
        _navigatorKey.currentContext!,
        platformPageRoute(
          context: context,
          fullscreenDialog: true,
          builder: (context) => CreateWorkoutModal(),
        ),
      );
    }
    if (workout != null) {
      final workoutList = await ref.read(workoutListProvider.future);
      workoutList.add(workout);
    }
  }

  @override
  Widget build(BuildContext context) => PlatformApp(
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
      builder: (context) => PlatformScaffold(
        appBar: PlatformAppBar(
          cupertino: (_, _) =>
              CupertinoNavigationBarData(backgroundColor: Colors.transparent),
          title: Text(L10n.of(context)!.appBarTitle),
          trailingActions: [
            if (_sectedTab == Tab.workouts)
              PlatformIconButton(
                icon: Icon(PlatformIcons(context).add),
                onPressed: _showComposeWorkoutModal,
              ),
          ],
        ),
        body: _tabPages[_sectedTab.index],
        bottomNavBar: PlatformNavBar(
          currentIndex: _sectedTab.index,
          itemChanged: _itemChanged,
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
    ),
  );
}
