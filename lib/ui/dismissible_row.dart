import 'package:flutter/material.dart';

/// A helper class to create a dismissible row with a red background for
/// deletion when swiped.
final class DismissibleRow extends StatelessWidget {
  const DismissibleRow({
    required super.key,
    required this.onDismissed,
    this.enabled = true,
    this.backgroundPadding = const EdgeInsets.fromLTRB(24, 0, 24, 0),
    this.confirmDismiss,
    required this.child,
  });

  final bool enabled;
  final EdgeInsets backgroundPadding;
  final ConfirmDismissCallback? confirmDismiss;
  final void Function(DismissDirection) onDismissed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: key!,
      confirmDismiss: confirmDismiss,
      onDismissed: (direction) => onDismissed(direction),
      background: Container(
        padding: backgroundPadding,
        color: scheme.error,
        child: Row(
          mainAxisAlignment: .end,
          children: [Icon(Icons.delete, color: scheme.onError)],
        ),
      ),
      direction: enabled ? .endToStart : .none,
      child: child,
    );
  }
}
