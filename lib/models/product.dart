class Product {
  final int id;
  final int ownerId;
  final String name;
  final int price;
  final bool isPricePerHour;
  final String location;
  final List<String> images;
  final String category;
  final String description;
  final String subcategory;
  final String brand;
  final int minRentDays;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.price,
    this.isPricePerHour = false,
    required this.location,
    required this.images,
    this.category = '',
    this.subcategory = '',
    this.description = '',
    this.brand = '',
    this.minRentDays = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();


  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'name': name,
    'price': price,
    'isPricePerHour': isPricePerHour,
    'location': location,
    'images': images,
    'category': category,
    'description': description,
    'subcategory': subcategory,
    'brand': brand,
    'minRentDays': minRentDays,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as int,
    ownerId: json['ownerId'] as int,
    name: json['name'] as String,
    price: json['price'] as int,
    isPricePerHour: json['isPricePerHour'] as bool? ?? false,
    location: json['location'] as String,
    images: List<String>.from(json['images'] as List),
    category: json['category'] as String,
    subcategory: json['subcategory'] as String? ?? '',
    description: json['description'] as String,
    brand: json['brand'] as String? ?? '',
    minRentDays: json['minRentDays'] as int? ?? 1,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  String get region {
    if (location.isEmpty) return '';
    final parts = location.split(',');
    final first = parts.first.trim();
    final regionKeywords = ['область', 'край', 'республика', 'округ'];
    for (final keyword in regionKeywords) {
      if (first.toLowerCase().contains(keyword)) {
        String cleaned = first.replaceFirst(RegExp('\\s*$keyword\\s*', caseSensitive: false), ' ').trim();
        return cleaned;
      }
    }
    if (parts.length > 1) {
      return first;
    }
    return '';
  }

  static int commissionForPrice(int price) {
    if (price > 1000) {
      return (price * 0.03).round();
    } else {
      return (price * 0.05).round();
    }
  }

  int get commission => Product.commissionForPrice(price);

  String get commissionText {
    final rate = price > 1000 ? 3 : 5;
    return 'Сервисный сбор $rate% (~ $commission ₽)';
  }

  String get city {
    if (location.isEmpty) return '';
    final parts = location.split(',');
    final first = parts.first.trim();
    final second = parts.length > 1 ? parts[1].trim() : '';

    String cleanCity(String raw) {
      return raw.replaceFirst(RegExp(r'^(г\.\s*|город\s*)', caseSensitive: false), '').trim();
    }
    if (region.isNotEmpty) {
      if (second.isNotEmpty) {
        return cleanCity(second);
      }
      return '';
    }
    if (parts.length > 1) {
      return cleanCity(second);
    } else {
      return cleanCity(first);
    }
  }
}