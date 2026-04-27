import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

class BasketProvider extends ChangeNotifier {
  final Map<int, List<CartItem>> _userBaskets = {};

  List<CartItem> getItemsForUser(int userId) => _userBaskets[userId] ?? [];

  int totalPriceForUser(int userId) {
    final items = getItemsForUser(userId);
    return items.fold(0, (sum, item) => sum + (item.price * item.days));
  }

  void addToCartForUser(int userId, CartItem item) {
    _userBaskets[userId] ??= [];
    _userBaskets[userId]!.add(item);
    notifyListeners();
    _saveToPrefs(userId);
  }

  void clearCartForUser(int userId) {
    _userBaskets.remove(userId);
    notifyListeners();
    _saveToPrefs(userId);
  }

  Future<void> _saveToPrefs(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = getItemsForUser(userId);
    final jsonList = items.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('basket_items_$userId', jsonList);
  }

  Future<void> loadForUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('basket_items_$userId');
    if (jsonList != null) {
      final items = jsonList
          .map((s) => CartItem.fromJson(jsonDecode(s)))
          .toList();
      _userBaskets[userId] = items;
    } else {
      _userBaskets.remove(userId);
    }
    notifyListeners();
  }
}