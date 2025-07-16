import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:prodspace/l10n/app_localizations.dart';
import 'package:prodspace/login_n_regestration/logged_in.dart';
import 'package:prodspace/settings/presentations/widgets/settings_btn.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for name and password
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  // State management
  bool isLoading = false;

  // Submit button pressed
  void _submit() async {
    if (_formKey.currentState!.validate()) {
      // Update state
      setState(() {
        isLoading = true;
      });

      // Get values from controllers
      final username = _nameController.text.trim();
      final password = _passwordController.text;

      // Request to backend
      final response = await http.post(
        Uri.parse('http://localhost:3000/register'),
        headers: {'Content-Type': 'application/json'},
        body: '{"login": "$username", "password": "$password"}',
      );

      // Bad response case
      if (response.statusCode < 200 || response.statusCode > 299) {
        // Log failure
        debugPrint('Registration failed: ${response.statusCode}');
        if (!mounted) return;
        // Show error state
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${response.reasonPhrase}'),
            duration: const Duration(seconds: 1),
          ),
        );
        // Update state
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Good response case

      // Save valiues to box
      if (!Hive.isBoxOpen('user_parameters')) {
        await Hive.openBox('user_parameters');
      }
      final settingsBox = Hive.box('user_parameters');
      settingsBox.put('username', username);
      final responseJson = jsonDecode(response.body);
      settingsBox.put('token', responseJson['token']);

      // Log success
      debugPrint('Registered: $username');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registered: $username'),
          duration: const Duration(seconds: 1),
        ),
      );

      // Save user logged in
      await setLoggedIn(true);
      if (!mounted) return;

      // Update state
      setState(() {
        isLoading = false;
      });

      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.register),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        actions: [settingsButton(context)],
      ),
      body: Container(
        color: colorScheme.surface,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Text(
                          localizations.createAccount,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      labelText: localizations.username,
                                    ),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                        ? localizations.enterUsername
                                        : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordController,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    decoration: InputDecoration(
                                      labelText: localizations.password,
                                    ),
                                    obscureText: true,
                                    validator: (value) =>
                                        value != null && value.length >= 6
                                        ? null
                                        : localizations.min6chars,
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: _submit,
                                    child: Text(localizations.submit),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          child: Text(localizations.haveAccount),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () async {
                            if (!Hive.isBoxOpen('user_parameters')) {
                              await Hive.openBox('user_parameters');
                            }
                            final settingsBox = Hive.box('user_parameters');
                            settingsBox.put('username', 'Guest Mode');

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Logged in as Guest'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                            if (!context.mounted) return;
                            Navigator.pushReplacementNamed(context, '/home');
                          },
                          child: Text(localizations.enterWithoutRegistration),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
