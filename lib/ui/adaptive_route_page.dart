import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPage;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'adaptive_platform.dart';

/// Builds a go_router page with the app's platform-appropriate transition.
///
/// Uses a Material or Cupertino page to retain the transitions previously
/// appropriate to the active platform. Set [fullscreenDialog] for
/// destinations presented as full-screen dialogs.
Page<Object?> adaptiveRoutePage(
  BuildContext context,
  GoRouterState state,
  Widget child, {
  bool fullscreenDialog = false,
}) {
  final pageName = state.name ?? state.path;
  return isMaterialPlatform(context)
      ? MaterialPage<Object?>(
          key: state.pageKey,
          name: pageName,
          arguments: state.extra,
          fullscreenDialog: fullscreenDialog,
          child: child,
        )
      : CupertinoPage<Object?>(
          key: state.pageKey,
          name: pageName,
          arguments: state.extra,
          fullscreenDialog: fullscreenDialog,
          child: child,
        );
}
