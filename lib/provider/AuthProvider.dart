import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/models/user.dart';

class AuthProvider extends ChangeNotifier {

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  AuthProvider() {
    loadUserData();
  }

  Future<bool> register(UserModel user) async {
    _setLoading(true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String userKey = 'user_${user.email}';

      await prefs.setString(userKey, jsonEncode(user.toJson()));
      await prefs.setString('current_user_email', user.email);

      _currentUser = user;
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      print('Ошибка регистрации: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);

    final prefs = await SharedPreferences.getInstance();
    final userJsonString = prefs.getString('user_$email');
    if (userJsonString != null) {
      final userData = jsonDecode(userJsonString) as Map<String, dynamic>;
      if (userData['password'] == password) {
        _currentUser = UserModel.fromJson(userData);
        await prefs.setString('current_user_email', email);
        _setLoading(false);
        notifyListeners();
        return true;
      }
    }
    _setLoading(false);
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_email');
    notifyListeners();
  }

  Future<void> loadUserData() async{
    _setLoading(true);

    try{
      final prefs = await SharedPreferences.getInstance();
      final String? currentUserEmail = prefs.getString('current_user_email');

      if (currentUserEmail != null) {
        final String? userJsonString = prefs.getString('user_$currentUserEmail');

        if(userJsonString != null) {{
          final Map<String, dynamic> userData = jsonDecode(userJsonString);
          _currentUser = UserModel.fromJson(userData);
        }
        }
      }
    } catch (e) {
      print('Ошибка загрузки данных пользователя: $e');
    }
    _setLoading(false);
    notifyListeners();
  }

  bool get isAuthenticated => _currentUser != null;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}