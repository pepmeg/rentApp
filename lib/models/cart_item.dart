class CartItem {
  final int id;
  final String name;
  final int price;
  final List<String> images;
  final int ownerId;
  int _days;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    required this.ownerId,
    int days = 1,
  }) : _days = (days < 1) ? 1 : days;

  int get days => _days;
  set days(int value) {
    _days = (value < 1) ? 1 : value;
  }
}