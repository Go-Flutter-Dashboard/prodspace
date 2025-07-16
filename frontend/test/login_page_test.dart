import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prodspace/login_n_regestration/login_page.dart';

void main() {
  testWidgets('LoginPage: валидация и нажатие кнопки', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    // Проверяем наличие полей
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Login to Your Account'), findsOneWidget);

    // Оставляем поля пустыми и нажимаем Login
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();
    expect(find.text('Enter username'), findsOneWidget);
    expect(find.text('Min 6 characters'), findsOneWidget);

    // Вводим некорректный пароль
    await tester.enterText(find.byType(TextFormField).at(0), 'user');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();
    expect(find.text('Min 6 characters'), findsOneWidget);

    // Вводим корректные данные
    await tester.enterText(find.byType(TextFormField).at(0), 'user');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pump();
    // Проверяем, что появляется ошибка (т.к. http всегда 400)
    expect(find.textContaining('Login failed'), findsOneWidget);
  });
} 