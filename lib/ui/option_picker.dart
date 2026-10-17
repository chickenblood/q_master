import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// A single selectable row in an option picker sheet.
final class PickerOption<T> {
  final T value;
  final IconData icon;
  final String title;
  final String subtitle;

  const PickerOption({
    required this.value,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

/// Shows a bottom sheet listing [options] and returns the chosen value.
///
/// Morphs from [anchor] when one is provided, otherwise presents a standard
/// modal bottom sheet.
Future<T?> showOptionPicker<T>({
  required BuildContext context,
  required String title,
  required List<PickerOption<T>> options,
  GlassMorphAnchor? anchor,
}) {
  if (anchor != null) {
    return GlassModalSheet.show(
      morphFrom: anchor,
      initialState: .full,
      detents: {
        MediaQuery.orientationOf(context) == .portrait ? .medium : .large,
      },
      context: context,
      useRootNavigator: true,
      builder: (_) => _OptionPicker<T>(title: title, options: options),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    builder: (_) => _OptionPicker<T>(title: title, options: options),
  );
}

class _OptionPicker<T> extends StatelessWidget {
  final String title;
  final List<PickerOption<T>> options;

  const _OptionPicker({required this.title, required this.options});

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
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 16),
            for (final (index, option) in options.indexed) ...[
              if (index > 0) const SizedBox(height: 10),
              _PickerOptionButton(
                icon: option.icon,
                title: option.title,
                subtitle: option.subtitle,
                onTap: () => Navigator.of(context).pop(option.value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PickerOptionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerOptionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.primary;
    return Material(
      color: colorScheme.surface,
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
                  color: iconColor.withValues(alpha: 0.1),
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
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: colorScheme.outlineVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
