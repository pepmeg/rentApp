class CartItem {
  final int id;
  final String name;
  final int price;
  final List<String> images;
  final int ownerId;
  int days;
  int extraHours;
  final bool isHourly;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    required this.ownerId,
    this.days = 0,
    this.extraHours = 0,
    this.isHourly = false,
  });

  int get totalAmount {
    if (isHourly) return price * days;
    final daysCost = price * days;
    final hoursCost = (price * extraHours / 24).round();
    return daysCost + hoursCost;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'images': images,
    'ownerId': ownerId,
    'days': days,
    'extraHours': extraHours,
    'isHourly': isHourly,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] as int,
    name: json['name'] as String,
    price: json['price'] as int,
    images: List<String>.from(json['images'] as List),
    ownerId: json['ownerId'] as int,
    days: json['days'] as int? ?? 0,
    extraHours: json['extraHours'] as int? ?? 0,
    isHourly: json['isHourly'] as bool? ?? false,
  );
}