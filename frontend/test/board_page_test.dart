import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prodspace/board/presentation/pages/board_page.dart';
import 'package:prodspace/board/presentation/widgets/board_object_widget.dart';

void main() {
  testWidgets('BoardPage smoke test: renders and toolbar works', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: BoardPage()));

    // Проверяем, что BoardPage отрисовался
    expect(find.text('Интерактивная доска'), findsOneWidget);

    // Проверяем наличие кнопки "Прямоугольник" в тулбаре
    expect(find.byTooltip('Прямоугольник'), findsOneWidget);

    // Тап по кнопке "Прямоугольник"
    await tester.tap(find.byTooltip('Прямоугольник'));
    await tester.pump();

    // Тап по доске для добавления прямоугольника
    final board = find.byType(Container).first;
    await tester.tap(board);
    await tester.pump();

    // Проверяем, что появился хотя бы один объект (BoardObjectWidget)
    expect(find.byType(BoardObjectWidget), findsWidgets);
  });
} 