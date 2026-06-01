class CategoryNode {
  final String id;
  final String name;
  final String? parentId;
  final int order;

  CategoryNode({
    required this.id,
    required this.name,
    this.parentId,
    required this.order,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'parentId': parentId,
    'order': order,
  };

  factory CategoryNode.fromJson(String id, Map<String, dynamic> json) {
    return CategoryNode(
      id: id,
      name: json['name'] as String,
      parentId: json['parentId'] as String?,
      order: json['order'] as int? ?? 0,
    );
  }

  bool get isRoot => parentId == null;
}