import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:billyrigdon/apps/code_editor_app.dart';

void main() {
  testWidgets('CodeEditorApp renders hierarchical tree and code with no empty pane', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CodeEditorApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify WORKSPACE header and collapse icon exist
    expect(find.text('WORKSPACE'), findsOneWidget);
    expect(find.byIcon(Icons.view_sidebar_outlined), findsOneWidget);

    // Verify hierarchical folders exist (e.g. 'lib')
    expect(find.text('lib'), findsOneWidget);

    // Verify active file tab exists ('main.dart')
    expect(find.text('main.dart'), findsWidgets);

    // Verify divider exists between tree and code
    final dividerFinder = find.byType(MouseRegion).first;
    expect(dividerFinder, findsWidgets);

    // Verify resizability: find draggable divider and drag it
    final initialTreeSizedBox = tester.widget<SizedBox>(
      find.ancestor(
        of: find.text('WORKSPACE'),
        matching: find.byType(SizedBox),
      ).first,
    );
    expect(initialTreeSizedBox.width, equals(240.0));

    // Drag the divider by 50px to the right
    final dragGestureFinder = find.byType(GestureDetector);
    // Find the one with onHorizontalDragUpdate
    Finder? resizerFinder;
    for (final el in dragGestureFinder.evaluate()) {
      final gd = el.widget as GestureDetector;
      if (gd.onHorizontalDragUpdate != null) {
        resizerFinder = find.byWidget(gd);
        break;
      }
    }
    expect(resizerFinder, isNotNull);

    await tester.drag(resizerFinder!, const Offset(50, 0));
    await tester.pumpAndSettle();

    final resizedTreeSizedBox = tester.widget<SizedBox>(
      find.ancestor(
        of: find.text('WORKSPACE'),
        matching: find.byType(SizedBox),
      ).first,
    );
    expect(resizedTreeSizedBox.width, equals(290.0));

    // Verify collapsibility: tap collapse button
    final collapseBtn = find.byIcon(Icons.view_sidebar_outlined);
    await tester.tap(collapseBtn);
    await tester.pumpAndSettle();

    // Tree should now be collapsed (WORKSPACE not visible)
    expect(find.text('WORKSPACE'), findsNothing);

    // Expand button should now be present in tab bar
    expect(find.byIcon(Icons.chevron_right), findsWidgets);
    final expandBtn = find.ancestor(
      of: find.byIcon(Icons.chevron_right),
      matching: find.byType(InkWell),
    ).first;
    await tester.tap(expandBtn);
    await tester.pumpAndSettle();

    // Tree should now be restored
    expect(find.text('WORKSPACE'), findsOneWidget);
  });
}
