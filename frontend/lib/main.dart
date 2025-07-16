import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_n_regestration/logged_in.dart';
import 'pages.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    final appDocDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocDir.path);
  } else {
    await Hive.initFlutter();
  }
  await Hive.openBox('user_parameters');
  await Hive.openBox('settings');
  await Hive.openBox('changes');

  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // Navigator key
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (themeProvider.isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Your Workspace',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => FutureBuilder<bool>(
          future: hasLoggedInBefore(),
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            //return const BoardPage();
            if (snapshot.data == true) {
              return const BoardPage();
            } else {
              return const LoginPage(); 
            }
          },
        ),
        '/home': (context) => const BoardPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
