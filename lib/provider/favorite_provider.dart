import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteProvider extends ChangeNotifier {
  final Map<int, Set<int>> _favoritesByUser = {};

  bool isFavorite(int userId, int productId) {
    return _favoritesByUser[userId]?.contains(productId) ?? false;
  }

  void toggleFavorite(int userId, int productId) {
    _favoritesByUser.putIfAbsent(userId, () => {});
    if (_favoritesByUser[userId]!.contains(productId)) {
      _favoritesByUser[userId]!.remove(productId);
    } else {
      _favoritesByUser[userId]!.add(productId);
    }
    notifyListeners();
    _saveFavorites(userId);
  }

  Set<int> getFavoritesForUser(int userId) {
    return _favoritesByUser[userId] ?? {};
  }

  void clearFavoritesForUser(int userId) {
    _favoritesByUser.remove(userId);
    notifyListeners();
    _saveFavorites(userId);
  }

  Future<void> loadFavoritesForUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('favorites_$userId');
    if (jsonString != null) {
      final List<dynamic> list = jsonDecode(jsonString);
      _favoritesByUser[userId] = list.cast<int>().toSet();
    } else {
      _favoritesByUser[userId] = {};
    }
    notifyListeners();
  }

  Future<void> _saveFavorites(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final set = _favoritesByUser[userId] ?? {};
    if (set.isEmpty) {
      await prefs.remove('favorites_$userId');
    } else {
      await prefs.setString('favorites_$userId', jsonEncode(set.toList()));
    }
  }
}