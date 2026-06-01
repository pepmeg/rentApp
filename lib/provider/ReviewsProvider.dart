import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/review.dart';
import '../models/activeLease.dart';
import '../services/product_service.dart';
import 'activeLeasesProvider.dart';

class ReviewsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Review> _reviews = [];

  ReviewsProvider() {
    loadFromFirestore();
  }

  List<Review> get reviews => _reviews;

  List<Review> getReviewsForProduct(String productId) =>
      _reviews.where((r) => r.productId == productId).toList();

  Future<void> loadFromFirestore() async {
    final snapshot = await _firestore.collection('reviews').get();
    _reviews = snapshot.docs.map((doc) {
      final data = doc.data();
      return Review.fromJson(data, docId: doc.id);
    }).toList();
    notifyListeners();
  }

  bool canUserReview(String userId, String productId, ActiveLeasesProvider leases) {
    return leases.leases.any((lease) =>
    lease.productId == productId &&
        lease.userId == userId &&
        (lease.status == LeaseStatus.active || lease.isCompleted));
  }

  Review? getUserReview(String userId, String productId) {
    try {
      return _reviews.firstWhere((r) => r.userId == userId && r.productId == productId);
    } catch (_) {
      return null;
    }
  }

  Future<void> addReview(Review review) async {
    final docRef = await _firestore.collection('reviews').add(review.toJson());
    final newReview = Review.fromJson(review.toJson(), docId: docRef.id);
    _reviews.add(newReview);
    notifyListeners();
  }

  Future<void> updateReview(String reviewId, int newRating, String newText) async {
    final docRef = _firestore.collection('reviews').doc(reviewId);
    await docRef.update({'rating': newRating, 'text': newText});
    final index = _reviews.indexWhere((r) => r.id == reviewId);
    if (index != -1) {
      _reviews[index] = Review(
        id: reviewId,
        productId: _reviews[index].productId,
        userId: _reviews[index].userId,
        userName: _reviews[index].userName,
        userAvatarPath: _reviews[index].userAvatarPath,
        createdAt: _reviews[index].createdAt,
        rating: newRating,
        text: newText,
      );
      notifyListeners();
    }
  }

  Future<void> deleteReview(String reviewId) async {
    final docRef = _firestore.collection('reviews').doc(reviewId);
    await docRef.delete();
    _reviews.removeWhere((r) => r.id == reviewId);
    notifyListeners();
  }

  Future<void> deleteReviewsByUser(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    await loadFromFirestore();
  }

  Future<double> getUserRating(String userId) async {
    final products = await ProductService.getAllProducts(ownerId: userId);
    final productIds = products.map((p) => p.id).toSet();
    if (productIds.isEmpty) return 0.0;
    double sum = 0;
    int count = 0;
    for (final review in _reviews) {
      if (productIds.contains(review.productId)) {
        sum += review.rating;
        count++;
      }
    }
    return count > 0 ? sum / count : 0.0;
  }
}