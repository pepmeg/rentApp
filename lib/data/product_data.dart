import '../models/product.dart';

class ProductData {
  static final List<Product> products = [
    Product(
        id: 1,
        name: 'Электродрель',
        price: 500,
        location: 'Йошкар-Ола',
        images: ['assets/drill.png'],
    ),
    Product(
        id: 2,
        name: 'Палатка',
        price: 1300,
        location: 'Йошкар-Ола',
        images: ['assets/palatka.png'],
    ),
  ];

  static List<Product> getAllProducts() => products;

  static List<Product> searchProducts(String query) {
    if (query.isEmpty) return products;
    return products
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
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
  }
}