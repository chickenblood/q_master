import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:q_master/ai_clients/gemini_client.dart';
import 'package:q_master/ui/simple_alert.dart';

import '../l10n/l10n.dart';
import '../model/workout.dart';
import '../ui/adaptive_icons.dart';

final class GenerateWorkoutSheet extends StatefulWidget {
  const GenerateWorkoutSheet({super.key});

  @override
  State<GenerateWorkoutSheet> createState() => _GenerateWorkoutSheetState();
}

final class _GenerateWorkoutSheetState extends State<GenerateWorkoutSheet> {
  final _client = GeminiClient();
  final _promptTextController = TextEditingController();
  var _isGenerating = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _promptTextController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerateWorkout() async {
    final prompt = _promptTextController.text;
    if (prompt.isNotEmpty) {
      setState(() => _isGenerating = true);
      Workout? workout;
      try {
        final jsonResponse = await _client.requestWorkout(prompt);

        final jsonWorkout = jsonDecode(jsonResponse) as Map<String, Object?>;
        workout = Workout.fromJson(jsonWorkout);

        if (!mounted) return;
        Navigator.of(context).pop(workout);
      } catch (e) {
        if (!mounted) return;
        showSimpleAlert(
          context,
          title: L10n.of(context)!.generateWorkoutErrorTitle,
          message: e.toString(),
        );
      }
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        cupertino: (appBarContext, _) => CupertinoNavigationBarData(
          backgroundColor: Colors.transparent,

          leading: PlatformIconButton(
            padding: EdgeInsets.only(right: 22),
            icon: Icon(AdaptiveIcons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: PlatformText(
            L10n.of(context)!.generateWorkoutDialogTitle,
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: 1.6),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: PlatformTextField(
                controller: _promptTextController,
                autofocus: true,
                maxLines: 5,
                hintText: L10n.of(context)!.generateWorkoutPromptHint,
              ),
            ),
            Stack(
              children: [
                PlatformElevatedButton(
                  onPressed: _isGenerating ? null : _handleGenerateWorkout,
                  child: _isGenerating
                      ? PlatformCircularProgressIndicator()
                      : PlatformText(
                          L10n.of(context)!.generateWorkoutButtonLabel,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
