class CartItem {
  final int id;
  final String name;
  final int price;
  final List<String> images;
  int days;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    this.days = 1,
  });
}