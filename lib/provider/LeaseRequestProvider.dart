import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/activeLease.dart';
import '../models/product.dart';
import '../services/connectivityService.dart';
import '../services/notification_service.dart';
import '../services/product_service.dart';
import '../models/lease_request.dart';
import 'activeLeasesProvider.dart';
import 'basket_provider.dart';

class LeaseRequestProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<LeaseRequest> _requests = [];
  ConnectivityService? _connectivityService;
  StreamSubscription<QuerySnapshot>? _incomingSub;
  StreamSubscription<QuerySnapshot>? _outgoingSub;

  List<LeaseRequest> get requests => _requests;

  LeaseRequestProvider() {
    loadRequests();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  Future<void> loadRequests() async {
    final snapshot = await _firestore.collection("lease_requests").get();
    _requests = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return LeaseRequest.fromJson(data, docId: doc.id);
    }).toList();
    notifyListeners();
  }

  List<LeaseRequest> getIncomingRequests(String userId) =>
      _requests.where((r) => r.ownerId == userId && r.status == RequestStatus.pending).toList();

  void _sendNotification(String requestDocId, String title, String body, {String payload = 'notifications'}) {
    final int notificationId = (requestDocId.hashCode & 0x7FFFFFFF).abs();
    NotificationService().showLeaseNotification(
      id: notificationId,
      title: title,
      body: body,
      payload: payload,
    );
  }

  void listenForUser(String userId) {
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    void init() {
      _connectivityService = ConnectivityService();
    }
    _incomingSub = _firestore
        .collection("lease_requests")
        .where("ownerId", isEqualTo: userId)
        .where("status", isEqualTo: RequestStatus.pending.index)
        .snapshots()
        .listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        final data = change.doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        if (change.type == DocumentChangeType.added) {
          final newRequest = LeaseRequest.fromJson(data, docId: change.doc.id);
          if (!_requests.any((r) => r.firestoreDocId == newRequest.firestoreDocId)) {
            _requests.add(newRequest);
            notifyListeners();
          }
          if (!newRequest.notificationSent) {
            final requesterFirstName = data['requesterFirstName'] ?? '';
            final requesterLastName = data['requesterLastName'] ?? '';
            final productName = data['productName'] ?? '';
            final requestDocId = change.doc.id;
            final type = data['type'] as int?;
            if (type == RequestType.lease.index) {
              _sendNotification(requestDocId, 'Новый запрос аренды',
                  '$requesterFirstName $requesterLastName хочет арендовать $productName');
            } else if (type == RequestType.completion.index) {
              _sendNotification(requestDocId, 'Запрос на завершение аренды',
                  '$requesterFirstName $requesterLastName хочет завершить аренду «$productName»',
                  payload: 'notifications');
            }
            try {
              await _firestore.collection("lease_requests").doc(change.doc.id).update({'notificationSent': true});
              final idx = _requests.indexWhere((r) => r.firestoreDocId == change.doc.id);
              if (idx != -1) {
                _requests[idx] = LeaseRequest.fromJson(data, docId: change.doc.id);
                notifyListeners();
              }
            } catch (e) {
              debugPrint('Ошибка обновления флага уведомления: $e');
            }
          }
        } else if (change.type == DocumentChangeType.modified) {
          final updatedRequest = LeaseRequest.fromJson(data, docId: change.doc.id);
          final existingIndex = _requests.indexWhere((r) => r.firestoreDocId == change.doc.id);
          final oldType = existingIndex != -1 ? _requests[existingIndex].type : RequestType.lease;

          if (existingIndex != -1) {
            _requests[existingIndex] = updatedRequest;
          } else {
            _requests.add(updatedRequest);
          }
          notifyListeners();
          if (updatedRequest.type == RequestType.completion && oldType != RequestType.completion) {
            final requesterFirstName = data['requesterFirstName'] ?? '';
            final requesterLastName = data['requesterLastName'] ?? '';
            final productName = data['productName'] ?? '';
            _sendNotification(change.doc.id, 'Запрос на завершение аренды',
                '$requesterFirstName $requesterLastName хочет завершить аренду «$productName»',
                payload: 'notifications');
            try {
              await _firestore.collection("lease_requests").doc(change.doc.id).update({'notificationSent': true});
              final idx = _requests.indexWhere((r) => r.firestoreDocId == change.doc.id);
              if (idx != -1) {
                _requests[idx] = LeaseRequest.fromJson(data, docId: change.doc.id);
                notifyListeners();
              }
            } catch (e) {
              debugPrint('Ошибка обновления флага уведомления: $e');
            }
          }
        } else if (change.type == DocumentChangeType.removed) {
          _requests.removeWhere((r) => r.firestoreDocId == change.doc.id);
          notifyListeners();
        }
      }
    });
    _outgoingSub = _firestore
        .collection("lease_requests")
        .where("requesterId", isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        final data = change.doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        final productName = data['productName'] ?? '';
        if (change.type == DocumentChangeType.modified) {
          final status = data['status'] as int?;
          final newType = data['type'] as int?;
          final requestDocId = change.doc.id;
          final index = _requests.indexWhere((r) => r.firestoreDocId == requestDocId);
          if (index != -1) {
            final oldType = _requests[index].type;
            _requests[index].status = RequestStatus.values[status ?? 0];
            if (newType != null) {
              _requests[index].type = RequestType.values[newType];
            }
            notifyListeners();
            final isCompletionCancellation = (oldType == RequestType.completion && _requests[index].type == RequestType.lease);
            if (status == RequestStatus.accepted.index && !isCompletionCancellation) {
              _sendNotification(requestDocId, 'Запрос аренды одобрен',
                  'Владелец одобрил ваш запрос на «$productName»', payload: 'active_leases');
            } else if (status == RequestStatus.rejected.index) {
              _sendNotification(requestDocId, 'Запрос аренды отклонён',
                  'Владелец отклонил ваш запрос на «$productName»', payload: 'active_leases');
            }
          }
        } else if (change.type == DocumentChangeType.removed) {
          _requests.removeWhere((r) => r.firestoreDocId == change.doc.id);
          notifyListeners();
        }
      }
    });
  }

  Future<void> addRequest(LeaseRequest request, {required ActiveLeasesProvider leasesProvider}) async {
    if (_requests.any((r) =>
    r.requesterId == request.requesterId &&
        r.productId == request.productId &&
        r.status == RequestStatus.pending)) {
      debugPrint("Уже есть ожидающий запрос на этот товар");
      return;
    }
    final tempRequest = LeaseRequest(
      firestoreDocId: '',
      productId: request.productId,
      productName: request.productName,
      pricePerDay: request.pricePerDay,
      totalDays: request.totalDays,
      requesterId: request.requesterId,
      requesterFirstName: request.requesterFirstName,
      requesterLastName: request.requesterLastName,
      requesterAvatarPath: request.requesterAvatarPath,
      ownerId: request.ownerId,
      images: request.images,
      status: request.status,
      type: request.type,
      isHourly: request.isHourly,
      requesterRating: request.requesterRating,
    );
    _requests.add(tempRequest);
    notifyListeners();
    if (request.type == RequestType.lease) {
      final pendingLease = ActiveLease(
        productId: request.productId,
        name: request.productName,
        pricePerDay: request.pricePerDay,
        startDate: null,
        totalDays: request.totalDays,
        userId: request.requesterId,
        ownerId: request.ownerId,
        userFirstName: request.requesterFirstName,
        userLastName: request.requesterLastName,
        userAvatarUrl: request.requesterAvatarPath,
        status: LeaseStatus.pending,
        isCompleted: false,
        requestId: null,
        isHourly: request.isHourly,
        requesterRating: request.requesterRating,
      );
      leasesProvider.addLocalLease(pendingLease);
    }
    try {
      final docRef = await _firestore
          .collection("lease_requests")
          .add(request.toJson())
          .timeout(const Duration(seconds: 15));
      final finalRequest = LeaseRequest.fromJson(request.toJson(), docId: docRef.id);
      final index = _requests.indexWhere((r) =>
      r.productId == request.productId &&
          r.requesterId == request.requesterId &&
          r.firestoreDocId.isEmpty);
      if (index != -1) {
        _requests[index] = finalRequest;
        final leaseIndex = leasesProvider.leases.indexWhere((l) =>
        l.productId == request.productId &&
            l.userId == request.requesterId &&
            l.status == LeaseStatus.pending);
        if (leaseIndex != -1) {
          final updatedLease = ActiveLease(
            productId: leasesProvider.leases[leaseIndex].productId,
            name: leasesProvider.leases[leaseIndex].name,
            pricePerDay: leasesProvider.leases[leaseIndex].pricePerDay,
            startDate: leasesProvider.leases[leaseIndex].startDate,
            totalDays: leasesProvider.leases[leaseIndex].totalDays,
            userId: leasesProvider.leases[leaseIndex].userId,
            ownerId: leasesProvider.leases[leaseIndex].ownerId,
            userFirstName: leasesProvider.leases[leaseIndex].userFirstName,
            userLastName: leasesProvider.leases[leaseIndex].userLastName,
            userAvatarUrl: leasesProvider.leases[leaseIndex].userAvatarUrl,
            status: leasesProvider.leases[leaseIndex].status,
            isCompleted: leasesProvider.leases[leaseIndex].isCompleted,
            requestId: docRef.id,
            isHourly: finalRequest.isHourly,
            requesterRating: finalRequest.requesterRating,
          );
          leasesProvider.removeLocalLease(updatedLease.productId);
          leasesProvider.addLocalLease(updatedLease);
        }
        notifyListeners();
      }
    } catch (e) {
      _requests.removeWhere((r) =>
      r.firestoreDocId.isEmpty &&
          r.productId == request.productId &&
          r.requesterId == request.requesterId);
      if (request.type == RequestType.lease) {
        leasesProvider.removeLocalLease(request.productId);
      }
      notifyListeners();
      debugPrint('Ошибка добавления запроса: $e');
      throw Exception('Не удалось отправить запрос: ${e.toString()}');
    }
  }

  Future<void> acceptRequest(String requestDocId, ActiveLeasesProvider leasesProvider) async {
    final index = _requests.indexWhere((r) => r.firestoreDocId == requestDocId);
    if (index == -1) return;
    final removed = _requests.removeAt(index);
    notifyListeners();
    _requests.removeWhere((r) =>
    r.productId == removed.productId &&
        r.requesterId == removed.requesterId &&
        r.status == RequestStatus.pending);
    notifyListeners();
    leasesProvider.removeLocalLease(removed.productId);
    final nowUtc = DateTime.now().toUtc();
    Product? product;
    try {
      product = await ProductService.getProductById(removed.productId);
      if (product == null) throw Exception("Товар не найден");
      final activeLease = ActiveLease(
        productId: removed.productId,
        name: removed.productName,
        pricePerDay: removed.pricePerDay,
        startDate: nowUtc,
        totalDays: removed.totalDays,
        userId: removed.requesterId,
        ownerId: removed.ownerId,
        userFirstName: removed.requesterFirstName,
        userLastName: removed.requesterLastName,
        userAvatarUrl: removed.requesterAvatarPath,
        status: LeaseStatus.active,
        isCompleted: false,
        requestId: requestDocId,
        isHourly: product.isPricePerHour,
        requesterRating: removed.requesterRating,
      );
      leasesProvider.addLocalLease(activeLease);

      final docRef = _firestore.collection("lease_requests").doc(removed.firestoreDocId);
      final allPendingSnapshot = await _firestore
          .collection("lease_requests")
          .where("productId", isEqualTo: removed.productId)
          .where("status", isEqualTo: RequestStatus.pending.index)
          .get();

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) throw Exception("Запрос не найден");
        final data = doc.data() as Map<String, dynamic>;
        if (data["status"] != RequestStatus.pending.index) return;
        final String ownerId = data["ownerId"] as String;
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null || currentUser.uid != ownerId) throw Exception("Нет прав");
        transaction.update(docRef, {"status": RequestStatus.accepted.index});
        for (final otherDoc in allPendingSnapshot.docs) {
          if (otherDoc.id != docRef.id) {
            transaction.update(otherDoc.reference, {"status": RequestStatus.rejected.index});
          }
        }

        transaction.set(_firestore.collection("leases").doc(), {
          "productId": removed.productId,
          "name": data["productName"],
          "pricePerDay": data["pricePerDay"],
          "startDate": DateTime.now().toUtc().toIso8601String(),
          "totalDays": data["totalDays"],
          "userId": data["requesterId"],
          "ownerId": ownerId,
          "userFirstName": data["requesterFirstName"],
          "userLastName": data["requesterLastName"],
          "userAvatarUrl": data["requesterAvatarUrl"],
          "status": LeaseStatus.active.index,
          "isCompleted": false,
          "createdAt": DateTime.now().toUtc().toIso8601String(),
          "requestId": requestDocId,
        });
      }).timeout(const Duration(seconds: 20));
      await leasesProvider.loadLeases();
      await loadRequests();
    } catch (e) {
      leasesProvider.removeLocalLease(removed.productId);
      leasesProvider.addLocalLease(ActiveLease(
        productId: removed.productId,
        name: removed.productName,
        pricePerDay: removed.pricePerDay,
        startDate: null,
        totalDays: removed.totalDays,
        userId: removed.requesterId,
        ownerId: removed.ownerId,
        userFirstName: removed.requesterFirstName,
        userLastName: removed.requesterLastName,
        userAvatarUrl: removed.requesterAvatarPath,
        status: LeaseStatus.pending,
        isCompleted: false,
        requestId: requestDocId,
        isHourly: product?.isPricePerHour ?? false,
        requesterRating: removed.requesterRating,
      ));
      _requests.insert(index, removed);
      notifyListeners();
      debugPrint("Ошибка принятия запроса: $e");
      throw Exception('Не удалось принять запрос: ${e.toString()}');
    }
  }

  Future<void> rejectRequest(String requestDocId, {required ActiveLeasesProvider leasesProvider}) async {
    final index = _requests.indexWhere((r) => r.firestoreDocId == requestDocId);
    if (index == -1) return;
    final removed = _requests.removeAt(index);
    notifyListeners();

    leasesProvider.removeLocalLease(removed.productId);

    try {
      final docRef = _firestore.collection("lease_requests").doc(removed.firestoreDocId);
      await docRef.update({"status": RequestStatus.rejected.index}).timeout(const Duration(seconds: 15));
      final doc = await docRef.get().timeout(const Duration(seconds: 10));
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data["status"] = RequestStatus.rejected.index;
        await _firestore.collection("lease_requests_archive").add(data).timeout(const Duration(seconds: 15));
        await docRef.delete().timeout(const Duration(seconds: 15));
      }
      await loadRequests();
    } catch (e) {
      leasesProvider.addLocalLease(ActiveLease(
        productId: removed.productId,
        name: removed.productName,
        pricePerDay: removed.pricePerDay,
        startDate: null,
        totalDays: removed.totalDays,
        userId: removed.requesterId,
        ownerId: removed.ownerId,
        userFirstName: removed.requesterFirstName,
        userLastName: removed.requesterLastName,
        userAvatarUrl: removed.requesterAvatarPath,
        status: LeaseStatus.pending,
        isCompleted: false,
        requestId: requestDocId,
        isHourly: removed.isHourly,
        requesterRating: removed.requesterRating,
      ));
      _requests.insert(index, removed);
      notifyListeners();
      debugPrint("Ошибка отклонения запроса: $e");
      throw Exception('Не удалось отклонить запрос: ${e.toString()}');
    }
  }

  Future<void> requestCompleteLease(ActiveLease lease, {required String userId, required double requesterRating, required ActiveLeasesProvider leasesProvider}) async {
    LeaseRequest? existingRequest;
    for (final r in _requests) {
      if (r.productId == lease.productId && r.requesterId == userId && r.type == RequestType.lease && r.status == RequestStatus.accepted) {
        existingRequest = r;
        break;
      }
    }

    if (existingRequest != null) {
      final req = existingRequest;
      final docRef = _firestore.collection("lease_requests").doc(req.firestoreDocId);
      await docRef.update({
        'type': RequestType.completion.index,
        'status': RequestStatus.pending.index,
        'notificationSent': false,
      });
      final updatedRequest = LeaseRequest(
        firestoreDocId: existingRequest.firestoreDocId,
        productId: existingRequest.productId,
        productName: existingRequest.productName,
        pricePerDay: existingRequest.pricePerDay,
        totalDays: existingRequest.totalDays,
        requesterId: existingRequest.requesterId,
        requesterFirstName: existingRequest.requesterFirstName,
        requesterLastName: existingRequest.requesterLastName,
        requesterAvatarPath: existingRequest.requesterAvatarPath,
        ownerId: existingRequest.ownerId,
        images: existingRequest.images,
        status: RequestStatus.pending,
        type: RequestType.completion,
        isHourly: existingRequest.isHourly,
        notificationSent: false,
        requesterRating: existingRequest.requesterRating,
      );
      final index = _requests.indexWhere((r) => r.firestoreDocId == req.firestoreDocId);
      if (index != -1) {
        _requests[index] = updatedRequest;
      }
      notifyListeners();
    } else {
      final request = LeaseRequest(
        firestoreDocId: '',
        productId: lease.productId,
        productName: lease.name,
        pricePerDay: lease.pricePerDay,
        totalDays: lease.totalDays,
        requesterId: userId,
        requesterFirstName: lease.userFirstName,
        requesterLastName: lease.userLastName,
        requesterAvatarPath: lease.userAvatarUrl,
        ownerId: lease.ownerId,
        type: RequestType.completion,
        isHourly: lease.isHourly,
        requesterRating: requesterRating,
      );
      await addRequest(request, leasesProvider: leasesProvider);
    }
  }

  Future<void> acceptCompletion(String requestDocId, ActiveLeasesProvider leasesProvider, BasketProvider basketProvider) async {
    final index = _requests.indexWhere((r) => r.firestoreDocId == requestDocId);
    if (index == -1) return;
    final removed = _requests.removeAt(index);
    notifyListeners();
    leasesProvider.removeLocalLease(removed.productId);
    try {
      final docRef = _firestore.collection("lease_requests").doc(removed.firestoreDocId);

      final product = await ProductService.getProductById(removed.productId).timeout(const Duration(seconds: 15));
      if (product == null) {
        await loadRequests();
        return;
      }

      final ownerDoc = await _firestore.collection('users').doc(product.ownerId).get().timeout(const Duration(seconds: 10));
      final ownerName = ownerDoc.exists
          ? '${ownerDoc.data()?['firstName']} ${ownerDoc.data()?['lastName']}'
          : 'Владелец';
      final ownerAvatarUrl = ownerDoc.data()?['avatarUrl'] as String?;

      final leaseSnapshot = await _firestore
          .collection("leases")
          .where("productId", isEqualTo: removed.productId)
          .where("status", isEqualTo: LeaseStatus.pendingCompletion.index)
          .limit(1)
          .get();
      if (leaseSnapshot.docs.isEmpty) {
        await loadRequests();
        return;
      }
      final leaseDocRef = leaseSnapshot.docs.first.reference;
      final leaseData = leaseSnapshot.docs.first.data();
      final startDate = DateTime.parse(leaseData["startDate"]).toUtc();
      final nowUtc = DateTime.now().toUtc();
      final diff = nowUtc.difference(startDate);
      final isHourly = product.isPricePerHour;
      int totalPrice;
      int days = 0;
      int extraHours = 0;
      int totalHours = 0;
      if (isHourly) {
        totalHours = diff.inHours;
        int minutesPast = diff.inMinutes % 60;
        if (minutesPast >= 20) totalHours++;
        totalPrice = removed.pricePerDay * totalHours;
        days = totalHours;
        extraHours = 0;
      } else {
        days = diff.inDays;
        extraHours = diff.inHours % 24;
        totalPrice = (removed.pricePerDay * days + removed.pricePerDay * extraHours / 24.0).ceil().toInt();
      }
      final archiveData = Map<String, dynamic>.from(removed.toJson());
      archiveData["status"] = "completed";
      archiveData["startDate"] = startDate.toIso8601String();
      archiveData["endDate"] = nowUtc.toIso8601String();
      archiveData["totalPrice"] = totalPrice;
      archiveData["units"] = isHourly ? totalHours : days;
      archiveData["extraHours"] = extraHours;
      archiveData["isHourly"] = isHourly;
      archiveData['ownerName'] = ownerName;
      archiveData['ownerAvatarUrl'] = ownerAvatarUrl;
      archiveData['images'] = removed.images.isNotEmpty ? removed.images : [];
      final leaseRequestSnapshot = await _firestore
          .collection("lease_requests")
          .where("productId", isEqualTo: removed.productId)
          .where("requesterId", isEqualTo: removed.requesterId)
          .where("type", isEqualTo: RequestType.lease.index)
          .where("status", isEqualTo: RequestStatus.accepted.index)
          .limit(1)
          .get();
      String? leaseRequestDocId;
      if (leaseRequestSnapshot.docs.isNotEmpty) {
        leaseRequestDocId = leaseRequestSnapshot.docs.first.id;
      }
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) throw Exception("Запрос не найден");
        final requestData = doc.data() as Map<String, dynamic>;
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null || currentUser.uid != requestData["ownerId"]) throw Exception("Нет прав");
        transaction.set(_firestore.collection("lease_requests_archive").doc(), archiveData);
        transaction.delete(leaseDocRef);
        final cartRef = _firestore
            .collection("users")
            .doc(requestData["requesterId"])
            .collection("cart")
            .doc();
        transaction.set(cartRef, {
          "id": removed.productId,
          "name": requestData["productName"],
          "price": removed.pricePerDay,
          "images": requestData["images"] ?? [],
          "ownerId": requestData["ownerId"],
          "units": isHourly ? totalHours : days,
          "extraHours": extraHours,
          "isHourly": isHourly,
          "totalPrice": totalPrice,
          "completedAt": nowUtc.toIso8601String(),
        });
        transaction.delete(docRef);

        if (leaseRequestDocId != null) {
          final leaseRequestRef = _firestore.collection("lease_requests").doc(leaseRequestDocId);
          transaction.delete(leaseRequestRef);
        }
      }).timeout(const Duration(seconds: 30));
      if (leaseRequestDocId != null) {
        _requests.removeWhere((r) => r.firestoreDocId == leaseRequestDocId);
        notifyListeners();
      }

      await leasesProvider.loadLeases();
      await loadRequests();

      final scheduledTime = DateTime.now().add(const Duration(minutes: 10));
      NotificationService().scheduleReviewReminder(
        productId: removed.productId,
        productName: removed.productName,
        scheduledTime: scheduledTime,
      );
    } catch (e) {
      leasesProvider.addLocalLease(ActiveLease(
        productId: removed.productId,
        name: removed.productName,
        pricePerDay: removed.pricePerDay,
        startDate: DateTime.now().toUtc(),
        totalDays: removed.totalDays,
        userId: removed.requesterId,
        ownerId: removed.ownerId,
        userFirstName: removed.requesterFirstName,
        userLastName: removed.requesterLastName,
        userAvatarUrl: removed.requesterAvatarPath,
        status: LeaseStatus.active,
        isCompleted: false,
        requestId: requestDocId,
        isHourly: false,
        requesterRating: removed.requesterRating,
      ));
      _requests.insert(index, removed);
      notifyListeners();
      debugPrint("Ошибка завершения аренды: $e");
      throw Exception('Не удалось завершить аренду: ${e.toString()}');
    }
  }

  Future<void> rejectCompletion(String requestDocId, ActiveLeasesProvider leasesProvider, {bool notifyRenter = true}) async {
    final index = _requests.indexWhere((r) => r.firestoreDocId == requestDocId);
    if (index == -1) return;
    final removed = _requests.removeAt(index);
    notifyListeners();
    leasesProvider.removeLocalLease(removed.productId);
    leasesProvider.addLocalLease(ActiveLease(
      productId: removed.productId,
      name: removed.productName,
      pricePerDay: removed.pricePerDay,
      startDate: DateTime.now().toUtc(),
      totalDays: removed.totalDays,
      userId: removed.requesterId,
      ownerId: removed.ownerId,
      userFirstName: removed.requesterFirstName,
      userLastName: removed.requesterLastName,
      userAvatarUrl: removed.requesterAvatarPath,
      status: LeaseStatus.active,
      isCompleted: false,
      requestId: requestDocId,
      isHourly: false,
      requesterRating: removed.requesterRating,
    ));
    try {
      final docRef = _firestore.collection("lease_requests").doc(removed.firestoreDocId);
      await leasesProvider.cancelCompletionRequest(removed.productId);
      await docRef.delete().timeout(const Duration(seconds: 15));
      if (notifyRenter) {
        _sendNotification(requestDocId, 'Завершение аренды отклонено',
            'Владелец отклонил завершение аренды «${removed.productName}».',
            payload: 'active_leases');
      }
      await loadRequests();
    } catch (e) {
      leasesProvider.removeLocalLease(removed.productId);
      _requests.insert(index, removed);
      notifyListeners();
      debugPrint("Ошибка отмены завершения: $e");
      throw Exception('Не удалось отклонить завершение аренды: ${e.toString()}');
    }
  }

  bool hasPendingOrAcceptedRequest(String userId, String productId) =>
      _requests.any((r) => r.requesterId == userId && r.productId == productId &&
          (r.status == RequestStatus.pending || r.status == RequestStatus.accepted));

  Future<void> deleteRequestsForUser(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore.collection("lease_requests")
        .where("requesterId", isEqualTo: userId)
        .get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    await loadRequests();
  }

  void stopListening() {
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    _incomingSub = null;
    _outgoingSub = null;
  }
}