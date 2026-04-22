class CartItem {
  final int id;
  final String name;
  final int price;
  final String image;
  int days;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.days = 1,
  });
}