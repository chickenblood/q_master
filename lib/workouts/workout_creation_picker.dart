import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../l10n/l10n.dart';
import '../ui/adaptive_icons.dart';

enum WorkoutCreationType { manual, generate }

Future<WorkoutCreationType?> showWorkoutCreationPicker(BuildContext context) {
  /*
  return showModalBottomSheet<WorkoutCreationType>(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    builder: (context) => const _WorkoutCreationPicker(),
  );
  */

  return GlassSheet.show(
    context: context,
    builder: (_) => _WorkoutCreationPicker(),
  );
}

/// WorkoutCreationPicker — Unified entry sheet for new workout creation
class _WorkoutCreationPicker extends StatelessWidget {
  const _WorkoutCreationPicker({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              L10n.of(context)!.createWorkoutPickerTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 16),
            _PickerOptionButton(
              icon: AdaptiveIcons.create,
              iconBg: Theme.of(context).colorScheme.surfaceContainerHighest,
              iconColor: Theme.of(context).colorScheme.primary,
              title: 'Build Manually',
              subtitle: 'Add sections & exercises',
              onTap: () =>
                  Navigator.of(context).pop(WorkoutCreationType.manual),
            ),
            const SizedBox(height: 10),
            _PickerOptionButton(
              icon: AdaptiveIcons.sparkles,
              iconBg: Theme.of(context).colorScheme.surfaceContainerHighest,
              iconColor: Theme.of(context).colorScheme.primary,
              title: 'Generate with AI',
              subtitle: 'Describe your beatdown',
              onTap: () =>
                  Navigator.of(context).pop(WorkoutCreationType.generate),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerOptionButton extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerOptionButton({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonColor = colorScheme.surface;
    final iconBgColor = iconColor.withValues(alpha: 0.1);
    final subtitleColor = colorScheme.onSurfaceVariant;
    final chevronColor = colorScheme.outlineVariant;
    return Material(
      color: buttonColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outline, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: subtitleColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: chevronColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
