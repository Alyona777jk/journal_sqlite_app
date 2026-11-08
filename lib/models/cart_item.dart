import 'product.dart';

class CartItem {
  final int id;
  final int productId;
  final int quantity;
  final String addedAt;
  final Product product;

  CartItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.addedAt,
    required this.product,
  });

  double get totalPrice {
    final effectivePrice = product.discountPrice ?? product.price;
    return effectivePrice * quantity;
  }
}