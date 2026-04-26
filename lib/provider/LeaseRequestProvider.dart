import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/models/lease_request.dart';
import 'package:untitled/models/activeLease.dart';
import 'package:untitled/provider/activeLeasesProvider.dart';

class LeaseRequestProvider extends ChangeNotifier {
  final List<LeaseRequest> _requests = [];
  static const String _requestsKey = 'lease_requests';

  List<LeaseRequest> get requests => _requests;

  LeaseRequestProvider() {
    loadFromPrefs();
  }

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
    saveToPrefs();
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
      userId: request.requesterId,
      userFirstName: request.requesterFirstName,
      userLastName: request.requesterLastName,
      userAvatarPath: request.requesterAvatarPath,
      status: LeaseStatus.active,
    ));

    notifyListeners();
    saveToPrefs();
  }

  void rejectRequest(int requestId) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index].status = RequestStatus.rejected;
      notifyListeners();
      saveToPrefs();
    }
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _requests.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_requestsKey, jsonList);
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_requestsKey);
    if (jsonList != null) {
      _requests.clear();
      for (final jsonStr in jsonList) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          _requests.add(LeaseRequest.fromJson(map));
        } catch (e) {
          print('Ошибка загрузки запроса: $e');
        }
      }
      notifyListeners();
    }
  }
}