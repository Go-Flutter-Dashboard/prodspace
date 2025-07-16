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
    final colorScheme = theme.colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
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
                  Text(AppLocalizations.of(context)!.darkMode, style: theme.textTheme.titleMedium?.copyWith(
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
                            value ? AppLocalizations.of(context)!.darkModeEnabled : AppLocalizations.of(context)!.lightModeEnabled,
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
                  Text(AppLocalizations.of(context)!.useSystemTheme, style: theme.textTheme.titleMedium?.copyWith(
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
                            value ? AppLocalizations.of(context)!.systemModeEnabled : AppLocalizations.of(context)!.lightModeEnabled,
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
          ],
        ),
      ),
    );
  }
}