import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:q_master/ui/cupertino_sheet_fork.dart' as sheet;

void main() {
  for (final nested in [false, true]) {
    testWidgets('Cupertino sheet opens and closes with nested=$nested', (
      tester,
    ) async {
      String? result;
      await tester.pumpWidget(
        cupertino.CupertinoApp(
          theme: const cupertino.CupertinoThemeData(
            brightness: Brightness.dark,
          ),
          home: Builder(
            builder: (context) => GestureDetector(
              onTap: () async {
                result = await sheet.showCupertinoSheet<String>(
                  context: context,
                  useNestedNavigation: nested,
                  pageBuilder: (context) => cupertino.CupertinoPageScaffold(
                    child: Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pop('closed'),
                        child: const Text('Close sheet'),
                      ),
                    ),
                  ),
                );
              },
              child: const Center(child: Text('Open sheet')),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();
      final sheetContext = tester.element(find.text('Close sheet'));
      expect(
        cupertino.CupertinoTheme.of(sheetContext).brightness,
        Brightness.dark,
      );
      await tester.tap(find.text('Close sheet'));
      await tester.pumpAndSettle();
      expect(find.text('Close sheet'), findsNothing);
      expect(result, 'closed');
    });
  }
}
