// Functions related to login and already logged in users
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Check if user is logged in
Future<bool> hasLoggedInBefore() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('hasLoggedIn') ?? false;
}

// Set logged in
Future<void> setLoggedIn(bool isLoggedIn) async {
  final prefs = await SharedPreferences.getInstance();
  // Clear boxes if not logged in
  if (!isLoggedIn) {
    // Clear user parameters
    if (!Hive.isBoxOpen('user_parameters')) {
      await Hive.openBox('user_parameters');
    }
    Hive.box('user_parameters').clear();
    Hive.box('settings').clear();
    // Clear unsaved changes
    if (!Hive.isBoxOpen('changes')) {
      await Hive.openBox('changes');
    }
    Hive.box('changes').clear();
  }
  // Set bool variable
  await prefs.setBool('hasLoggedIn', isLoggedIn);
}