import '../models/product.dart';

class ProductData {
  static final List<Product> products = [
    Product(
        name: 'Дрель',
        price: 300,
        location: 'Йошкар-Ола',
        image: 'assets/drill.png'
    ),
    Product(
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

  static Product getProductByIndex(int index) {
    return products[index];
  }
}