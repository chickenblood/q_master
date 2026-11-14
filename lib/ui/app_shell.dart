import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n.dart';
import '../workouts/workouts_tab.dart';
import 'adaptive_widgets.dart';
import 'media_query.dart';

enum _AppTab { workouts, games, timer, location }

/// Adaptive scaffold for the router's tab branches.
///
/// Keeps the selected branch in sync with the tab bar and derives tab-bar and
/// workout-action visibility from the current route and display orientation.
class AppShell extends ConsumerWidget {
  /// The stateful router shell containing the tab branch navigators.
  final StatefulNavigationShell navigationShell;

  /// The current route, used to determine which shell actions are visible.
  final GoRouterState routerState;

  /// Scroll controller shared by the workouts list and adaptive tab bar.
  final ScrollController workoutsScrollController;

  /// Creates the app shell around [navigationShell].
  const AppShell({
    required this.navigationShell,
    required this.routerState,
    required this.workoutsScrollController,
    super.key,
  });

  /// Hides the tab bar on phone timer landscape.
  bool _shouldShowTabBar(BuildContext context) {
    final isTablet = MediaUtils.isTablet(context);
    final isTimerTab = _AppTab.values[navigationShell.currentIndex] == .timer;
    final isLandscape = MediaQuery.orientationOf(context) == .landscape;
    return isTablet || !(isTimerTab && isLandscape);
  }

  AdaptiveAccessoryActionItem _addWorkoutButton(
    BuildContext context,
    WidgetRef ref,
  ) => AdaptiveAccessoryActionItem(
    icon: Icon(PlatformIcons(context).add),
    id: 'add-workout',
    onPressed: (anchor) => WorkoutsTab.showWorkoutCreationPicker(
      context: context,
      ref: ref,
      anchor: anchor,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = navigationShell.currentIndex;
    final location = routerState.uri.path;
    final isWorkoutsRoot = location == '/workouts';
    final showWorkoutActions =
        selectedIndex == _AppTab.workouts.index && isWorkoutsRoot;
    final workoutButton = showWorkoutActions
        ? _addWorkoutButton(context, ref)
        : null;

    return AdaptiveScaffold(
      body: SafeArea(top: false, child: navigationShell),
      bottomBar: AdaptiveTabBar(
        visible: _shouldShowTabBar(context),
        selectedIconColor: Theme.of(context).colorScheme.primary,
        selectedIndex: selectedIndex,
        onTabSelected: (index) => navigationShell.goBranch(index),
        items: [
          AdaptiveTabItem(
            icon: Icon(AdaptiveIcons.history),
            label: L10n.of(context)!.workoutsTabShortTitle,
          ),
          AdaptiveTabItem(
            icon: Icon(AdaptiveIcons.sports),
            label: L10n.of(context)!.gamesTabTitle,
          ),
          AdaptiveTabItem(
            icon: Icon(AdaptiveIcons.timer),
            label: L10n.of(context)!.timerPageTitle,
          ),
          AdaptiveTabItem(
            icon: Icon(AdaptiveIcons.location),
            label: L10n.of(context)!.nearMeTabTitle,
          ),
        ],
        trailingButton: workoutButton,
        scrollController: workoutsScrollController,
      ),
      resizeToAvoidBottomInset: false,
      floatingActionButton: showWorkoutActions ? workoutButton : null,
    );
  }
}
