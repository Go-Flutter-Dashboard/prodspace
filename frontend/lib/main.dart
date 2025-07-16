import 'package:flutter/material.dart';
import 'login_n_regestration/logged_in.dart';
import 'pages.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  // Path to folder with user variables
  final appDocDir = await getApplicationDocumentsDirectory();
  // Box with user variables init
  Hive.init(appDocDir.path);
  // Create box for user parameters
  await Hive.openBox('user_parameters');
  // Create box for settings
  await Hive.openBox('settings');
  // Create box for uncommited changes in canvas
  await Hive.openBox('changes');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // Navigator key
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Your Workspace',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: AppThemes.thememode,
      initialRoute: '/',
      routes: {
        '/': (context) => FutureBuilder<bool>(
          future: hasLoggedInBefore(),
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return const BoardPage();
            // if (snapshot.data == true) {
            //   return const BoardPage();
            // } else {
            //   return const LoginPage(); 
            // }
          },
        ),
        '/home': (context) => const BoardPage(),
        //'/login': (context) => const LoginPage(),
        //'/register': (context) => const RegisterPage(),
      },
    );
  }
}
