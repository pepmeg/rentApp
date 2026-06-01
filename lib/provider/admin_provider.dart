import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import '../models/activeLease.dart';
import '../models/lease_request.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../models/admin_models/report.dart';
import '../models/admin_models/moderation_log.dart';
import '../models/user.dart';

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Report> _reports = [];
  List<ModerationLog> _logs = [];
  List<UserModel> _users = [];
  final Map<String, List<Product>> _userProductsCache = {};
  int _totalProducts = 0;
  int _hiddenProducts = 0;
  int _blockedProducts = 0;

  List<Report> get reports => _reports;
  List<ModerationLog> get moderationLogs => _logs;
  List<UserModel> get users => _users;
  int get totalProducts => _totalProducts;
  int get totalReports => _reports.length;
  int get hiddenProducts => _hiddenProducts;
  int get blockedProducts => _blockedProducts;
  int get activeUsers => _users.where((u) => !u.blocked).length;
  int get blockedUsersCount => _users.where((u) => u.blocked).length;
  int get reportsOnProductsCount =>
      _reports.where((r) => r.targetType == ReportTargetType.product).length;
  int get reportsOnUsersCount =>
      _reports.where((r) => r.targetType == ReportTargetType.user).length;
  StreamSubscription<QuerySnapshot>? _reportsSubscription;

  AdminProvider() {
    listenToReports();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        loadAll();
      }
    });
  }

  void stopListening() {
    _reportsSubscription?.cancel();
    _reportsSubscription = null;
  }

  Future<void> loadAll() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await Future.wait([
      loadReports(),
      if (await _isAdminOrSupport()) loadLogs(),
      loadUsers(),
      loadProductCounts(),
    ]);
  }

  Future<bool> _isAdminOrSupport() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    final doc = await _firestore.collection('users').doc(currentUser.uid).get();
    final role = doc.data()?['role'] as String?;
    return role == 'admin' || role == 'support';
  }

  void startListening() {
    if (_reportsSubscription == null) {
      listenToReports();
    }
  }

  Future<List<Product>> getAllProducts() async => await ProductService.getAllProducts();

  Future<void> loadReports() async {
    final source = const GetOptions(source: Source.server);
    final snapshot = await _firestore.collection('reports').get(source);
    _reports = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = int.tryParse(doc.id) ?? DateTime.now().millisecondsSinceEpoch;
      return Report.fromJson(data, docId: doc.id);
    }).toList();
    notifyListeners();
  }

  Future<void> loadLogs() async {
    try {
      final snapshot = await _firestore.collection('moderation_logs').get();
      _logs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = int.tryParse(doc.id) ?? DateTime.now().millisecondsSinceEpoch;
        return ModerationLog.fromJson(data);
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка загрузки логов: $e');
      _logs = [];
    }
  }

  Future<void> loadUsers() async {
    final snapshot = await _firestore.collection('users').get();
    _users = snapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
    notifyListeners();
  }

  void listenToReports() {
    _reportsSubscription?.cancel();
    _reportsSubscription = _firestore
        .collection('reports')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        final doc = change.doc;
        final data = doc.data();
        if (data == null) continue;
        data['id'] = int.tryParse(doc.id) ?? DateTime.now().millisecondsSinceEpoch;
        final report = Report.fromJson(data, docId: doc.id);

        switch (change.type) {
          case DocumentChangeType.added:
            if (!_reports.any((r) => r.firestoreDocId == report.firestoreDocId)) {
              _reports.add(report);
            }
            break;
          case DocumentChangeType.modified:
            final index = _reports.indexWhere((r) => r.firestoreDocId == report.firestoreDocId);
            if (index != -1) {
              _reports[index] = report;
            } else {
              _reports.add(report);
            }
            break;
          case DocumentChangeType.removed:
            _reports.removeWhere((r) => r.firestoreDocId == report.firestoreDocId);
            break;
        }
      }
      notifyListeners();
    });
  }

  void cancelReportsSubscription() {
    _reportsSubscription?.cancel();
    _reportsSubscription = null;
  }

  Future<void> loadProductCounts() async {
    try {
      final all = await ProductService.getAllProducts(includeAll: true);
      _totalProducts = all.length;
      _hiddenProducts = all.where((p) => p.moderationStatus == 'hidden').length;
      _blockedProducts = all.where((p) => p.moderationStatus == 'blocked').length;
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка загрузки количества товаров: $e');
    }
  }

  void addReport({
    required String reporterId,
    String? productId,
    String? targetUserId,
    required String reason,
    required ReportTargetType targetType,
  }) async {
    final report = Report(
      firestoreDocId: '',
      id: DateTime.now().millisecondsSinceEpoch,
      reporterId: reporterId,
      productId: productId,
      targetUserId: targetUserId,
      reason: reason,
      createdAt: DateTime.now(),
      targetType: targetType,
    );
    await _firestore.collection('reports').add(report.toJson());
    await _checkAutoHide(productId);
  }

  List<Report> getReportsForProduct(String productId) =>
      _reports.where((r) => r.productId == productId && r.targetType == ReportTargetType.product).toList();

  List<Report> getReportsRelatedToUser(String userId) {
    final userProductIds = _getUserProductIds(userId);
    return _reports.where((r) {
      if (r.targetType == ReportTargetType.user && r.targetUserId == userId) return true;
      if (r.targetType == ReportTargetType.product &&
          r.productId != null &&
          userProductIds.contains(r.productId)) return true;
      return false;
    }).toList();
  }

  Set<String> _getUserProductIds(String userId) {
    return _userProductsCache[userId]?.map((p) => p.id).toSet() ?? {};
  }

  Future<void> loadUserProducts(String userId) async {
    try {
      final products = await ProductService.getAllProducts(ownerId: userId);
      _userProductsCache[userId] = products;
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка загрузки товаров пользователя: $e');
    }
  }

  Future<void> _checkAutoHide(String? productId) async {
    if (productId == null) return;
    final snapshot = await _firestore
        .collection('reports')
        .where('productId', isEqualTo: productId)
        .where('targetType', isEqualTo: ReportTargetType.product.index)
        .get();
    if (snapshot.size >= 3) {
      await ProductService.updateProductStatus(productId, 'hidden');
      await _addModerationLog('0', productId: productId, action: 'auto_hide', reason: 'Автоматическое скрытие после 3 жалоб');
    }
  }

  Future<void> hideProduct(String productId, String adminId, String reason) async {
    await ProductService.updateProductStatus(productId, 'hidden');
    await _addModerationLog(adminId, productId: productId, action: 'hide_product', reason: reason);
    await loadProductCounts();
    notifyListeners();
  }

  Future<void> unhideProduct(String productId, String adminId, String reason) async {
    await ProductService.updateProductStatus(productId, 'active');
    await _addModerationLog(adminId, productId: productId, action: 'unhide_product', reason: reason);
    await loadProductCounts();
    notifyListeners();
  }

  Future<void> blockProduct(String productId, String adminId, String reason) async {
    final productRef = _firestore.collection('products').doc(productId);
    final productDoc = await productRef.get();
    if (!productDoc.exists) return;
    final productData = productDoc.data()!;
    final ownerId = productData['ownerId'] as String;
    final productName = productData['name'] as String;

    final leaseRequestsSnapshot = await _firestore
        .collection('lease_requests')
        .where('productId', isEqualTo: productId)
        .get();
    final leasesSnapshot = await _firestore
        .collection('leases')
        .where('productId', isEqualTo: productId)
        .get();
    final usersSnapshot = await _firestore.collection('users').get();
    final batch = _firestore.batch();
    batch.update(productRef, {'moderationStatus': 'blocked'});
    for (final doc in leaseRequestsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in leasesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    for (final userDoc in usersSnapshot.docs) {
      final cartDocRef = userDoc.reference.collection('cart').doc(productId);
      final cartDoc = await cartDocRef.get();
      if (cartDoc.exists) {
        batch.delete(cartDocRef);
      }
    }
    await batch.commit();
    await _addModerationLog(adminId, productId: productId, action: 'block_product', reason: reason);
    await loadProductCounts();
    notifyListeners();
  }

  Future<void> blockUser(String uid, {bool block = true}) async {
    final userRef = _firestore.collection('users').doc(uid);
    final userDoc = await userRef.get();
    if (!userDoc.exists) return;

    final products = await ProductService.getAllProducts(ownerId: uid, includeAll: true);
    final leasesAsRenter = await _firestore
        .collection('leases')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: LeaseStatus.active.index)
        .get();
    final leasesAsOwner = await _firestore
        .collection('leases')
        .where('ownerId', isEqualTo: uid)
        .where('status', isEqualTo: LeaseStatus.active.index)
        .get();
    final pendingRequests = await _firestore
        .collection('lease_requests')
        .where(Filter.or(
      Filter('requesterId', isEqualTo: uid),
      Filter('ownerId', isEqualTo: uid),
    ))
        .where('status', isEqualTo: RequestStatus.pending.index)
        .get();
    final cartSnapshot = await _firestore.collection('users').doc(uid).collection('cart').get();

    final batch = _firestore.batch();

    if (block) {
      batch.update(userRef, {'blocked': true});
      for (final product in products) {
        final productRef = _firestore.collection('products').doc(product.id);
        batch.update(productRef, {'moderationStatus': 'blocked'});
      }
    } else {
      batch.update(userRef, {'blocked': false});
      for (final product in products) {
        final productRef = _firestore.collection('products').doc(product.id);
        batch.update(productRef, {'moderationStatus': 'active'});
      }
    }

    for (final doc in leasesAsRenter.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in leasesAsOwner.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in pendingRequests.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in cartSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    final action = block ? 'block_user' : 'unblock_user';
    final reason = block ? 'Заблокирован администратором' : 'Разблокирован';
    await _addModerationLog(_firestore.collection('users').doc().id, targetUserId: uid, action: action, reason: reason);
    await loadUsers();
    notifyListeners();
  }

  Future<void> unblockUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({'blocked': false});
    await _addModerationLog('0', targetUserId: uid, action: 'unblock_user', reason: 'Разблокирован');
    await loadUsers();
  }

  Future<void> _addModerationLog(String adminId, {
    String? productId,
    String? targetUserId,
    required String action,
    String? reason,
  }) async {
    final log = ModerationLog(
      id: DateTime.now().millisecondsSinceEpoch,
      adminId: adminId,
      productId: productId,
      targetUserId: targetUserId,
      action: action,
      reason: reason,
      timestamp: DateTime.now(),
    );
    await _firestore.collection('moderation_logs').add(log.toJson());
    await loadLogs();
  }

  Future<void> markReportAsRead(String firestoreDocId, String userId) async {
    print('markReportAsRead: $firestoreDocId, $userId');
    final index = _reports.indexWhere((r) => r.firestoreDocId == firestoreDocId);
    if (index == -1) {
      print('Report not found in _reports');
      return;
    }
    final report = _reports[index];
    if (!report.readByUserIds.contains(userId)) {
      final updatedSet = {...report.readByUserIds, userId};
      _reports[index] = Report(
        firestoreDocId: report.firestoreDocId,
        id: report.id,
        productId: report.productId,
        targetUserId: report.targetUserId,
        reporterId: report.reporterId,
        reason: report.reason,
        status: report.status,
        createdAt: report.createdAt,
        targetType: report.targetType,
        readByUserIds: updatedSet,
      );
      notifyListeners();

      await _firestore.collection('reports').doc(firestoreDocId).update({
        'readByUserIds': updatedSet.toList(),
      });
      await loadReports();
    }
  }
}