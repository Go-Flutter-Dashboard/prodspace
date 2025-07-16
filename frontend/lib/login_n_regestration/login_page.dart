import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:prodspace/l10n/app_localizations.dart';
import 'package:prodspace/login_n_regestration/logged_in.dart';
import 'package:prodspace/settings/presentations/widgets/settings_btn.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
        Uri.parse('http://localhost:3000/login'),
        headers: {'Content-Type': 'application/json'},
        // {'Authorization': "Baerer $token"}
        body: '{"login": "$username", "password": "$password"}',
      );

      // Bad response case
      if (response.statusCode < 200 || response.statusCode > 299) {
        // Log failure
        debugPrint('Login failed: ${response.statusCode}');
        if (!mounted) return;
        // Show error state
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${response.reasonPhrase}'),
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
      final userBox = Hive.box('user_parameters');
      userBox.put('username', username);
      final responseJson = jsonDecode(response.body);
      userBox.put('token', responseJson['token']);

      // Log success
      debugPrint('Logged in: $username');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged in: $username'),
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

      // Navigate to main page
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.login),
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
                          AppLocalizations.of(context)!.loginToAccount,
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
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextFormField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      labelText: AppLocalizations.of(
                                        context,
                                      )!.username,
                                    ),
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return AppLocalizations.of(
                                          context,
                                        )!.enterUsername;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      labelText: AppLocalizations.of(
                                        context,
                                      )!.password,
                                    ),
                                    obscureText: true,
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    validator: (value) =>
                                        value != null && value.length >= 6
                                        ? null
                                        : AppLocalizations.of(
                                            context,
                                          )!.min6chars,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _submit,
                                    child: Text(
                                      AppLocalizations.of(context)!.login,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            '/register',
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.dontHaveAccount,
                          ),
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
