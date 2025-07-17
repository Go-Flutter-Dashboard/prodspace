// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Ваш рабочий стол';

  @override
  String get login => 'Войти';

  @override
  String get register => 'Регистрация';

  @override
  String get username => 'Имя пользователя';

  @override
  String get password => 'Пароль';

  @override
  String get loginToAccount => 'Вход в аккаунт';

  @override
  String get dontHaveAccount => 'Нет аккаунта? Зарегистрируйтесь';

  @override
  String get enterUsername => 'Введите имя пользователя';

  @override
  String get min6chars => 'Минимум 6 символов';

  @override
  String get darkMode => 'Темная тема';

  @override
  String get useSystemTheme => 'Использовать системную тему';

  @override
  String get settings => 'Настройки';

  @override
  String get darkModeEnabled => 'Темный режим включен';

  @override
  String get lightModeEnabled => 'Светлый режим включен';

  @override
  String get systemModeEnabled => 'Системная тема включена';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get submit => 'Отправить';

  @override
  String get haveAccount => 'Уже есть аккаунт? Войти';

  @override
  String get enterWithoutRegistration =>
      "Хотите попробовать без регистрации? Войдите как гость";

  @override
  String get language => "Язык";

  @override
  String get languageChanged => "Язык успешно изменен!";

  @override
  String get changeErr => "Ошибка при отправке изменений";

  @override
  String get changeSuccess => "Изменения успешно сохранены";

  @override
  String get chooseColor => "Выберите цвет";

  @override
  String get circle => "Круг";

  @override
  String get color => "Цвет";

  @override
  String get delete => "Удалить";

  @override
  String get drawing => "Рисование";

  @override
  String get inputText => "Введите текст";

  @override
  String get mark => "Выделение";

  @override
  String get markerColor => "Цвет маркера";

  @override
  String get navigaton => "Навигация";

  @override
  String get noToken => "Токен не найден!";

  @override
  String get parseErr => "Ошибка при обработке данных";

  @override
  String get pic => "Изображение";

  @override
  String get rect => "Прямоугольник";

  @override
  String get saveBoard => "Сохранить доску";

  @override
  String get saveInGuestMode =>
      "Недоступно в гостевом режиме. Войдите или зарегистрируйтесь, чтобы сохранить изменения";

  @override
  String get text => "Текст";

  @override
  String get workspace => "Доска продуктивности";

  @override
  String get workspaceLoading => "Загрузка рабочего пространства...";
}
