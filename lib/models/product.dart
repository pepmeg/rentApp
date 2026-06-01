import '../services/category_service.dart';

class Product {
  final String id;
  final String ownerId;
  final String name;
  final String nameLowercase;
  final int price;
  final bool isPricePerHour;
  final String location;
  final List<String> images;
  final List<String> categoryPath;
  final String brand;
  final String description;
  final int minRentDays;
  final int minRentHours;
  final DateTime createdAt;
  final String moderationStatus;

  Product({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.nameLowercase,
    required this.price,
    this.isPricePerHour = false,
    required this.location,
    required this.images,
    required this.categoryPath,
    this.description = '',
    this.brand = '',
    this.minRentDays = 1,
    this.minRentHours = 1,
    DateTime? createdAt,
    this.moderationStatus = 'active',
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'name': name,
    'nameLowercase': name.toLowerCase(),
    'price': price,
    'isPricePerHour': isPricePerHour,
    'location': location,
    'images': images,
    'categoryPath': categoryPath,
    'brand': brand,
    'description': description,
    'minRentDays': minRentDays,
    'minRentHours': minRentHours,
    'createdAt': createdAt.toIso8601String(),
    'moderationStatus': moderationStatus,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String? ?? '',
    ownerId: json['ownerId'] as String? ?? '',
    name: json['name'] as String? ?? '',
    nameLowercase: json['nameLowercase'] as String? ?? (json['name'] as String? ?? '').toLowerCase(),
    price: json['price'] as int? ?? 0,
    isPricePerHour: json['isPricePerHour'] as bool? ?? false,
    location: json['location'] as String? ?? '',
    images: json['images'] != null ? List<String>.from(json['images']) : [],
    categoryPath: json['categoryPath'] != null ? List<String>.from(json['categoryPath']) : [],
    description: json['description'] as String? ?? '',
    brand: json['brand'] as String? ?? '',
    minRentDays: json['minRentDays'] as int? ?? 1,
    minRentHours: json['minRentHours'] as int? ?? 1,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    moderationStatus: json['moderationStatus'] as String? ?? 'active',
  );

  String get categoryDisplay {
    if (categoryPath.isEmpty) return 'Без категории';
    final service = CategoryService();
    return service.buildPathDisplay(categoryPath);
  }

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