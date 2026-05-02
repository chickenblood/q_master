import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:q_master/ai_clients/gemini_client.dart';
import 'package:q_master/ui/simple_alert.dart';

import '../l10n/l10n.dart';
import '../model/workout.dart';
import '../ui/action_button.dart';
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
    // iOS workaround: wait for keyboard dismissal to avoid transition glitches
    // when presenting the full-screen voice capture route.
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: 1.6),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: [
              PlatformTextField(
                controller: _promptTextController,
                focusNode: _promptFocusNode,
                autofocus: true,
                textInputAction: .done,
                maxLines: 5,
                hintText: L10n.of(context)!.generateWorkoutPromptHint,
                keyboardType: .multiline,
                onSubmitted: (_) => _handleGenerateWorkout(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Hero(
                    tag: 'voiceInputButton',
                    child: SizedBox(
                      width: 84,
                      height: 84,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.15),
                              blurRadius: 0,
                              spreadRadius: 14,
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _handleCaptureVoiceInput,
                          icon: Icon(
                            AdaptiveIcons.microphone,
                            size: 36,
                            color: Theme.of(context).colorScheme.onPrimary,
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

                      return _isGenerating
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                              ),
                              child: PlatformCircularProgressIndicator(),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                              ),
                              child: SizedBox(
                                height: 62,
                                child: ActionButton(
                                  label: L10n.of(
                                    context,
                                  )!.generateWorkoutButtonLabel,
                                  onPressed: hasPrompt
                                      ? _handleGenerateWorkout
                                      : null,
                                  icon: AdaptiveIcons.sparkles,
                                ),
                              ),
                            );
                    },
                  ),
                ],
              ),
              PlatformText(
                L10n.of(context)!.voiceGenerationInstructions,
                textAlign: .center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
