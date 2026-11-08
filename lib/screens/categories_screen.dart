import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/category.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await DatabaseHelper.instance.getCategoriesWithCounts();
    setState(() => _categories = categories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Categories')),
      body: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (ctx, idx) {
          final cat = _categories[idx];
          return ListTile(
            leading: Icon(cat.parentId == null ? Icons.folder : Icons.subdirectory_arrow_right),
            title: Text(cat.name),
            subtitle: Text(cat.description),
            trailing: Chip(label: Text('${cat.productCount} products')),
          );
        },
      ),
    );
  }
}