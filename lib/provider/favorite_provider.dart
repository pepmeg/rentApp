import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FavoriteProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Set<String>> _favoritesByUser = {};
  bool _favoritesChanged = false;

  bool isFavorite(String userId, String productId) {
    return _favoritesByUser[userId]?.contains(productId) ?? false;
  }

  void markFavoritesChanged() {
    _favoritesChanged = true;
  }

  bool get andClearFavoritesChanged {
    final changed = _favoritesChanged;
    _favoritesChanged = false;
    return changed;
  }

  Future<void> toggleFavorite(String userId, String productId) async {
    _favoritesByUser.putIfAbsent(userId, () => {});
    final isFav = _favoritesByUser[userId]!.contains(productId);
    if (isFav) {
      _favoritesByUser[userId]!.remove(productId);
    } else {
      _favoritesByUser[userId]!.add(productId);
    }
    markFavoritesChanged();
    notifyListeners();

    try {
      if (isFav) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc(productId)
            .delete();
      } else {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc(productId)
            .set({'addedAt': DateTime.now().toIso8601String()});
      }
    } catch (e) {
      debugPrint('Ошибка синхронизации избранного: $e');
      if (isFav) {
        _favoritesByUser[userId]!.add(productId);
      } else {
        _favoritesByUser[userId]!.remove(productId);
      }
      _favoritesChanged = false;
      notifyListeners();
    }
  }

  Set<String> getFavoritesForUser(String userId) {
    return _favoritesByUser[userId] ?? {};
  }

  Future<void> clearFavoritesForUser(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    _favoritesByUser.remove(userId);
    notifyListeners();
  }

  Future<void> loadFavoritesForUser(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .get();
    final ids = snapshot.docs.map((doc) => doc.id).toSet();
    _favoritesByUser[userId] = ids;
    notifyListeners();
  }
}