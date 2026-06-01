import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/activeLease.dart';

class ActiveLeasesProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ActiveLease> _leases = [];
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot>? _leasesSub;

  List<ActiveLease> get leases => _leases;
  int get totalLeasesCount => _leases.length;
  int get activeCount => _leases.where((l) => l.status == LeaseStatus.active).length;
  bool get isLoading => _isLoading;

  ActiveLeasesProvider() {
    _startListening();
  }

  void stopListening() {
    _leasesSub?.cancel();
    _leasesSub = null;
  }

  void _startListening() {
    _leasesSub?.cancel();
    _leasesSub = _firestore.collection('leases').snapshots().listen(
          (snapshot) {
        _leases = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return ActiveLease.fromJson(data);
        }).toList();
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Ошибка подписки на аренды: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _leasesSub?.cancel();
    super.dispose();
  }

  Future<void> loadLeases({String? userId, String? ownerId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      Query query = _firestore.collection('leases');
      if (userId != null) query = query.where('userId', isEqualTo: userId);
      if (ownerId != null) query = query.where('ownerId', isEqualTo: ownerId);
      final snapshot = await query.get();
      final freshLeases = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return ActiveLease.fromJson(data);
      }).toList();
      _leases = freshLeases;
    } catch (e) {
      debugPrint('Ошибка загрузки аренд: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> syncWithFirestore() async {
    try {
      final snapshot = await _firestore.collection('leases').get();
      final serverIds = snapshot.docs.map((d) => d.id).toSet();
      _leases.removeWhere((local) => !serverIds.contains(local.productId));
      await loadLeases();
    } catch (e) {
      debugPrint('Ошибка синхронизации аренд: $e');
    }
  }

  List<ActiveLease> getLeasesForUser(String userId) {
    return _leases.where((l) {
      if (l.userId == userId) return true;
      if (l.ownerId == userId) {
        return l.status == LeaseStatus.active || l.status == LeaseStatus.pendingCompletion;
      }
      return false;
    }).toList();
  }

  Future<void> addActiveLease(ActiveLease lease) async {
    await _firestore.collection('leases').add(lease.toJson());
    await loadLeases();
  }

  void addLocalLease(ActiveLease lease) {
    _leases.add(lease);
    notifyListeners();
  }

  void removeLocalLease(String productId) {
    _leases.removeWhere((l) => l.productId == productId);
    notifyListeners();
  }

  List<ActiveLease> getRentedLeasesForUser(String userId) {
    return _leases.where((l) => l.userId == userId).toList();
  }

  Future<void> removePendingLeaseByProductId(String productId) async {
    final querySnapshot = await _firestore
        .collection('leases')
        .where('productId', isEqualTo: productId)
        .where('status', isEqualTo: LeaseStatus.pending.index)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.delete();
      await loadLeases();
    }
  }

  Future<void> activateLease({
    required String productId,
    required String name,
    required int pricePerDay,
    required int totalDays,
    required String userId,
    required String ownerId,
    required String userFirstName,
    required String userLastName,
    String? userAvatarUrl,
    required double requesterRating,
  }) async {
    final batch = _firestore.batch();
    final querySnapshot = await _firestore
        .collection('leases')
        .where('productId', isEqualTo: productId)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: LeaseStatus.pending.index)
        .limit(1)
        .get();
    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }

    final newLease = ActiveLease(
      productId: productId,
      name: name,
      pricePerDay: pricePerDay,
      startDate: DateTime.now(),
      totalDays: totalDays,
      userId: userId,
      ownerId: ownerId,
      userFirstName: userFirstName,
      userLastName: userLastName,
      userAvatarUrl: userAvatarUrl,
      status: LeaseStatus.active,
      isHourly: false,
      requesterRating: requesterRating,
    );
    batch.set(_firestore.collection('leases').doc(), newLease.toJson());
    await batch.commit();
    await loadLeases();
  }

  Future<void> requestCompleteLease(String productId) async {
    final querySnapshot = await _firestore
        .collection('leases')
        .where('productId', isEqualTo: productId)
        .where('status', isEqualTo: LeaseStatus.active.index)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      await doc.reference.update({
        'status': LeaseStatus.pendingCompletion.index,
        'isCompleted': false,
      });
      await loadLeases();
    }
  }

  Future<void> finishLease(String productId) async {
    final querySnapshot = await _firestore
        .collection('leases')
        .where('productId', isEqualTo: productId)
        .where('status', isEqualTo: LeaseStatus.pendingCompletion.index)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.delete();
      await loadLeases();
    }
  }

  Future<void> cancelCompletionRequest(String productId) async {
    final querySnapshot = await _firestore
        .collection('leases')
        .where('productId', isEqualTo: productId)
        .where('status', isEqualTo: LeaseStatus.pendingCompletion.index)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      await querySnapshot.docs.first.reference.update({
        'status': LeaseStatus.active.index,
        'isCompleted': false,
      });
      await loadLeases();
    }
  }

  Future<void> deleteLeasesForUser(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('leases')
        .where('userId', isEqualTo: userId)
        .get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    await loadLeases();
  }
}