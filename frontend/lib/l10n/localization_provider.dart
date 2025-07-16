import 'package:flutter/material.dart';
import 'package:prodspace/l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocaleProvider with ChangeNotifier {
  Locale? _locale;
  bool _isLoading = true;

  Locale? get locale => _locale;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    final box = await Hive.openBox('settings');
    final localeCode = box.get('locale');
    if (localeCode != null) {
      _locale = Locale(localeCode);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (!AppLocalizations.supportedLocales.contains(locale)) return;
    _locale = locale;
    final box = await Hive.openBox('settings');
    await box.put('locale', locale.languageCode);
    notifyListeners();
  }

  Future<void> clearLocale() async {
    _locale = null;
    final box = await Hive.openBox('settings');
    await box.delete('locale');
    notifyListeners();
  }
}