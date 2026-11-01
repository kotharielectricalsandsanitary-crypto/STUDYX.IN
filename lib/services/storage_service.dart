import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

class StorageService {
  static const String userKey = "studyx_user";
  static const String firstTimeKey = "studyx_first_time";

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      userKey,
      jsonEncode(user.toMap()),
    );

    await prefs.setBool(firstTimeKey, true);
  }

  static Future<bool> isFirstSetupDone() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(firstTimeKey) ?? false;
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString(userKey);

    if (data == null) return null;

    return UserModel.fromMap(
      jsonDecode(data),
    );
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
  }
}