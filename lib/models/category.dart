class Category {
  final int? id;
  final String name;
  final String description;
  final String icon;
  final int? parentId;
  final int productCount;

  Category({
    this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.parentId,
    this.productCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'parent_id': parentId,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      icon: map['icon'] ?? 'category',
      parentId: map['parent_id'],
      productCount: map['product_count'] ?? 0,
    );
  }
}