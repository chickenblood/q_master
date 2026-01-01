import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
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
      sliver: SliverList(delegate: SliverChildListDelegate(
          [

          ],
        )),
    );
  }

  @override
  Widget build(BuildContext context) => PlatformScaffold(
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
  );
}
