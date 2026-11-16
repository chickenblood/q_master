import 'package:cupertino_ui/cupertino_ui.dart' as modern_cupertino;
import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as legacy;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as modern_material;

import '../l10n/l10n.dart';
import 'material_theme.dart' as modern_gloom;
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
  final modern_material.ThemeMode themeMode;
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
      modern_material.ThemeMode.system =>
        View.of(context).platformDispatcher.platformBrightness ==
            Brightness.dark,
      modern_material.ThemeMode.light => false,
      modern_material.ThemeMode.dark => true,
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
    // The legacy Material theme also supplies the legacy Cupertino theme used
    // by Liquid Glass, including dynamic colors that resolve in legacy widgets.
    return legacy.Theme(
      data: activeTheme,
      child: legacy.ScaffoldMessenger(
        child: isCupertino
            ? modern_cupertino.CupertinoApp.router(
                title: 'Q Master',
                theme: modern_material.MaterialBasedCupertinoThemeData(
                  materialTheme: isDark
                      ? modern_gloom.darkTheme()
                      : modern_gloom.lightTheme(),
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
                themeMode: switch (widget.themeMode) {
                  modern_material.ThemeMode.system => legacy.ThemeMode.system,
                  modern_material.ThemeMode.light => legacy.ThemeMode.light,
                  modern_material.ThemeMode.dark => legacy.ThemeMode.dark,
                },
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
