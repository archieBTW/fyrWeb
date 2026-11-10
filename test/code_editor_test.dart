import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
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

  testWidgets('Line numbers and code stay anchored to the left against the file tree on resize', (tester) async {
    for (final width in [700.0, 1100.0, 1500.0, 2000.0]) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: width,
              height: 900,
              child: const CodeEditorApp(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final line1 = tester.getTopLeft(find.text('1'));
      final code = tester.getTopLeft(find.byType(HighlightView));

      // Tree is 240 wide by default, divider is 6. The line numbers gutter should be
      // anchored immediately next to the divider (around x = 246 + 10px gutter padding)
      // and NOT floating in the middle of a 1500px or 2000px screen!
      expect(line1.dx, lessThanOrEqualTo(270.0));
      expect(code.dx, lessThanOrEqualTo(310.0));
    }
  });
}
