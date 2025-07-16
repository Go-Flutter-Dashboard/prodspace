import 'package:flutter/material.dart';
import 'package:prodspace/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:prodspace/theme/theme_provider.dart';
import 'package:prodspace/login_n_regestration/logged_in.dart';
import 'package:prodspace/l10n/localization_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _getFlag(String code) {
    switch (code) {
      case 'ru': return '🇷🇺';
      case 'en': 
      default: return '🇬🇧';
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'ru': return 'Русский';
      case 'en':
      default: return 'English';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localization = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale ?? const Locale('en');

    return Scaffold(
      appBar: AppBar(
        title: Text(localization.settings),
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurfaceVariant,
      ),
      body: Container(
        color: colorScheme.surface,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Section
            Text('Appearance', style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
            )),
            const SizedBox(height: 16),
            // Dark Mode Switch
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(localization.darkMode, style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  )),
                  Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) async {
                      themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: colorScheme.inverseSurface,
                          content: Text(
                            value ? localization.darkModeEnabled : localization.lightModeEnabled,
                            style: TextStyle(color: colorScheme.onInverseSurface),
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    //activeThumbColor: colorScheme.primary,
                    activeTrackColor: colorScheme.primaryContainer,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8.0),
            // System Theme Switch
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(localization.useSystemTheme, style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  )),
                  Switch(
                    value: themeProvider.isSystemMode,
                    onChanged: (value) async {
                      themeProvider.setThemeMode(value ? ThemeMode.system : ThemeMode.light);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: colorScheme.inverseSurface,
                          content: Text(
                            value ? localization.systemModeEnabled : localization.lightModeEnabled,
                            style: TextStyle(color: colorScheme.onInverseSurface),
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    activeThumbColor: colorScheme.primary,
                    activeTrackColor: colorScheme.primaryContainer,
                  ),
                ],
              ),
            ),
            Text(localization.language, 
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
              )),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButton<Locale>(
                value: currentLocale,
                isExpanded: true,
                underline: const SizedBox(),
                items: AppLocalizations.supportedLocales.map((Locale locale) {
                  final flag = _getFlag(locale.languageCode);
                  final language = _getLanguageName(locale.languageCode);
                  return DropdownMenuItem<Locale>(
                    value: locale,
                    child: Row(
                      children: [
                        Text(flag),
                        const SizedBox(width: 12),
                        Text(language),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (Locale? newLocale) {
                  if (newLocale != null) {
                    localeProvider.setLocale(newLocale);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: colorScheme.inverseSurface,
                        content: Text(
                          AppLocalizations.of(context)!.languageChanged,
                          style: TextStyle(color: colorScheme.onInverseSurface),
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            // Logout button
            const SizedBox(height: 8.0),
              ElevatedButton(
                onPressed: () async {
                  await setLoggedIn(false);
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
                child: Text('Log Out'),
              ),
          ],
        ),
      ),
    );
  }
}