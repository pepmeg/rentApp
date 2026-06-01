import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class BasketProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, List<CartItem>> _cache = {};
  StreamSubscription<QuerySnapshot>? _cartSub;

  List<CartItem> getItemsForUser(String userId) => _cache[userId] ?? [];

  int totalPriceForUser(String userId) =>
      getItemsForUser(userId).fold(0, (total, item) => total + item.totalAmount);

  Future<void> loadForUser(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .get();
    final items = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return CartItem.fromJson(data);
    }).toList();
    _cache[userId] = items;
    notifyListeners();
  }

  void listenForUser(String userId) {
    _cartSub?.cancel();
    _cartSub = _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .snapshots()
        .listen((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CartItem.fromJson(data);
      }).toList();
      _cache[userId] = items;
      notifyListeners();
    });
  }

  Future<void> removeItemById(String userId, String productId) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(productId);
    await docRef.delete();
  }

  void stopListening() {
    _cartSub?.cancel();
    _cartSub = null;
  }

  Future<void> addToCartForUser(String userId, CartItem item) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(item.id)
        .set(item.toJson());
    await loadForUser(userId);
  }

  void addLocalItem(String userId, CartItem item) {
    _cache.putIfAbsent(userId, () => []);
    _cache[userId]!.add(item);
    notifyListeners();
  }

  void removeItem(String userId, String productId) {
    _cache[userId]?.removeWhere((item) => item.id == productId);
    notifyListeners();
  }

  Future<void> clearCartForUser(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    _cache.remove(userId);
    notifyListeners();
  }

  Future<void> markReminderSent(String userId, String productId) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(productId);
    await docRef.update({'reminderSent': true});
  }
}