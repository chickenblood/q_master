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
  Future<void> _showAboutDialog(BuildContext context) async {
    final l10n = L10n.of(context)!;
    final packageInfo = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    return showAdaptiveAboutDialog(
      context: context,
      applicationName: L10n.of(context)!.appBarTitle,
      applicationVersion: packageInfo.version,
      applicationIcon: Image.asset(
        'assets/icon/app_icon.png',
        width: 48.0,
        height: 48.0,
      ),
      children: [Text(l10n.settingsAboutDialogDescription)],
    );
  }

  Widget content(BuildContext context, {required SharedPreferences prefs}) {
    final l10n = L10n.of(context)!;
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          PlatformListTile(
            title: Text(L10n.of(context)!.exercisesPerPageSettingsLabel),
            subtitle: Slider.adaptive(
              value: prefs.exercisesPerPage.toDouble(),
              min: 1,
              max: 30,
              divisions: 30,
              onChanged: (value) async {
                await prefs.setExercisesPerPage(value.round());
                setState(() {});
              },
            ),
            trailing: Text(prefs.exercisesPerPage.toString()),
          ),
          const Divider(),
          PlatformListTile(
            title: Text(l10n.appBarTitle),
            leading: Icon(context.platformIcons.info),
            onTap: () => _showAboutDialog(context),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PlatformScaffold(
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
            content(context, prefs: snapshot.data!),
          ],
        );
      },
    ),
  );
}
