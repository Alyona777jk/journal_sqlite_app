class Product {
  final int? id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final int categoryId;
  final String imageUrl;
  final int stockQuantity;
  final double rating;
  final int reviewCount;
  final bool isFeatured;
  final bool isFavorite;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.categoryId,
    required this.imageUrl,
    required this.stockQuantity,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isFeatured = false,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discount_price': discountPrice,
      'category_id': categoryId,
      'image_url': imageUrl,
      'stock_quantity': stockQuantity,
      'rating': rating,
      'review_count': reviewCount,
      'is_featured': isFeatured ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, {bool isFav = false}) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: (map['price'] as num).toDouble(),
      discountPrice: map['discount_price'] != null ? (map['discount_price'] as num).toDouble() : null,
      categoryId: map['category_id'],
      imageUrl: map['image_url'] ?? '',
      stockQuantity: map['stock_quantity'],
      rating: (map['rating'] as num).toDouble(),
      reviewCount: map['review_count'],
      isFeatured: map['is_featured'] == 1,
      isFavorite: isFav,
    );
  }
}