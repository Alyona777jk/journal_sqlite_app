import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/cart_item.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final items = await DatabaseHelper.instance.getCartItems();
    setState(() => _cartItems = items);
  }

  double get _totalPrice => _cartItems.fold(0, (sum, item) => sum + item.totalPrice);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              await DatabaseHelper.instance.clearCart();
              _loadCart();
            },
          )
        ],
      ),
      body: _cartItems.isEmpty
          ? const Center(child: Text('Cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (ctx, idx) {
                      final item = _cartItems[idx];
                      return ListTile(
                        title: Text(item.product.name),
                        subtitle: Text('Total: \$${item.totalPrice.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () async {
                                await DatabaseHelper.instance.updateCartQuantity(item.id, item.quantity - 1);
                                _loadCart();
                              },
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () async {
                                await DatabaseHelper.instance.updateCartQuantity(item.id, item.quantity + 1);
                                _loadCart();
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.indigo.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total: \$${_totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ElevatedButton(onPressed: () {}, child: const Text('Checkout')),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}