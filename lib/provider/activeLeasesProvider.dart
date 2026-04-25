import 'package:flutter/material.dart';
import '../models/activeLease.dart';

class ActiveLeasesProvider extends ChangeNotifier {
  final List<ActiveLease> _leases = [];
  int _totalLeases = 0;

  List<ActiveLease> get leases => _leases;
  int get activeCount => _leases.where((l) => l.status == LeaseStatus.active).length;
  int get totalLeasesCount => _totalLeases;

  bool addPendingLease(ActiveLease lease) {
    final exists = _leases.any((l) => l.productId == lease.productId);
    if (exists) return false;
    _leases.add(lease);
    notifyListeners();
    return true;
  }

  void addActiveLease(ActiveLease lease) {
    _leases.add(lease);
    _totalLeases++;
    notifyListeners();
  }

  void activateLease(int productId, String name, int pricePerDay, int totalDays) {
    final index = _leases.indexWhere((l) => l.productId == productId && l.status == LeaseStatus.pending);
    if (index != -1) {
      _leases[index] = ActiveLease(
        productId: productId,
        name: name,
        pricePerDay: pricePerDay,
        startDate: DateTime.now(),
        totalDays: totalDays,
        status: LeaseStatus.active,
      );
    } else {
      addActiveLease(ActiveLease(
        productId: productId,
        name: name,
        pricePerDay: pricePerDay,
        startDate: DateTime.now(),
        totalDays: totalDays,
        status: LeaseStatus.active,
      ));
    }
    notifyListeners();
  }

  void removePendingLeaseByProductId(int productId) {
    _leases.removeWhere((lease) => lease.productId == productId && lease.status == LeaseStatus.pending);
    notifyListeners();
  }

  void incrementTotalLeases() {
    _totalLeases++;
    notifyListeners();
  }
}