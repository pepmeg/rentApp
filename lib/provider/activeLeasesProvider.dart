import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activeLease.dart';

class ActiveLeasesProvider extends ChangeNotifier {
  final List<ActiveLease> _leases = [];
  int _totalLeases = 0;
  static const String _leasesKey = 'active_leases';

  List<ActiveLease> get leases => _leases;
  int get activeCount => _leases.where((l) => l.status == LeaseStatus.active).length;
  int get totalLeasesCount => _totalLeases;

  ActiveLeasesProvider() {
    loadFromPrefs();
  }

  List<ActiveLease> getLeasesForUser(int userId) {
    return _leases.where((lease) => lease.userId == userId).toList();
  }

  bool addPendingLease(ActiveLease lease) {
    final exists = _leases.any((l) => l.productId == lease.productId);
    if (exists) return false;
    _leases.add(lease);
    notifyListeners();
    saveToPrefs();
    return true;
  }

  void addActiveLease(ActiveLease lease) {
    _leases.add(lease);
    _totalLeases++;
    notifyListeners();
    saveToPrefs();
  }

  void activateLease(
      int productId,
      String name,
      int pricePerDay,
      int totalDays,
      int userId,
      String userFirstName,
      String userLastName, {
        String? userAvatarPath,
      }) {
    final index = _leases.indexWhere((l) => l.productId == productId && l.status == LeaseStatus.pending);
    if (index != -1) {
      _leases[index] = ActiveLease(
        productId: productId,
        name: name,
        pricePerDay: pricePerDay,
        startDate: DateTime.now(),
        totalDays: totalDays,
        userId: userId,
        userFirstName: userFirstName,
        userLastName: userLastName,
        userAvatarPath: userAvatarPath,
        status: LeaseStatus.active,
      );
    } else {
      addActiveLease(ActiveLease(
        productId: productId,
        name: name,
        pricePerDay: pricePerDay,
        startDate: DateTime.now(),
        totalDays: totalDays,
        userId: userId,
        userFirstName: userFirstName,
        userLastName: userLastName,
        userAvatarPath: userAvatarPath,
        status: LeaseStatus.active,
      ));
    }
    notifyListeners();
    saveToPrefs();
  }

  void removePendingLeaseByProductId(int productId) {
    _leases.removeWhere((lease) => lease.productId == productId && lease.status == LeaseStatus.pending);
    notifyListeners();
    saveToPrefs();
  }

  void incrementTotalLeases() {
    _totalLeases++;
    notifyListeners();
    saveToPrefs();
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _leases.map((lease) => jsonEncode(lease.toJson())).toList();
    await prefs.setStringList(_leasesKey, jsonList);
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_leasesKey);
    if (jsonList != null) {
      _leases.clear();
      for (final jsonStr in jsonList) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          _leases.add(ActiveLease.fromJson(map));
        } catch (e) {
          print('Ошибка загрузки аренды: $e');
        }
      }
      _totalLeases = _leases.length;
      notifyListeners();
    }
  }
}