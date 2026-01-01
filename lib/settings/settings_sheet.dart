import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:q_master/l10n/l10n.dart';
import 'package:q_master/ui/adaptive_icons.dart';
import 'package:q_master/utils/shared_preferences_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  Widget _aboutListTile(BuildContext context) {
    final l10n = L10n.of(context)!;
    return FutureBuilder<PackageInfo>(
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
    );
  }

  Widget _content(BuildContext context, {required SharedPreferences prefs}) {
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          PlatformListTile(
            title: Text(L10n.of(context)!.exercisesPerPageSettingsLabel),
            subtitle: Slider.adaptive(
              value: prefs.exercisesPerPage.toDouble(),
              min: 1,
              max: 50,
              onChanged: (value) async {
                await prefs.setExercisesPerPage(value.round());
                setState(() {});
              },
            ),
            trailing: Text(prefs.exercisesPerPage.toString()),
          ),
          const Divider(),
          _aboutListTile(context),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: PlatformScaffold(
      body: FutureBuilder(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }
          return CustomScrollView(
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
              _content(context, prefs: snapshot.data!),
            ],
          );
        },
      ),
    ),
  );
}
