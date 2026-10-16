import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../l10n/l10n.dart';
import '../ui/adaptive_icons.dart';
import '../ui/option_picker.dart';

enum WorkoutCreationType { manual, generate }

Future<WorkoutCreationType?> showWorkoutCreationPicker({
  required BuildContext context,
  required GlassMorphAnchor? anchor,
}) {
  final l10n = L10n.of(context)!;
  return showOptionPicker<WorkoutCreationType>(
    context: context,
    anchor: anchor,
    title: l10n.createWorkoutPickerTitle,
    options: [
      PickerOption(
        value: WorkoutCreationType.manual,
        icon: AdaptiveIcons.create,
        title: l10n.workoutCreationPickerManual,
        subtitle: l10n.workoutCreationPickerManualSubtitle,
      ),
      PickerOption(
        value: WorkoutCreationType.generate,
        icon: AdaptiveIcons.sparkles,
        title: l10n.workoutCreationPickerGenerate,
        subtitle: l10n.workoutCreationPickerGenerateSubtitle,
      ),
    ],
  );
}
