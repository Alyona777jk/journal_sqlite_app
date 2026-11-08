import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/category.dart';
import 'product_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<Product> _products = [];
  List<Category> _categories = [];
  String _searchQuery = '';
  int? _selectedCategory;
  String _sortBy = 'default';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final products = await DatabaseHelper.instance.getProducts(
      searchQuery: _searchQuery,
      categoryId: _selectedCategory,
      sortBy: _sortBy,
    );
    final categories = await DatabaseHelper.instance.getCategoriesWithCounts();
    setState(() {
      _products = products;
      _categories = categories;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Catalog')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                _searchQuery = val;
                _loadData();
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (_) {
                    setState(() => _selectedCategory = null);
                    _loadData();
                  },
                ),
                ..._categories.map((c) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: ChoiceChip(
                    label: Text('${c.name} (${c.productCount})'),
                    selected: _selectedCategory == c.id,
                    onSelected: (sel) {
                      setState(() => _selectedCategory = sel ? c.id : null);
                      _loadData();
                    },
                  ),
                )),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _products.isEmpty
                ? const Center(child: Text('No products found'))
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (ctx, idx) {
                      final item = _products[idx];
                      return Card(
                        child: InkWell(
                          onTap: () async {
                            await Navigator.push(ctx, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: item)));
                            _loadData();
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  color: Colors.grey.shade200,
                                  width: double.infinity,
                                  child: const Icon(Icons.shopping_bag, size: 48, color: Colors.indigo),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Row(
                                      children: [
                                        Text('\$${item.discountPrice ?? item.price}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                        if (item.discountPrice != null)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 4),
                                            child: Text('\$${item.price}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 12)),
                                          ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, size: 14, color: Colors.amber),
                                        Text(' ${item.rating} (${item.reviewCount})', style: const TextStyle(fontSize: 12)),
                                        const Spacer(),
                                        IconButton(
                                          icon: Icon(item.isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red, size: 18),
                                          onPressed: () async {
                                            await DatabaseHelper.instance.toggleFavorite(item.id!);
                                            _loadData();
                                          },
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}