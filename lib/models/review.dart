class Review {
  final int? id;
  final int productId;
  final String userName;
  final double rating;
  final String comment;
  final String createdAt;

  Review({
    this.id,
    required this.productId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'user_name': userName,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'],
      productId: map['product_id'],
      userName: map['user_name'],
      rating: (map['rating'] as num).toDouble(),
      comment: map['comment'],
      createdAt: map['created_at'],
    );
  }
}