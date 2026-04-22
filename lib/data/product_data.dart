import '../models/product.dart';

class ProductData {
  static final List<Product> products = [
    Product(
        id: 1,
        name: 'Электродрель',
        price: 500,
        location: 'Йошкар-Ола',
        image: 'assets/drill.png'
    ),
    Product(
        id: 2,
        name: 'Палатка',
        price: 1300,
        location: 'Йошкар-Ола',
        image: 'assets/palatka.png'
    ),
  ];

  static List<Product> getAllProducts(){
    return products;
  }

  static List<Product> searchProducts(String query) {
    if (query.isEmpty) return products;

    return products.where((product){
      return product.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  static Product? getProductById(int id) {
    try {
      return products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }
}