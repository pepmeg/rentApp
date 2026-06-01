import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BrandService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _brands = [];
  late StreamSubscription<QuerySnapshot> _subscription;

  List<String> get brands => _brands;

  void startListening() {
    _subscription = _firestore
        .collection('brands')
        .orderBy('name')
        .snapshots()
        .listen((snapshot) {
      _brands = snapshot.docs.map((doc) => doc.data()['name'] as String).toList();
      notifyListeners();
    });
  }

  Future<void> addBrand(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) return;
    final lower = normalized.toLowerCase();
    final snapshot = await _firestore
        .collection('brands')
        .where('lowercase', isEqualTo: lower)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      await _firestore.collection('brands').add({
        'name': normalized,
        'lowercase': lower,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}