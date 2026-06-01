import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// ActionButton — A large, attention-grabbing button used for primary actions
/// in modals and sheets.
///
/// Supports outlined and filled styles, with an icon and label.
class ActionButton extends StatelessWidget {
  final Function()? onPressed;
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final bool outlined;
  const ActionButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.iconColor,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isDisabled = onPressed == null;
    final disabledBg = colorScheme.onSurface.withValues(alpha: 0.12);
    final disabledFg = colorScheme.onSurface.withValues(alpha: 0.38);
    final textColor = isDisabled
        ? disabledFg
        : (outlined && isLight ? colorScheme.onSurface : colorScheme.onPrimary);
    final borderColor = isDisabled
        ? colorScheme.outline.withValues(alpha: 0.38)
        : colorScheme.outline;
    return PlatformTextButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: outlined
              ? Colors.transparent
              : (isDisabled ? disabledBg : colorScheme.primary),
          border: outlined ? Border.all(color: borderColor, width: 2) : null,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: outlined || isDisabled
                  ? Colors.transparent
                  : colorScheme.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
        constraints: const BoxConstraints(minHeight: 54),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? textColor, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: textColor,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
