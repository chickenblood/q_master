import 'package:flutter/cupertino.dart' show CupertinoPage;
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:go_router/go_router.dart';

/// Builds a go_router page with the app's platform-appropriate transition.
///
/// Uses a Material or Cupertino page to retain the transitions previously
/// provided by `platformPageRoute`. Set [fullscreenDialog] for destinations
/// presented as full-screen dialogs.
Page<Object?> adaptiveRoutePage(
  BuildContext context,
  GoRouterState state,
  Widget child, {
  bool fullscreenDialog = false,
}) {
  final pageName = state.name ?? state.path;
  return isMaterial(context)
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
