import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:prodspace/login_n_regestration/logged_in.dart';

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

  // Submit button pressed
  void _submit() async {
    if (_formKey.currentState!.validate()) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${response.reasonPhrase}'),
            duration: const Duration(seconds: 1),
          ),
        );
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
      await setLoggedIn(true);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: colorScheme.tertiary,
        foregroundColor: colorScheme.onTertiary,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Create an Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                            decoration: const InputDecoration(
                              labelText: 'Username',
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Enter username'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                            obscureText: true,
                            validator: (value) =>
                                value != null && value.length >= 6
                                ? null
                                : 'Min 6 characters',
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _submit,
                            child: const Text('Submit'),
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
                  child: Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}