# Frontend (Flutter)

## Оглавление

- [Структура проекта](#структура-проекта)
- [Точка входа и маршрутизация](#точка-входа-и-маршрутизация)
- [Аутентификация](#аутентификация)
- [Интерактивная доска](#интерактивная-доска)
- [Темы приложения](#темы-приложения)
- [Локальное хранилище данных: Hive](#локальное-хранилище-данных-hive)
- [Зависимости](#зависимости)
- [Запуск приложения](#запуск-приложения)
- [Платформы и поддержка](#платформы-и-поддержка)

---

## Структура проекта

```
lib/
  main.dart                — точка входа приложения
  pages.dart               — экспорт страниц для маршрутизации
  theme/
    app_theme.dart         — светлая и тёмная темы приложения
  login_n_regestration/
    login_page.dart        — страница входа
    registration_page.dart — страница регистрации
    logged_in.dart         — виджет для авторизованного пользователя
  board/
    domain/
      models/
        board_models.dart  — модели данных доски (BoardObject, ToolType и др.)
      services/            — бизнес-логика (может быть расширена)
      utils/               — утилиты для работы с доской
    presentation/
      pages/
        board_page.dart    — основная страница доски
      widgets/
        board_object_widget.dart — виджет для отображения объектов доски
        toolbar.dart              — тулбар с инструментами
        selection_actions.dart    — действия над выделением
        draw_color_picker.dart    — выбор цвета для рисования
        dashed_rect.dart          — пунктирная рамка для выделения
        color_picker_dialog.dart  — диалог выбора цвета
        board_painter.dart        — кастомный painter для рисования
```

---

## Точка входа и маршрутизация

- Входная точка: `main.dart`
- Используется `MaterialApp` с маршрутизацией через `routes`.
- Основной маршрут (`/`) ведёт на доску (`BoardPage`).
- В коде предусмотрена поддержка страниц входа и регистрации (закомментированы).

---

## Аутентификация

- Модуль `login_n_regestration/` содержит страницы входа (`login_page.dart`), регистрации (`registration_page.dart`) и виджет для авторизованного пользователя (`logged_in.dart`).
- В текущей конфигурации аутентификация не активна, но легко включается через маршруты.

---

## Интерактивная доска

- Основная логика — в `board/presentation/pages/board_page.dart`.
- Поддерживаются инструменты: навигация, выделение, прямоугольник, круг, текст, рисование, изображение.
- Для каждого объекта реализовано:
  - Перемещение
  - Изменение размера (resize-ручки)
  - Изменение цвета (для фигур и текста)
  - Добавление изображений (image picker/file picker)
- Все объекты описаны в `board/domain/models/board_models.dart`.

---

## Темы приложения

- В `theme/app_theme.dart` определены светлая и тёмная темы.
- Переключение темы реализовано через `themeMode` в `MaterialApp`.

---

## Локальное хранилище данных: Hive

В проекте используется [Hive](https://pub.dev/packages/hive) для кроссплатформенного хранения данных (Web, Desktop, Mobile).

### Как работает Hive в проекте
- На **мобильных и десктопных** платформах Hive хранит данные в файловой системе приложения.
- На **Web** Hive использует IndexedDB (через `hive_flutter`).
- Инициализация и открытие box-ов происходит в `main.dart`:

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    final appDocDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocDir.path);
  } else {
    await Hive.initFlutter();
  }
  await Hive.openBox('user_parameters');
  await Hive.openBox('settings');
  await Hive.openBox('changes');
  runApp(MyApp());
}
```

### Основные box-ы:
- `user_parameters` — пользовательские параметры
- `settings` — настройки приложения
- `changes` — несохранённые изменения на доске

### Использование Hive в коде

```dart
var box = Hive.box('settings');
box.put('theme', 'dark');
var theme = box.get('theme', defaultValue: 'light');
```

---

## Зависимости

Основные зависимости (см. `pubspec.yaml`):

- `flutter`
- `hive`, `hive_flutter` — локальное хранилище
- `path_provider` — доступ к файловой системе (не для web)
- `shared_preferences` — простое хранилище настроек
- `flutter_colorpicker` — выбор цвета
- `http` — сетевые запросы
- `image_picker` — выбор изображений (мобильные/десктоп)
- и др.

---

## Запуск приложения

1. Установите зависимости:
   ```
   flutter pub get
   ```
2. Запустите на нужной платформе:
   - Web:
     ```
     flutter run -d chrome
     ```
   - Android/iOS:
     ```
     flutter run
     ```
   - Windows/macOS/Linux:
     ```
     flutter run -d windows
     ```

---

## Платформы и поддержка

- Поддерживаются: Web, Android, iOS, Windows, macOS, Linux.
- Для хранения данных используется Hive (работает везде).
- Для выбора изображений на Web рекомендуется использовать file_picker вместо image_picker.

---

**Если вы добавляете новые box-ы или храните сложные объекты, не забудьте зарегистрировать адаптеры (см. документацию Hive).**
