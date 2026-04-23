import 'package:flutter/material.dart';
import '../models/activeLease.dart';

class ActiveLeasesProvider extends ChangeNotifier {
  final List<ActiveLease> _leases = [];

  List<ActiveLease> get leases => _leases;

  int get activeCount => _leases.length;

  bool addPendingLease(ActiveLease lease) {
    final exists = _leases.any((l) => l.productId == lease.productId);
    if (exists) return false;

    _leases.add(lease);
    notifyListeners();
    return true;
  }

  void activateLease(int productId, String name, int pricePerDay, int totalDays) {
    final index = _leases.indexWhere((l) => l.productId == productId && l.status == LeaseStatus.pending);
    if (index != -1) {
      final updated = ActiveLease(
        productId: productId,
        name: name,
        pricePerDay: pricePerDay,
        startDate: DateTime.now(),
        totalDays: totalDays,
        status: LeaseStatus.active,
      );
      _leases[index] = updated;
    } else {
      _leases.add(ActiveLease(
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

  void removeLease(ActiveLease lease) {
    _leases.remove(lease);
    notifyListeners();
  }
}