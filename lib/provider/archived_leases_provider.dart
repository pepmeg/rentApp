import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/CompletedLease.dart';

class ArchivedLeasesProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<CompletedLease> _completedLeases = [];
  StreamSubscription<QuerySnapshot>? _archiveSub;
  bool _isListening = false;

  List<CompletedLease> get completedLeases => _completedLeases;

  void listenForUser(String userId) {
    if (_isListening) return;
    _archiveSub?.cancel();
    _archiveSub = _firestore
        .collection('lease_requests_archive')
        .where('requesterId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .orderBy('endDate', descending: true)
        .snapshots()
        .listen((snapshot) {
      _completedLeases = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CompletedLease.fromJson(data, doc.id);
      }).toList();
      _isListening = true;
      notifyListeners();
    });
  }

  Future<void> loadArchivedForUser(String userId) async {
    final snapshot = await _firestore
        .collection('lease_requests_archive')
        .where('requesterId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .orderBy('endDate', descending: true)
        .get();
    _completedLeases = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return CompletedLease.fromJson(data, doc.id);
    }).toList();
    notifyListeners();
  }

  void stopListening() {
    _archiveSub?.cancel();
    _archiveSub = null;
    _isListening = false;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}