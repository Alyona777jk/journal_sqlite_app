import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/review.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<Review> _reviews = [];
  final _commentController = TextEditingController();
  double _userRating = 5.0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final reviews = await DatabaseHelper.instance.getReviews(widget.product.id!);
    setState(() => _reviews = reviews);
  }

  void _submitReview() async {
    if (_commentController.text.trim().isEmpty) return;

    final review = Review(
      productId: widget.product.id!,
      userName: 'User',
      rating: _userRating,
      comment: _commentController.text,
      createdAt: DateTime.now().toIso8601String(),
    );

    await DatabaseHelper.instance.addReview(review);
    _commentController.clear();
    _loadReviews();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.product;
    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              color: Colors.indigo.shade50,
              child: const Icon(Icons.shopping_bag, size: 80, color: Colors.indigo),
            ),
            const SizedBox(height: 12),
            Text(item.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(item.description, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Price: \$${item.discountPrice ?? item.price}', style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
            const Divider(),
            ElevatedButton.icon(
              onPressed: () async {
                await DatabaseHelper.instance.addToCart(item.id!);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart!')));
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add to Cart'),
            ),
            const SizedBox(height: 20),
            const Text('Reviews:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                const Text('Rating: '),
                Slider(
                  value: _userRating,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '$_userRating',
                  onChanged: (val) => setState(() => _userRating = val),
                ),
              ],
            ),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(labelText: 'Your review', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 6),
            ElevatedButton(onPressed: _submitReview, child: const Text('Submit Review')),
            const SizedBox(height: 12),
            ..._reviews.map((r) => ListTile(
                  title: Text('${r.userName} (★ ${r.rating})'),
                  subtitle: Text(r.comment),
                )),
          ],
        ),
      ),
    );
  }
}