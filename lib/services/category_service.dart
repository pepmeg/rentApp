import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/category_node.dart';

class CategoryService extends ChangeNotifier {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<CategoryNode> _categories = [];
  late StreamSubscription<QuerySnapshot> _subscription;

  Map<String, CategoryNode> get categoriesMap =>
      {for (var c in _categories) c.id: c};

  List<CategoryNode> get rootCategories =>
      _categories.where((c) => c.isRoot).toList();

  CategoryNode? getCategoryById(String id) => categoriesMap[id];

  List<CategoryNode> getChildren(String parentId) =>
      _categories.where((c) => c.parentId == parentId).toList();

  String buildPathDisplay(List<String> ids) {
    if (ids.isEmpty) return 'Без категории';
    final names = ids.map((id) => categoriesMap[id]?.name ?? '?').toList();
    return names.join(' / ');
  }

  void startListening() {
    _subscription = _firestore
        .collection('categories')
        .orderBy('order')
        .snapshots()
        .listen((snapshot) {
      _categories = snapshot.docs
          .map((doc) => CategoryNode.fromJson(doc.id, doc.data()))
          .toList();
      notifyListeners();
    });
  }

  void dispose() {
    _subscription.cancel();
  }

  List<Map<String, dynamic>> getCategoryTree() {
    final Map<String, List<CategoryNode>> childrenMap = {};
    for (var cat in _categories) {
      if (cat.parentId != null) {
        childrenMap.putIfAbsent(cat.parentId!, () => []).add(cat);
      }
    }
    List<Map<String, dynamic>> buildTree(List<CategoryNode> nodes) {
      return nodes.map((node) {
        return {
          'id': node.id,
          'name': node.name,
          'children': buildTree(childrenMap[node.id] ?? []),
        };
      }).toList();
    }
    return buildTree(rootCategories);
  }
}