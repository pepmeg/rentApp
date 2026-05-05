import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin_models/report.dart';
import '../models/admin_models/moderation_log.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../data/product_data.dart';
import 'AuthProvider.dart';

class AdminProvider extends ChangeNotifier {
  List<Report> _reports = [];
  List<ModerationLog> _moderationLogs = [];
  static const String _reportsKey = 'reports';
  static const String _moderationLogsKey = 'moderation_logs';

  List<UserModel> _allUsers = [];

  AdminProvider() {
    loadFromPrefs();
  }

  List<UserModel> get users => List.unmodifiable(_allUsers);

  Future<void> loadUsers() async {
    final auth = AuthProvider();
    _allUsers = await auth.getAllUsers();
    notifyListeners();
  }

  void blockUser(int userId) {
    final index = _allUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final old = _allUsers[index];
      final updated = UserModel(
        id: old.id,
        email: old.email,
        password: old.password,
        firstName: old.firstName,
        lastName: old.lastName,
        address: old.address,
        phoneNumber: old.phoneNumber,
        avatarPath: old.avatarPath,
        role: old.role,
        blocked: true,
      );
      _allUsers[index] = updated;
      _addModerationLog(0, targetUserId: userId, action: 'block_user', reason: 'Заблокирован администратором');
      _saveUser(updated);
      notifyListeners();
    }
  }

  void unblockUser(int userId) {
    final index = _allUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final old = _allUsers[index];
      final updated = UserModel(
        id: old.id,
        email: old.email,
        password: old.password,
        firstName: old.firstName,
        lastName: old.lastName,
        address: old.address,
        phoneNumber: old.phoneNumber,
        avatarPath: old.avatarPath,
        role: old.role,
        blocked: false,
      );
      _allUsers[index] = updated;
      _addModerationLog(0, targetUserId: userId, action: 'unblock_user', reason: 'Разблокирован');
      _saveUser(updated);
      notifyListeners();
    }
  }

  Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'user_${user.email}';
    await prefs.setString(key, jsonEncode(user.toJson()));
  }

  List<Report> get reports => List.unmodifiable(_reports);

  void addReport({
    required int reporterId,
    int? productId,
    int? targetUserId,
    required String reason,
    required ReportTargetType targetType,
  }) {
    final report = Report(
      id: DateTime.now().millisecondsSinceEpoch,
      productId: productId,
      targetUserId: targetUserId,
      reporterId: reporterId,
      reason: reason,
      createdAt: DateTime.now(),
      targetType: targetType,
    );
    _reports.add(report);
    _checkAutoHide(productId);
    notifyListeners();
    _saveReports();
  }

  List<Report> getReportsForProduct(int productId) {
    return _reports
        .where((r) => r.productId == productId && r.targetType == ReportTargetType.product)
        .toList();
  }

  List<Report> getReportsRelatedToUser(int userId) {
    final userProductIds = ProductData.products
        .where((p) => p.ownerId == userId)
        .map((p) => p.id)
        .toSet();
    return _reports.where((r) {
      if (r.targetType == ReportTargetType.user && r.targetUserId == userId) return true;
      if (r.targetType == ReportTargetType.product &&
          r.productId != null &&
          userProductIds.contains(r.productId)) return true;
      return false;
    }).toList();
  }

  void _checkAutoHide(int? productId) {
    if (productId == null) return;
    final count = _reports
        .where((r) => r.productId == productId && r.targetType == ReportTargetType.product)
        .length;
    if (count >= 3) {
      ProductData.updateProductStatus(productId, 'hidden');
      _addModerationLog(0,
          productId: productId,
          action: 'auto_hide',
          reason: 'Автоматическое скрытие после 3 жалоб');
    }
  }

  List<Product> getAllProducts() => ProductData.products;

  void hideProduct(int productId, int adminId, String reason) {
    ProductData.updateProductStatus(productId, 'hidden');
    _addModerationLog(adminId, productId: productId, action: 'hide_product', reason: reason);
    notifyListeners();
  }

  void unhideProduct(int productId, int adminId, String reason) {
    ProductData.updateProductStatus(productId, 'active');
    _addModerationLog(adminId, productId: productId, action: 'unhide_product', reason: reason);
    notifyListeners();
  }

  void blockProduct(int productId, int adminId, String reason) {
    ProductData.updateProductStatus(productId, 'blocked');
    _addModerationLog(adminId, productId: productId, action: 'block_product', reason: reason);
    notifyListeners();
  }

  List<ModerationLog> get moderationLogs => List.unmodifiable(_moderationLogs);

  void _addModerationLog(int adminId, {
    int? productId,
    int? targetUserId,
    required String action,
    String? reason,
  }) {
    final log = ModerationLog(
      id: DateTime.now().millisecondsSinceEpoch,
      adminId: adminId,
      productId: productId,
      targetUserId: targetUserId,
      action: action,
      reason: reason,
      timestamp: DateTime.now(),
    );
    _moderationLogs.add(log);
    notifyListeners();
    _saveModerationLogs();
  }

  int get activeUsers => _allUsers.where((u) => !u.blocked).length;
  int get totalProducts => ProductData.products.length;
  int get totalReports => _reports.length;
  int get hiddenProducts =>
      ProductData.products.where((p) => p.moderationStatus == 'hidden').length;
  int get blockedProducts =>
      ProductData.products.where((p) => p.moderationStatus == 'blocked').length;

  Future<void> _saveReports() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _reports.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_reportsKey, jsonList);
  }

  Future<void> _saveModerationLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _moderationLogs.map((l) => jsonEncode(l.toJson())).toList();
    await prefs.setStringList(_moderationLogsKey, jsonList);
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final reportsData = prefs.getStringList(_reportsKey);
    if (reportsData != null) {
      _reports = reportsData.map((s) => Report.fromJson(jsonDecode(s))).toList();
    }
    final logsData = prefs.getStringList(_moderationLogsKey);
    if (logsData != null) {
      _moderationLogs = logsData.map((s) => ModerationLog.fromJson(jsonDecode(s))).toList();
    }
    notifyListeners();
  }
}