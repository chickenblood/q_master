import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'games/games_tab.dart';
import 'near_me/near_me_tab.dart';
import 'timer/timer_setup_tab.dart';
import 'workouts/exercise_picker_sheet.dart';
import 'ui/app_shell.dart';
import 'workouts/received_workout_share_listener.dart';
import 'workouts/workouts_tab.dart';

/// Creates the app router with an independent navigation stack for each tab.
///
/// [navigatorKey] identifies the root navigator used by app-level overlays.
/// [workoutsScrollController] is shared with the workouts list and tab bar so
/// the adaptive tab bar can respond to list scrolling.
GoRouter createAppRouter({
  required GlobalKey<NavigatorState> navigatorKey,
  required ScrollController workoutsScrollController,
}) => GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/workouts',
  routes: [
    StatefulShellRoute(
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/workouts',
              routes: [
                ...WorkoutsTab.routes,
                youtubeVideoRoute(rootNavigatorKey: navigatorKey),
              ],
              builder: (context, state) =>
                  WorkoutsTab(scrollController: workoutsScrollController),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/games',
              routes: GamesTab.routes(rootNavigatorKey: navigatorKey),
              builder: (context, state) => GamesTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/timer',
              routes: TimerSetupTab.routes,
              builder: (context, state) => TimerSetupTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/location',
              builder: (context, state) => NearMeTab(),
            ),
          ],
        ),
      ],
      navigatorContainerBuilder: (context, navigationShell, children) =>
          IndexedStack(
            index: navigationShell.currentIndex,
            children: [
              for (final child in children) GlassNavigationShell(child: child),
            ],
          ),
      builder: (context, state, navigationShell) =>
          ReceivedWorkoutShareListener(
            child: AppShell(
              navigationShell: navigationShell,
              routerState: state,
              workoutsScrollController: workoutsScrollController,
            ),
          ),
    ),
  ],
);
