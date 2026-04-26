import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/review.dart';
import '../provider/activeLeasesProvider.dart';

class ReviewsProvider extends ChangeNotifier {
  List<Review> _reviews = [];
  static const String _key = 'reviews';

  ReviewsProvider() { loadFromPrefs(); }

  List<Review> get reviews => _reviews;

  List<Review> getReviewsForProduct(int productId) =>
      _reviews.where((r) => r.productId == productId).toList();

  bool canUserReview(int userId, int productId, ActiveLeasesProvider leases) {
    return leases.leases.any((lease) =>
    lease.productId == productId && lease.userId == userId
    );
  }

  void addReview(Review review) {
    _reviews.add(review);
    notifyListeners();
    saveToPrefs();
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _reviews.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key);
    if (jsonList != null) {
      _reviews = jsonList
          .map((s) => Review.fromJson(jsonDecode(s)))
          .toList();
      notifyListeners();
    }
  }

  Review? getUserReview(int userId, int productId) {
    try {
      return _reviews.firstWhere((r) => r.userId == userId && r.productId == productId);
    } catch (_) {
      return null;
    }
  }

  void updateReview(int reviewId, int newRating, String newText) {
    final index = _reviews.indexWhere((r) => r.id == reviewId);
    if (index != -1) {
      _reviews[index] = Review(
        id: _reviews[index].id,
        productId: _reviews[index].productId,
        userId: _reviews[index].userId,
        userName: _reviews[index].userName,
        userAvatarPath: _reviews[index].userAvatarPath,
        createdAt: _reviews[index].createdAt,
        rating: newRating,
        text: newText,
      );
      notifyListeners();
      saveToPrefs();
    }
  }

  void deleteReview(int reviewId) {
    _reviews.removeWhere((r) => r.id == reviewId);
    notifyListeners();
    saveToPrefs();
  }
}