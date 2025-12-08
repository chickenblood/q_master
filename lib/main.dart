import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'theme/theme.dart';

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

  final List<Widget> _tabPages = [
    Container(color: Colors.green),
    Container(color: Colors.blue),
  ];

  void _itemChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) => PlatformApp(
      title: 'Q Master',
      material: (_, _) => MaterialAppData(
        theme: lightTheme,
        darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      ),
      cupertino: (context, _) => CupertinoAppData(
        theme: MaterialBasedCupertinoThemeData(
          materialTheme: MediaQuery.platformBrightnessOf(context) == Brightness.light ? lightTheme : darkTheme,
        ),
      ),
      home: PlatformScaffold(
        appBar: PlatformAppBar(
          title: const Text('F3 Q Master'),
        ),
        body: _tabPages[_selectedTabIndex],
        bottomNavBar: PlatformNavBar(
          currentIndex: _selectedTabIndex,
          itemChanged: _itemChanged,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Workouts',
            ),
          ],
        ),
      ),
    );
}
