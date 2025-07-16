import 'package:flutter/material.dart';
import 'package:prodspace/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:prodspace/theme/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
        backgroundColor: theme.colorScheme.tertiary,
        foregroundColor: theme.colorScheme.onTertiary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark Mode Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.darkMode, style: theme.textTheme.titleMedium),
                Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) async {
                    themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value ? AppLocalizations.of(context)!.darkModeEnabled : AppLocalizations.of(context)!.lightModeEnabled),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            // System Theme Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.useSystemTheme, style: theme.textTheme.titleMedium),
                Switch(
                  value: themeProvider.isSystemMode,
                  onChanged: (value) async {
                    themeProvider.setThemeMode(value ? ThemeMode.system : ThemeMode.light);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value ? AppLocalizations.of(context)!.systemModeEnabled : AppLocalizations.of(context)!.lightModeEnabled),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}