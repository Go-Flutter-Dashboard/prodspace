// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Your Workspace';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get loginToAccount => 'Login to Your Account';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Register';

  @override
  String get enterUsername => 'Enter username';

  @override
  String get min6chars => 'Min 6 characters';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get useSystemTheme => 'Use System Theme';

  @override
  String get settings => 'Settings';

  @override
  String get darkModeEnabled => 'Dark mode enabled';

  @override
  String get lightModeEnabled => 'Ligth mode enabled';

  @override
  String get systemModeEnabled => 'System mode enabled';

  @override
  String get createAccount => 'Create an Account';

  @override
  String get submit => 'Sumbit';

  @override
  String get haveAccount => 'Already have an account? Login';

  @override
  String get enterWithoutRegistration => "Want to try without creating an account? Enter as Guest";
}
