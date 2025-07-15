import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:prodspace/functions/logged_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  // Controllers for email and password
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Submit button pressed
  void _submit() async {
    if (_formKey.currentState!.validate()) {
      // Get values from controllers
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Request to backend
      final response = await http.post(
        Uri.parse(
          'localhost:8080'
        ),
        headers: {'Content-Type': 'application/json'},
        body: '{"email": "$email", "password": "$password"}',
      );

      // Bad response case
      if (response.statusCode != 200) {
        // Log failure
        debugPrint('Login failed: ${response.statusCode}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${response.reasonPhrase}'),
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
      final userBox = Hive.box('user_parameters');
      userBox.put('email', email);
      final responseJson = jsonDecode(response.body);
      userBox.put('name', '${responseJson['name']}');

      // Log success
      debugPrint('Logged in: $email, $password');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged in: $email'),
          duration: const Duration(seconds: 1),
        ),
      );

      // Save user logged in
      await setLoggedIn(true);
      if (!mounted) return;

      // Navigate to main page
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
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
                  'Login to Your Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter email';
                              }
                              final emailPattern = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                              );
                              if (!emailPattern.hasMatch(value)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                            obscureText: true,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (value) =>
                                value != null && value.length >= 6
                                ? null
                                : 'Min 6 characters',
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _submit,
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/register'),
                  child: const Text('Don\'t have an account? Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}