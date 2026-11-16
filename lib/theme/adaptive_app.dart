import 'package:cupertino_ui/cupertino_ui.dart' as modern_cupertino;
import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/cupertino.dart' as legacy_cupertino;
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as modern_material;

import '../l10n/l10n.dart';
import 'theme.dart' as gloom;
import 'transition_theme.dart';

/// Hosts the router with matching legacy and split-package Gloom themes.
///
/// Material is used on web and non-Apple platforms; iOS and macOS retain the
/// Cupertino app and system-chrome brightness behavior.
class AdaptiveApp extends StatefulWidget {
  const AdaptiveApp({
    super.key,
    required this.routerConfig,
    required this.themeMode,
    this.builder,
  });

  final RouterConfig<Object> routerConfig;
  final legacy.ThemeMode themeMode;
  final TransitionBuilder? builder;

  @override
  State<AdaptiveApp> createState() => _AdaptiveAppState();
}

class _AdaptiveAppState extends State<AdaptiveApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    final isCupertino =
        !kIsWeb &&
        (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS);
    final isDark = switch (widget.themeMode) {
      legacy.ThemeMode.system =>
        View.of(context).platformDispatcher.platformBrightness ==
            Brightness.dark,
      legacy.ThemeMode.light => false,
      legacy.ThemeMode.dark => true,
    };
    final lightTheme = gloom.lightTheme();
    final darkTheme = gloom.darkTheme();
    final activeTheme = isDark ? darkTheme : lightTheme;
    if (isCupertino) {
      SystemChrome.setSystemUIOverlayStyle(
        isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      );
    }

    Widget buildRouter(BuildContext context, Widget? child) {
      final router = widget.builder?.call(context, child) ?? child!;
      return TransitionTheme(child: router);
    }

    final delegates = [
      ...L10n.localizationsDelegates,
      modern_material.GlobalMaterialLocalizations.delegate,
      modern_cupertino.GlobalCupertinoLocalizations.delegate,
    ];
    return legacy.Theme(
      data: activeTheme,
      child: legacy.ScaffoldMessenger(
        child: isCupertino
            ? legacy_cupertino.CupertinoApp.router(
                title: 'Q Master',
                theme: legacy.MaterialBasedCupertinoThemeData(
                  materialTheme: activeTheme,
                ),
                localizationsDelegates: delegates,
                supportedLocales: L10n.supportedLocales,
                routerConfig: widget.routerConfig,
                debugShowCheckedModeBanner: false,
                builder: buildRouter,
              )
            : legacy.MaterialApp.router(
                title: 'Q Master',
                theme: lightTheme.copyWith(platform: TargetPlatform.android),
                darkTheme: darkTheme.copyWith(platform: TargetPlatform.android),
                themeMode: widget.themeMode,
                localizationsDelegates: delegates,
                supportedLocales: L10n.supportedLocales,
                routerConfig: widget.routerConfig,
                debugShowCheckedModeBanner: false,
                builder: buildRouter,
              ),
      ),
    );
  }
}
