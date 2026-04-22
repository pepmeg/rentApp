import 'package:flutter/material.dart';

class FavoriteProvider extends ChangeNotifier {
  final Set<int> _favoriteId = {};

  Set<int> get favoriteId => _favoriteId;

  bool isFavorite(int productId) => _favoriteId.contains(productId);

  void toggleFavorite(int productId) {
    if (_favoriteId.contains(productId)) {
      _favoriteId.remove(productId);
    }
    else {
      _favoriteId.add(productId);
    }
    notifyListeners();
  }
}