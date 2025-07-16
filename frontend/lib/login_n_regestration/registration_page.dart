import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
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
        Uri.parse(
          'localhost:8080',
        ),
        headers: {'Content-Type': 'application/json'},
        body:
            '{"username": "$username", "password": "$password"}',
      );

      // Bad response case
      if (response.statusCode != 200) {
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
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  
  return Scaffold(
    appBar: AppBar(
      title: const Text('Register'),
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
                ? CircularProgressIndicator(color: colorScheme.primary)
                : Column(
                    children: [
                      Text(
                        'Create an Account',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        color: colorScheme.surfaceContainerHighest,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  style: TextStyle(color: colorScheme.onSurface),
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: colorScheme.outline),
                                    ),
                                  ),
                                  validator: (value) => value?.isEmpty ?? true
                                      ? 'Enter username'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordController,
                                  style: TextStyle(color: colorScheme.onSurface),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: colorScheme.outline),
                                    ),
                                  ),
                                  obscureText: true,
                                  validator: (value) => value != null && value.length >= 6
                                      ? null
                                      : 'Min 6 characters',
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    minimumSize: const Size(double.infinity, 50),
                                  ),
                                  child: const Text('Submit'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                        child: const Text('Already have an account? Login'),
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