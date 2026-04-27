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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'images': images,
    'ownerId': ownerId,
    'days': _days,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] as int,
    name: json['name'] as String,
    price: json['price'] as int,
    images: List<String>.from(json['images'] as List),
    ownerId: json['ownerId'] as int,
    days: json['days'] as int,
  );
}