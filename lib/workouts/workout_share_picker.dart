import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../ui/adaptive_icons.dart';
import '../ui/option_picker.dart';

enum WorkoutShareType { plainText, beatdownFile }

Future<WorkoutShareType?> showWorkoutSharePicker({
  required BuildContext context,
}) {
  final l10n = L10n.of(context)!;
  return showOptionPicker<WorkoutShareType>(
    context: context,
    title: l10n.sharePickerTitle,
    options: [
      PickerOption(
        value: WorkoutShareType.plainText,
        icon: AdaptiveIcons.notes,
        title: l10n.sharePickerPlainText,
        subtitle: l10n.sharePickerPlainTextSubtitle,
      ),
      PickerOption(
        value: WorkoutShareType.beatdownFile,
        icon: AdaptiveIcons.file,
        title: l10n.sharePickerFile,
        subtitle: l10n.sharePickerFileSubtitle,
      ),
    ],
  );
}
