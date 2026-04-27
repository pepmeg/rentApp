import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class ProductData {
  static const String _productsKey = 'saved_products';
  static final List<Product> _presetProducts = [
    Product(
      id: 1,
      ownerId: -1,
      name: 'Электродрель',
      price: 500,
      location: 'Йошкар-Ола',
      images: ['assets/drill.png'],
      category: 'Инструменты',
      subcategory: 'Электроинструменты',
      createdAt: DateTime(2026, 4, 20),
    ),
    Product(
      id: 2,
      ownerId: -1,
      name: 'Палатка',
      price: 1300,
      location: 'Йошкар-Ола',
      images: ['assets/palatka.png'],
      category: 'Личные вещи',
      subcategory: 'Спорт и отдых',
      createdAt: DateTime(2026, 4, 21),
    ),
  ];

  static List<Product> products = [];

  static List<Product> getAllProducts({int? ownerId}) {
    if (ownerId == null) return products;
    return products.where((p) => p.ownerId == ownerId || p.ownerId == -1).toList();
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
        final loadedProducts = decoded
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();

        for (final preset in _presetProducts) {
          if (!loadedProducts.any((p) => p.id == preset.id)) {
            loadedProducts.add(preset);
          }
        }
        products = loadedProducts;
      } catch (e) {
        print('Ошибка загрузки продуктов: $e');
        products = List.from(_presetProducts);
      }
    } else {
      products = List.from(_presetProducts);
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