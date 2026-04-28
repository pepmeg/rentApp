import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class ProductData {
  static const String _productsKey = 'saved_products';
  static List<Product> products = [];

  static List<Product> getAllProducts({int? ownerId}) {
    if (ownerId == null) return products;
    return products.where((p) => p.ownerId == ownerId).toList();
  }

  static List<Product> searchProducts(String query, {int? ownerId}) {
    final list = ownerId != null ? getAllProducts(ownerId: ownerId) : products;
    if (query.isEmpty) return list;
    return list.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  static Product? getProductById(int id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static void addProduct(Product product) {
    products.add(product);
    _saveToPrefs();
  }

  static void updateProduct(int id, Product updatedProduct) {
    final index = products.indexWhere((p) => p.id == id);
    if (index != -1) {
      products[index] = updatedProduct;
      _saveToPrefs();
    }
  }

  static void deleteProduct(int id) {
    products.removeWhere((p) => p.id == id);
    _saveToPrefs();
  }

  static Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_productsKey);
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        products = decoded
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Ошибка загрузки продуктов: $e');
        products = [];
      }
    } else {
      products = [];
    }
  }

  static void deleteProductsByOwner(int ownerId) {
    products.removeWhere((p) => p.ownerId == ownerId);
    _saveToPrefs();
  }

  static Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(products.map((p) => p.toJson()).toList());
    await prefs.setString(_productsKey, jsonString);
  }
}