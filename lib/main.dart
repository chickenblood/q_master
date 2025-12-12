import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'timer/timer_tab.dart';
import 'workouts/workouts_tab.dart';
import 'icons/adaptive_icons.dart';
import 'theme/theme.dart';
import 'games/games_tab.dart';
import 'l10n/l10n.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedTabIndex = 0;

  final List<Widget> _tabPages = [WorkoutsTab(), GamesTab(), TimerTab()];

  void _itemChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) => PlatformApp(
    title: 'Q Master',
    localizationsDelegates: L10n.localizationsDelegates,
    supportedLocales: L10n.supportedLocales,
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
          title: Text(L10n.of(context)!.appBarTitle),
          trailingActions: [
            PlatformIconButton(
              icon: Icon(PlatformIcons(context).add),
              onPressed: () {},
            ),
          ],
        ),
        body: _tabPages[_selectedTabIndex],
        bottomNavBar: PlatformNavBar(
          currentIndex: _selectedTabIndex,
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
