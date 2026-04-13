import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:q_master/ai_clients/gemini_client.dart';
import 'package:q_master/ui/simple_alert.dart';

import '../l10n/l10n.dart';
import '../model/workout.dart';
import '../ui/adaptive_icons.dart';
import 'capture_voice_input_dialog.dart';

final class GenerateWorkoutSheet extends StatefulWidget {
  const GenerateWorkoutSheet({super.key});

  @override
  State<GenerateWorkoutSheet> createState() => _GenerateWorkoutSheetState();
}

final class _GenerateWorkoutSheetState extends State<GenerateWorkoutSheet> {
  final _client = GeminiClient();
  final _promptTextController = TextEditingController();
  final _promptFocusNode = FocusNode();
  var _isGenerating = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _promptFocusNode.dispose();
    _promptTextController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerateWorkout() async {
    final prompt = _promptTextController.text.trim();
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

  Future<void> _handleCaptureVoiceInput() async {
    // Clear focus from the text field to dismiss the keyboard before opening
    // the voice input dialog.
    _promptFocusNode.unfocus();
    // Wait for keyboard to hide.
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    final transcript = await navigator.push<String?>(
      PageRouteBuilder(
        fullscreenDialog: true,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CaptureVoiceInputDialog(),
      ),
    );
    if (!mounted) return;
    if (transcript == null || transcript.trim().isEmpty) return;

    final normalizedTranscript = transcript.trim();
    _promptTextController.value = TextEditingValue(
      text: normalizedTranscript,
      selection: TextSelection(
        baseOffset: 0,
        extentOffset: normalizedTranscript.length,
      ),
    );
    _promptFocusNode.requestFocus();
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
                focusNode: _promptFocusNode,
                autofocus: true,
                textInputAction: .done,
                maxLines: 5,
                hintText: L10n.of(context)!.generateWorkoutPromptHint,
                keyboardType: .multiline,
                onSubmitted: (_) => _handleGenerateWorkout(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Center(
                child: Hero(
                  tag: 'voiceInputButton',
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _handleCaptureVoiceInput,
                        icon: Icon(
                          AdaptiveIcons.microphone,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Stack(
              children: [
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _promptTextController,
                  builder: (context, value, child) {
                    final hasPrompt = value.text.trim().isNotEmpty;
                    return PlatformElevatedButton(
                      onPressed: (_isGenerating || !hasPrompt)
                          ? null
                          : _handleGenerateWorkout,
                      child: _isGenerating
                          ? PlatformCircularProgressIndicator()
                          : PlatformText(
                              L10n.of(context)!.generateWorkoutButtonLabel,
                            ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
