class Product {
  final int id;
  final int ownerId;
  final String name;
  final int price;
  final String location;
  final List<String> images;
  final String category;
  final String description;
  final String subcategory;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.price,
    required this.location,
    required this.images,
    this.category = '',
    this.subcategory = '',
    this.description = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();


  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'name': name,
    'price': price,
    'location': location,
    'images': images,
    'category': category,
    'description': description,
    'subcategory': subcategory,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as int,
    ownerId: json['ownerId'] as int,
    name: json['name'] as String,
    price: json['price'] as int,
    location: json['location'] as String,
    images: List<String>.from(json['images'] as List),
    category: json['category'] as String,
    subcategory: json['subcategory'] as String? ?? '',
    description: json['description'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}