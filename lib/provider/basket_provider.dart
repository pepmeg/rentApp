import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class BasketProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get totalPrice => _items.fold(0, (sum, item) => sum + (item.price * item.days));

  void addToCart(CartItem item) {
    final existingIndex = _items.indexWhere((i) => i.id == item.id);
    if (existingIndex != -1) {
      int newDays = _items[existingIndex].days + item.days;

      _items[existingIndex].days = newDays > 99 ? 99 : newDays;
    } else {
      if (item.days > 99) {
        item.days = 99;
      }
      _items.add(item);
    }
    notifyListeners();
  }

  void removeFromCart(int id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateDays(int id, int newDays) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {

      if (newDays < 1) {
        _items[index].days = 1;
      } else if (newDays > 99) {
        _items[index].days = 99;
      } else {
        _items[index].days = newDays;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}