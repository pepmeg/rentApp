import 'package:flutter/material.dart';
import 'package:untitled/models/lease_request.dart';
import 'package:untitled/models/activeLease.dart';
import 'package:untitled/provider/activeLeasesProvider.dart';

class LeaseRequestProvider extends ChangeNotifier {
  final List<LeaseRequest> _requests = [];

  List<LeaseRequest> get requests => _requests;

  List<LeaseRequest> getIncomingRequests(int userId) {
    return _requests
        .where((r) => r.ownerId == userId && r.status == RequestStatus.pending)
        .toList();
  }

  List<LeaseRequest> getOutgoingRequests(int userId) {
    return _requests.where((r) => r.requesterId == userId).toList();
  }

  void addRequest(LeaseRequest request) {
    _requests.add(request);
    notifyListeners();
  }

  void acceptRequest(int requestId, ActiveLeasesProvider leasesProvider) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    final request = _requests[index];
    request.status = RequestStatus.accepted;

    leasesProvider.addActiveLease(ActiveLease(
      productId: request.productId,
      name: request.productName,
      pricePerDay: request.pricePerDay,
      startDate: DateTime.now(),
      totalDays: request.totalDays,
      status: LeaseStatus.active,
    ));

    notifyListeners();
  }

  void rejectRequest(int requestId) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index].status = RequestStatus.rejected;
      notifyListeners();
    }
  }
}