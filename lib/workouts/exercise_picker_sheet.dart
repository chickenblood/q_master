import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../l10n/l10n.dart';
import '../ui/adaptive_icons.dart';
import '../ui/adaptive_modal_sheet.dart';
import 'workout_auto_completions.dart';

Future<String?> showExercisePicker(BuildContext context, {String? text}) async {
  final controller = TextEditingController(text: text);
  controller.selection = TextSelection(
    baseOffset: 0,
    extentOffset: text?.length ?? 0,
  );

  return showAdaptiveModalSheet<String>(
    context: context,
    child: PlatformScaffold(
      appBar: PlatformAppBar(
        cupertino: (appBarContext, _) => CupertinoNavigationBarData(
          backgroundColor: Colors.transparent,
          leading: PlatformIconButton(
            padding: const EdgeInsets.only(right: 22),
            icon: Icon(AdaptiveIcons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: PlatformText(
            L10n.of(context)!.exerciseEntryPromptText,
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: 1.6),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WorkoutAutocompleteTextField(
                textEditingController: controller,
                autofocus: true,
                minLines: 1,
                maxLines: 1,
                onSubmitted: () => Navigator.of(context).pop(controller.text),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    ),
  );
}
