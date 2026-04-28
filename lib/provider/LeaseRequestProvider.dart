import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lease_request.dart';
import '../provider/activeLeasesProvider.dart';
import '../data/product_data.dart';
import '../models/activeLease.dart';
import '../models/cart_item.dart';
import 'basket_provider.dart';

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

    final hasActiveLease = leasesProvider.leases.any(
          (l) => l.productId == request.productId && l.status == LeaseStatus.active,
    );
    if (hasActiveLease) {
      _requests[index].status = RequestStatus.rejected;
      notifyListeners();
      saveToPrefs();
      return;
    }

    leasesProvider.activateLease(
      request.productId,
      request.productName,
      request.pricePerDay,
      request.totalDays,
      request.requesterId,
      request.ownerId,
      request.requesterFirstName,
      request.requesterLastName,
      userAvatarPath: request.requesterAvatarPath,
    );

    for (final r in _requests) {
      if (r.productId == request.productId && r.status == RequestStatus.pending && r.id != requestId) {
        r.status = RequestStatus.rejected;
      }
    }

    request.status = RequestStatus.accepted;

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

  void acceptCompletion(int requestId, ActiveLeasesProvider leasesProvider, BasketProvider basketProvider) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;

    final request = _requests[index];
    request.status = RequestStatus.accepted;

    final leaseIndex = leasesProvider.leases.indexWhere((l) =>
    l.productId == request.productId && l.status == LeaseStatus.pendingCompletion);
    if (leaseIndex == -1) {
      print('Аренда не найдена');
      notifyListeners();
      saveToPrefs();
      return;
    }

    final lease = leasesProvider.leases[leaseIndex];
    if (lease.startDate == null) {
      print('Аренда не имеет startDate');
      notifyListeners();
      saveToPrefs();
      return;
    }

    final product = ProductData.getProductById(request.productId);
    final bool isHourly = product?.isPricePerHour ?? false;

    final diff = DateTime.now().difference(lease.startDate!);
    final int totalHours = diff.inHours < 1 ? 1 : diff.inHours; // минимум 1 час

    if (isHourly) {
      basketProvider.addToCartForUser(request.requesterId, CartItem(
        id: request.productId,
        name: request.productName,
        price: request.pricePerDay,
        images: request.images,
        ownerId: request.requesterId,
        days: totalHours,
        isHourly: true,
      ));
    } else {
      final int fullDays = totalHours ~/ 24;
      final int remainingHours = totalHours % 24;
      final int days = fullDays;
      final int extraHours = (fullDays >= 1) ? remainingHours : totalHours;

      basketProvider.addToCartForUser(request.requesterId, CartItem(
        id: request.productId,
        name: request.productName,
        price: request.pricePerDay,
        images: request.images,
        ownerId: request.requesterId,
        days: days,
        extraHours: extraHours,
        isHourly: false,
      ));
    }

    leasesProvider.finishLease(request.productId);
    notifyListeners();
    saveToPrefs();
  }

  void rejectCompletion(int requestId, ActiveLeasesProvider leasesProvider) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index].status = RequestStatus.rejected;
      final request = _requests[index];
      leasesProvider.cancelCompletionRequest(request.productId);
      notifyListeners();
      saveToPrefs();
    }
  }

  void deleteRequestsForUser(int userId) {
    _requests.removeWhere((r) => r.requesterId == userId || r.ownerId == userId);
    notifyListeners();
    saveToPrefs();
  }
}