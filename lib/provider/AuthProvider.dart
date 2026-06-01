import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/const.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isUser => _currentUser?.role == 'user';
  bool get isSupport => _currentUser?.role == 'support';
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isAuthenticated => _currentUser != null;

  static const String _cachedUserKey = 'cached_user';
  static const String _cachedUserEmailKey = 'cached_user_email';

  bool _profileLoaded = false;
  bool get isProfileLoaded => _profileLoaded;

  AuthProvider() {
    _loadCachedUser();
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  final Map<String, UserModel> _userCache = {};

  Future<void> _loadCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cachedUserKey);
      if (jsonString != null) {
        final Map<String, dynamic> userMap = jsonDecode(jsonString);
        _currentUser = UserModel.fromJson(userMap);
        _profileLoaded = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Ошибка загрузки кеша пользователя: $e');
    }
  }

  Future<void> _cacheUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedUserKey, jsonEncode(user.toJson()));
      await prefs.setString(_cachedUserEmailKey, user.email);
    } catch (e) {
      debugPrint('Ошибка сохранения кеша пользователя: $e');
    }
  }

  void _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _profileLoaded = true;
      notifyListeners();
      return;
    }
    _profileLoaded = false;
    notifyListeners();
    try {
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromJson(doc.data()!);
      } else {
        _currentUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          firstName: firebaseUser.displayName ?? '',
          lastName: '',
        );
        await _firestore.collection('users').doc(firebaseUser.uid).set(_currentUser!.toJson());
      }
      await _cacheUser(_currentUser!);
    } catch (e) {
      if (_currentUser != null && _currentUser!.uid == firebaseUser.uid) {
        debugPrint('Используем кешированный профиль (офлайн)');
      } else {
        _currentUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          firstName: firebaseUser.displayName ?? '',
          lastName: '',
        );
        debugPrint('Создан временный профиль из FirebaseAuth (офлайн)');
      }
    }
    _profileLoaded = true;
    notifyListeners();
  }

  Future<String?> register(
      String email,
      String password,
      String firstName,
      String lastName, {
        String phone = '',
        String address = '',
      }) async {
    _setLoading(true);
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName('$firstName $lastName');
        final newUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? email,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phone,
          address: address,
        );
        await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toJson());
        _currentUser = newUser;
        await _cacheUser(newUser);
        notifyListeners();
      }
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      if (e.code == 'network-request-failed') {
        return 'Нет подключения к интернету. Проверьте соединение.';
      }
      return _mapAuthError(e.code);
    } catch (e) {
      _setLoading(false);
      return 'Ошибка регистрации: ${e.toString()}';
    }
  }

  Future<String?> login(String email, String password) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      if (e.code == 'network-request-failed') {
        return 'Нет подключения к интернету';
      }
      return _mapAuthError(e.code);
    } catch (e) {
      _setLoading(false);
      return 'Ошибка входа: ${e.toString()}';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }

Future<void> syncUserProfile() async {
  final firebaseUser = _auth.currentUser;
  if (firebaseUser == null) return;
  try {
    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists) {
      _currentUser = UserModel.fromJson(doc.data()!);
      await _cacheUser(_currentUser!);
      notifyListeners();
    }
  } catch (e) {
    debugPrint('Ошибка синхронизации профиля: $e');
  }
}

  Future<String?> changePassword(String oldPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return 'Пользователь не найден';

    try {
      final credential = EmailAuthProvider.credential(email: user.email!, password: oldPassword);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } catch (e) {
      return 'Ошибка: ${e.toString()}';
    }
  }

  Future<void> updateUser(UserModel updatedUser) async {
    assert(updatedUser.uid == _auth.currentUser?.uid);
    await _firestore.collection('users').doc(updatedUser.uid).update(updatedUser.toJson());
    _currentUser = updatedUser;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
      _currentUser = null;
      notifyListeners();
    }
  }

  Future<UserModel?> getUserById(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid];
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final user = UserModel.fromJson(doc.data()!);
        _userCache[uid] = user;
        return user;
      }
    } catch (e) {
      debugPrint('Ошибка загрузки пользователя: $e');
    }
    return null;
  }

  Future<String?> getSupportUid() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'support')
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty ? snapshot.docs.first.id : null;
  }

  Future<String?> getAdminUid() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty ? snapshot.docs.first.id : null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((d) => UserModel.fromJson(d.data())).toList();
  }

  Future<void> updateRole(String uid, String newRole) async {
    await _firestore.collection('users').doc(uid).update({'role': newRole});
    if (_currentUser?.uid == uid) {
      _currentUser = UserModel.fromJson({..._currentUser!.toJson(), 'role': newRole});
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> incrementUnpaidLeaseCount(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);
    int newCount = 0;
    DateTime? blockedUntil;

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(userRef);
      final currentCount = (doc.data()?['unpaidLeaseCount'] as int?) ?? 0;
      newCount = currentCount + 1;
      transaction.update(userRef, {'unpaidLeaseCount': newCount});

      if (newCount >= AppConst.maxUnpaidLeaseCount) {
        blockedUntil = DateTime.now().add(const Duration(days: 7));
        transaction.update(userRef, {'blockedUntil': blockedUntil!.toIso8601String()});
      }
    });
    if (_currentUser != null && _currentUser!.uid == uid) {
      final updatedData = _currentUser!.toJson();
      updatedData['unpaidLeaseCount'] = newCount;
      updatedData['blockedUntil'] = blockedUntil?.toIso8601String();
      _currentUser = UserModel.fromJson(updatedData);
      notifyListeners();
    }
  }

  Future<void> resetUnpaidLeaseCount(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'unpaidLeaseCount': 0,
      'blockedUntil': null
    });

    if (_currentUser != null && _currentUser!.uid == uid) {
      final updatedData = _currentUser!.toJson();
      updatedData['unpaidLeaseCount'] = 0;
      updatedData['blockedUntil'] = null;
      _currentUser = UserModel.fromJson(updatedData);
      notifyListeners();
    }
  }

  Future<void> refreshCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return;
    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists) {
      _currentUser = UserModel.fromJson(doc.data()!);
      notifyListeners();
    }
  }

  Future<void> incrementRating(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(userRef);
      final currentRating = (doc.data()?['rating'] as num?)?.toDouble() ?? 5.0;
      double newRating = (currentRating + 0.1).clamp(0.0, 5.0);
      transaction.update(userRef, {'rating': newRating});
      if (_currentUser?.uid == uid) {
        _currentUser = UserModel.fromJson({..._currentUser!.toJson(), 'rating': newRating});
        notifyListeners();
      }
    });
  }

  Future<void> decrementRating(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(userRef);
      final currentRating = (doc.data()?['rating'] as num?)?.toDouble() ?? 5.0;
      double newRating = (currentRating - 0.5).clamp(0.0, 5.0);
      transaction.update(userRef, {'rating': newRating});
      if (_currentUser?.uid == uid) {
        _currentUser = UserModel.fromJson({..._currentUser!.toJson(), 'rating': newRating});
        notifyListeners();
      }
    });
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Этот email уже используется';
      case 'invalid-email':
        return 'Некорректный email';
      case 'operation-not-allowed':
        return 'Операция не разрешена';
      case 'weak-password':
        return 'Слишком слабый пароль (минимум 6 символов)';
      case 'user-disabled':
        return 'Пользователь заблокирован';
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
        return 'Неверный пароль';
      default:
        return 'Ошибка авторизации';
    }
  }
}