import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

/// ActionButton — A large, attention-grabbing button used for primary actions
/// in modals and sheets.
///
/// Supports outlined and filled styles, with an icon and label.
class ActionButton extends StatelessWidget {
  final Function()? onPressed;
  final String label;
  final IconData icon;
  final Color? iconColor;
  final bool outlined;
  const ActionButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    this.iconColor,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return PlatformTextButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: outlined
              ? Colors.transparent
              : Theme.of(context).colorScheme.primary,
          border: outlined
              ? Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 2,
                )
              : null,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: outlined
                  ? Colors.transparent
                  : Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.35),
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
            Icon(
              icon,
              color: iconColor ?? Theme.of(context).colorScheme.onPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 16,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
