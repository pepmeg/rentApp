class CartItem {
  final String id;
  final String name;
  final int price;
  final List<String> images;
  final String ownerId;
  int units;
  int extraHours;
  bool isHourly;
  final DateTime completedAt;
  final bool reminderSent;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    required this.ownerId,
    this.units = 0,
    this.extraHours = 0,
    this.isHourly = false,
    required this.completedAt,
    this.reminderSent = false,
  });

  int get totalAmount {
    if (isHourly) return price * units;
    final daysCost = price * units;
    final hoursCost = (price * extraHours / 24).round();
    return daysCost + hoursCost;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'images': images,
    'ownerId': ownerId,
    'units': units,
    'extraHours': extraHours,
    'isHourly': isHourly,
    'completedAt': completedAt.toIso8601String(),
    'reminderSent': reminderSent,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final oldDays = json['days'] as int? ?? 0;
    final units = json['units'] as int? ?? oldDays;
    return CartItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: json['price'] as int,
      images: List<String>.from(json['images']),
      ownerId: json['ownerId'] as String,
      units: units,
      extraHours: json['extraHours'] as int? ?? 0,
      isHourly: json['isHourly'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt']).toUtc()
          : DateTime.now().toUtc(),
      reminderSent: json['reminderSent'] as bool? ?? false,
    );
  }
}