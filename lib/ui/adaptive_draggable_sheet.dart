import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:stupid_simple_sheet/stupid_simple_sheet.dart';

/// Presents a modal sheet that can be extended by dragging.
Future<T?> showAdaptiveDraggableSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  if (defaultTargetPlatform == .android) {
    Widget dragHandle() {
      final bottomSheetTheme = Theme.of(context).bottomSheetTheme;
      final dragHandleSize =
          bottomSheetTheme.dragHandleSize ?? const Size(60, 4);
      return Container(
        width: dragHandleSize.width,
        height: dragHandleSize.height,
        margin: const EdgeInsets.only(top: 12, bottom: 12),
        decoration: BoxDecoration(
          color: bottomSheetTheme.dragHandleColor!,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

    return Navigator.of(context, rootNavigator: true).push(
      StupidSimpleSheetRoute(
        snappingConfig: SheetSnappingConfig([0.7, 1.0], initialSnap: 0.7),
        child: SafeArea(
          // Add additional top padding to allow the content behind to be visible
          // when adding a new exercise to the list.
          minimum: const EdgeInsets.only(top: 180),
          bottom: false,
          child: SheetBackground(
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                dragHandle(),
                Expanded(child: builder(context)), // You control all styling
              ],
            ),
          ),
        ),
      ),
    );
  } else {
    return GlassModalSheet.show(
      context: context,
      useRootNavigator: true,
      dragIndicatorWidth: 64,
      halfSize: 0.6,
      fullSize: 0.9,
      builder: builder,
    );
  }
}
