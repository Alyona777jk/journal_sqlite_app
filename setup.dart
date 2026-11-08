import 'dart:io';

void main() {
  // Створюємо папки
  Directory('lib/models').createSync(recursive: true);
  Directory('lib/database').createSync(recursive: true);
  Directory('lib/screens').createSync(recursive: true);

  // 1. Models
  File('lib/models/category.dart').writeAsStringSync('''
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
''');

  File('lib/models/product.dart').writeAsStringSync('''
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
''');

  File('lib/models/review.dart').writeAsStringSync('''
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
''');

  File('lib/models/cart_item.dart').writeAsStringSync('''
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
''');

  // 2. Database Helper
  File('lib/database/database_helper.dart').writeAsStringSync('''
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../models/cart_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('catalog.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute("""
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        icon TEXT,
        parent_id INTEGER,
        FOREIGN KEY (parent_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    """);

    await db.execute("""
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        discount_price REAL,
        category_id INTEGER NOT NULL,
        image_url TEXT,
        stock_quantity INTEGER NOT NULL DEFAULT 0,
        rating REAL DEFAULT 0.0,
        review_count INTEGER DEFAULT 0,
        is_featured INTEGER DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    """);

    await db.execute("""
      CREATE TABLE reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        user_name TEXT NOT NULL,
        rating REAL NOT NULL,
        comment TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    """);

    await db.execute("""
      CREATE TABLE cart_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL UNIQUE,
        quantity INTEGER NOT NULL DEFAULT 1,
        added_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    """);

    await db.execute("""
      CREATE TABLE favorites (
        product_id INTEGER PRIMARY KEY,
        added_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    """);

    await db.execute("INSERT INTO categories (name, description, icon, parent_id) VALUES ('Електроніка', 'Ґаджети та пристрої', 'devices', NULL)");
    await db.execute("INSERT INTO categories (name, description, icon, parent_id) VALUES ('Смартфони', 'Телефони', 'phone_android', 1)");
    await db.execute("INSERT INTO categories (name, description, icon, parent_id) VALUES ('Ноутбуки', 'Комп''ютери', 'laptop', 1)");

    await db.execute("INSERT INTO products (name, description, price, discount_price, category_id, image_url, stock_quantity, rating, review_count, is_featured) VALUES ('iPhone 15 Pro', 'Флагманський смартфон', 1200.0, 1100.0, 2, 'https://picsum.photos/200', 10, 4.8, 1, 1)");
    await db.execute("INSERT INTO products (name, description, price, discount_price, category_id, image_url, stock_quantity, rating, review_count, is_featured) VALUES ('MacBook Pro 16', 'Потужний ноутбук', 2500.0, NULL, 3, 'https://picsum.photos/201', 5, 5.0, 1, 1)");
  }

  Future<List<Product>> getProducts({
    String? searchQuery,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sortBy,
  }) async {
    final db = await instance.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause += '(p.name LIKE ? OR p.description LIKE ?)';
      whereArgs.addAll(['%' + searchQuery + '%', '%' + searchQuery + '%']);
    }

    if (categoryId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'p.category_id = ?';
      whereArgs.add(categoryId);
    }

    if (minPrice != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'p.price >= ?';
      whereArgs.add(minPrice);
    }

    if (maxPrice != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'p.price <= ?';
      whereArgs.add(maxPrice);
    }

    if (minRating != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'p.rating >= ?';
      whereArgs.add(minRating);
    }

    String orderBy = 'p.id DESC';
    if (sortBy == 'price_asc') orderBy = 'p.price ASC';
    if (sortBy == 'price_desc') orderBy = 'p.price DESC';
    if (sortBy == 'rating') orderBy = 'p.rating DESC';

    final query = '''
      SELECT p.*, (CASE WHEN f.product_id IS NOT NULL THEN 1 ELSE 0 END) as is_favorite
      FROM products p
      LEFT JOIN favorites f ON p.id = f.product_id
      ''' + (whereClause.isNotEmpty ? 'WHERE ' + whereClause : '') + '''
      ORDER BY ''' + orderBy;

    final result = await db.rawQuery(query, whereArgs);
    return result.map((json) => Product.fromMap(json, isFav: json['is_favorite'] == 1)).toList();
  }

  Future<void> addReview(Review review) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert('reviews', review.toMap());

      final res = await txn.rawQuery(
        'SELECT AVG(rating) as avg_rating, COUNT(*) as count FROM reviews WHERE product_id = ?',
        [review.productId],
      );

      final avgRating = (res.first['avg_rating'] as num?)?.toDouble() ?? 0.0;
      final count = res.first['count'] as int;

      await txn.update(
        'products',
        {'rating': avgRating, 'review_count': count},
        where: 'id = ?',
        whereArgs: [review.productId],
      );
    });
  }

  Future<List<Review>> getReviews(int productId) async {
    final db = await instance.database;
    final res = await db.query('reviews', where: 'product_id = ?', whereArgs: [productId], orderBy: 'created_at DESC');
    return res.map((json) => Review.fromMap(json)).toList();
  }

  Future<void> addToCart(int productId) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    await db.rawInsert('''
      INSERT INTO cart_items (product_id, quantity, added_at)
      VALUES (?, 1, ?)
      ON CONFLICT(product_id) DO UPDATE SET quantity = quantity + 1
    ''', [productId, now]);
  }

  Future<List<CartItem>> getCartItems() async {
    final db = await instance.database;
    final res = await db.rawQuery('''
      SELECT c.*, p.name, p.description, p.price, p.discount_price, p.category_id, p.image_url, p.stock_quantity, p.rating, p.review_count, p.is_featured
      FROM cart_items c
      JOIN products p ON c.product_id = p.id
    ''');

    return res.map((row) {
      final product = Product.fromMap(row);
      return CartItem(
        id: row['id'] as int,
        productId: row['product_id'] as int,
        quantity: row['quantity'] as int,
        addedAt: row['added_at'] as String,
        product: product,
      );
    }).toList();
  }

  Future<void> updateCartQuantity(int cartId, int quantity) async {
    final db = await instance.database;
    if (quantity <= 0) {
      await db.delete('cart_items', where: 'id = ?', whereArgs: [cartId]);
    } else {
      await db.update('cart_items', {'quantity': quantity}, where: 'id = ?', whereArgs: [cartId]);
    }
  }

  Future<void> clearCart() async {
    final db = await instance.database;
    await db.delete('cart_items');
  }

  Future<void> toggleFavorite(int productId) async {
    final db = await instance.database;
    final res = await db.query('favorites', where: 'product_id = ?', whereArgs: [productId]);
    if (res.isNotEmpty) {
      await db.delete('favorites', where: 'product_id = ?', whereArgs: [productId]);
    } else {
      await db.insert('favorites', {
        'product_id': productId,
        'added_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<Category>> getCategoriesWithCounts() async {
    final db = await instance.database;
    final res = await db.rawQuery('''
      SELECT c.*, COUNT(p.id) as product_count
      FROM categories c
      LEFT JOIN products p ON c.id = p.category_id
      GROUP BY c.id
    ''');
    return res.map((json) => Category.fromMap(json)).toList();
  }
}
''');

  // 3. Screens & Main
  File('lib/screens/catalog_screen.dart').writeAsStringSync('''
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
      appBar: AppBar(title: const Text('Каталог товарів')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Пошук товару...',
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
                  label: const Text('Всі'),
                  selected: _selectedCategory == null,
                  onSelected: (_) {
                    setState(() => _selectedCategory = null);
                    _loadData();
                  },
                ),
                ..._categories.map((c) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: ChoiceChip(
                    label: Text('\${c.name} (\${c.productCount})'),
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
                ? const Center(child: Text('Товари не знайдені'))
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
                                        Text('\\\$\${item.discountPrice ?? item.price}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                        if (item.discountPrice != null)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 4),
                                            child: Text('\\\$\${item.price}', style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 12)),
                                          ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, size: 14, color: Colors.amber),
                                        Text(' \${item.rating} (\${item.reviewCount})', style: const TextStyle(fontSize: 12)),
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
''');

  File('lib/screens/product_detail_screen.dart').writeAsStringSync('''
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
      userName: 'Студент',
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
            Text('Ціна: \\\$\${item.discountPrice ?? item.price}', style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
            const Divider(),
            ElevatedButton.icon(
              onPressed: () async {
                await DatabaseHelper.instance.addToCart(item.id!);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Додано в кошик!')));
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Додати в кошик'),
            ),
            const SizedBox(height: 20),
            const Text('Відгуки:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                const Text('Оцінка: '),
                Slider(
                  value: _userRating,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '\$_userRating',
                  onChanged: (val) => setState(() => _userRating = val),
                ),
              ],
            ),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(labelText: 'Ваш відгук', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 6),
            ElevatedButton(onPressed: _submitReview, child: const Text('Залишити відгук')),
            const SizedBox(height: 12),
            ..._reviews.map((r) => ListTile(
                  title: Text('\${r.userName} (★ \${r.rating})'),
                  subtitle: Text(r.comment),
                )),
          ],
        ),
      ),
    );
  }
}
''');

  File('lib/screens/cart_screen.dart').writeAsStringSync('''
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
        title: const Text('Кошик'),
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
          ? const Center(child: Text('Кошик порожній'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (ctx, idx) {
                      final item = _cartItems[idx];
                      return ListTile(
                        title: Text(item.product.name),
                        subtitle: Text('Сума: \\\$\${item.totalPrice.toStringAsFixed(2)}'),
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
                            Text('\${item.quantity}'),
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
                      Text('Загалом: \\\$\${_totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ElevatedButton(onPressed: () {}, child: const Text('Оформити')),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
''');

  File('lib/screens/categories_screen.dart').writeAsStringSync('''
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
      appBar: AppBar(title: const Text('Категорії продуктів')),
      body: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (ctx, idx) {
          final cat = _categories[idx];
          return ListTile(
            leading: Icon(cat.parentId == null ? Icons.folder : Icons.subdirectory_arrow_right),
            title: Text(cat.name),
            subtitle: Text(cat.description),
            trailing: Chip(label: Text('\${cat.productCount} товарів')),
          );
        },
      ),
    );
  }
}
''');

  File('lib/main.dart').writeAsStringSync('''
import 'package:flutter/material.dart';
import 'screens/catalog_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/categories_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CatalogApp());
}

class CatalogApp extends StatelessWidget {
  const CatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Каталог товарів',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [
    CatalogScreen(),
    CategoriesScreen(),
    CartScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.store), label: 'Каталог'),
          NavigationDestination(icon: Icon(Icons.category), label: 'Категорії'),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Кошик'),
        ],
      ),
    );
  }
}
''');

  print('Successfully created all project files!');
}
