import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/ui/adaptive_icons.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  Widget _content(BuildContext context) {
    final l10n = L10n.of(context)!;

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              final packageInfo = snapshot.data;
              return AboutListTile(
                applicationName: l10n.appBarTitle,
                applicationVersion: packageInfo?.version,
                applicationIcon: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 48.0,
                  height: 48.0,
                ),
                icon: Icon(context.platformIcons.info),
                aboutBoxChildren: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(l10n.settingsAboutDialogDescription),
                  ),
                ],
              );
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: PlatformScaffold(
      body: CustomScrollView(
        physics: ClampingScrollPhysics(),
        slivers: [
          PlatformSliverAppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: PlatformIconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(AdaptiveIcons.close),
            ),
            title: Text(L10n.of(context)!.settingsDialogTitle),
          ),
          _content(context),
        ],
      ),
    ),
  );
}
