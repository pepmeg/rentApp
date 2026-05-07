import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'chat_provider.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  UserModel? _supportUser;
  bool _isLoading = false;
  bool get isUser => _currentUser?.role == 'user';
  bool get isSupport => _currentUser?.role == 'support';
  bool get isAdmin => _currentUser?.role == 'admin';
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

  Future<bool> isEmailRegistered(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('user_$email');
  }

  Future<String?> login(String email, String password) async {
    _setLoading(true);

    final prefs = await SharedPreferences.getInstance();
    final userJsonString = prefs.getString('user_$email');
    if (userJsonString != null) {
      final userData = jsonDecode(userJsonString) as Map<String, dynamic>;
      if (userData['password'] == password) {
        if (userData['blocked'] == true) {
          _setLoading(false);
          return 'Пользователь заблокирован';
        }
        _currentUser = UserModel.fromJson(userData);
        await prefs.setString('current_user_email', email);
        _setLoading(false);
        notifyListeners();
        return null;
      }
    }
    _setLoading(false);
    return 'Неверный email или пароль';
  }

  Future<void> logout({required ChatProvider chatProvider}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_email');
    await chatProvider.saveLastReadToPrefs();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final current = _currentUser;
    if (current != null) {
      final prefs = await SharedPreferences.getInstance();
      final userKey = 'user_${current.email}';
      await prefs.remove(userKey);
      await prefs.remove('current_user_email');
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<UserModel?> getUserById(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('user_')) {
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          final userData = jsonDecode(jsonString);
          if (userData['id'] == id) {
            return UserModel.fromJson(userData);
          }
        }
      }
    }
    return null;
  }

  Future<void> loadUserData() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? currentUserEmail = prefs.getString('current_user_email');
      if (currentUserEmail != null) {
        final String? userJsonString = prefs.getString('user_$currentUserEmail');
        if (userJsonString != null) {
          final Map<String, dynamic> userData = jsonDecode(userJsonString);
          _currentUser = UserModel.fromJson(userData);
        }
      }
      await _loadSupportUser();
    } catch (e) {
      debugPrint('Ошибка загрузки данных пользователя: $e');
    }
    _setLoading(false);
    notifyListeners();
  }

  bool get isAuthenticated => _currentUser != null;


  Future<void> updateUser(UserModel updatedUser) async {
    final prefs = await SharedPreferences.getInstance();
    final oldEmail = _currentUser?.email;
    final newEmail = updatedUser.email;

    if (oldEmail != null && oldEmail != newEmail) {
      await prefs.remove('user_$oldEmail');
    }

    await prefs.setString('user_$newEmail', jsonEncode(updatedUser.toJson()));
    await prefs.setString('current_user_email', newEmail);

    _currentUser = updatedUser;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<String?> changePassword(String oldPassword, String newPassword) async {
    if (_currentUser == null) return 'Пользователь не найден';
    if (_currentUser!.password != oldPassword) {
      return 'Неверный старый пароль';
    }
    if (newPassword.length < 6) {
      return 'Новый пароль должен быть не менее 6 символов';
    }
    final updatedUser = UserModel(
      id: _currentUser!.id,
      email: _currentUser!.email,
      password: newPassword,
      firstName: _currentUser!.firstName,
      lastName: _currentUser!.lastName,
      address: _currentUser!.address,
      phoneNumber: _currentUser!.phoneNumber,
      avatarPath: _currentUser!.avatarPath,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_${updatedUser.email}', jsonEncode(updatedUser.toJson()));
    _currentUser = updatedUser;
    notifyListeners();
    return null;
  }

  Future<UserModel?> getSupportUser() async {
    final prefs = await SharedPreferences.getInstance();
    const supportEmail = 'support@rentapp.local';
    final jsonString = prefs.getString('user_$supportEmail');
    if (jsonString != null) {
      final data = jsonDecode(jsonString);
      return UserModel.fromJson(data);
    }
    final support = UserModel(
      id: 0,
      email: supportEmail,
      password: '',
      firstName: 'Поддержка',
      lastName: '',
      address: '',
      phoneNumber: '',
      role: 'support',
    );
    await prefs.setString('user_$supportEmail', jsonEncode(support.toJson()));
    return support;
  }

  UserModel? getSupportUserSync() {
    return _supportUser;
  }

  Future<void> _loadSupportUser() async {
    final prefs = await SharedPreferences.getInstance();
    const supportEmail = 'support@rentapp.local';
    final jsonString = prefs.getString('user_$supportEmail');
    if (jsonString != null) {
      _supportUser = UserModel.fromJson(jsonDecode(jsonString));
    } else {
      _supportUser = UserModel(
        id: 0,
        email: supportEmail,
        password: '',
        firstName: 'Поддержка',
        lastName: '',
        address: '',
        phoneNumber: '',
        role: 'support',
      );
      await prefs.setString('user_$supportEmail', jsonEncode(_supportUser!.toJson()));
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final List<UserModel> users = [];
    for (final key in keys) {
      if (key.startsWith('user_')) {
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          final userData = jsonDecode(jsonString);
          users.add(UserModel.fromJson(userData));
        }
      }
    }
    return users;
  }
}