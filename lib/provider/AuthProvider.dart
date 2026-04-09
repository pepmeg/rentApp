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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_${user.email}', jsonEncode(user.toJson()));

    _currentUser = user;
    notifyListeners();
    return true;
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);

    final prefs = await SharedPreferences.getInstance();
    final userJsonString = prefs.getString('user_$email');
    if (userJsonString != null) {
      final userData = jsonEncode(userJsonString) as Map<String, String>;
      if (userData['password'] == password) {
        _currentUser = UserModel.fromJson(userData);
        _setLoading(false);
        notifyListeners();
        return true;
      }
    }
    _setLoading(false);
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> loadUserData() async{
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}