import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../l10n/l10n.dart';

/// A titled, drill-down list section used by the Slackblast picker sheet:
/// shows a loading spinner, an error state with retry, an empty state, or a
/// selectable list of [T] items. Not independently scrollable — meant to be
/// embedded within an outer scroll view.
class SlackblastPickerSection<T> extends StatelessWidget {
  final String title;
  final Widget? headerChild;
  final Future<List<T>>? future;
  final String Function(T) itemLabel;
  final TextStyle? Function(BuildContext, T)? itemTextStyle;
  final T? selectedItem;
  final void Function(T) onSelect;
  final String emptyLabel;
  final String errorLabel;
  final VoidCallback? onRetry;

  /// Creates a drill-down section backed by [future] and selecting with
  /// [onSelect].
  const SlackblastPickerSection({
    super.key,
    required this.title,
    this.headerChild,
    required this.future,
    required this.itemLabel,
    this.itemTextStyle,
    required this.selectedItem,
    required this.onSelect,
    required this.emptyLabel,
    required this.errorLabel,
    this.onRetry,
  });

  /// Builds the shared empty or error presentation, optionally with retry.
  Widget _stateMessage(
    BuildContext context, {
    required IconData icon,
    required String message,
    VoidCallback? onAction,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (onAction != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onAction,
              child: Text(L10n.of(context)!.exercisePickerRetryButtonLabel),
            ),
          ],
        ],
      ),
    );
  }

  /// Resolves [future] into its loading, error, empty, or item-list UI.
  Widget _body(BuildContext context) {
    final currentFuture = future;
    if (currentFuture == null) return const SizedBox.shrink();

    return FutureBuilder<List<T>>(
      future: currentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _stateMessage(
            context,
            icon: Icons.error_outline,
            message: errorLabel,
            onAction: onRetry,
          );
        }

        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return _stateMessage(
            context,
            icon: Icons.search_off,
            message: emptyLabel,
          );
        }

        return Visibility(
          // Hide the list if there's only one item and it's already selected.
          visible: items.length != 1 || selectedItem == null,
          child: Column(
            children: [
              for (final item in items)
                PlatformListTile(
                  title: PlatformText(
                    itemLabel(item),
                    style: itemTextStyle?.call(context, item),
                  ),
                  trailing: item == selectedItem
                      ? Icon(
                          context.platformIcons.checkMark,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () => onSelect(item),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      if (headerChild != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: headerChild,
        ),
      _body(context),
    ],
  );
}
