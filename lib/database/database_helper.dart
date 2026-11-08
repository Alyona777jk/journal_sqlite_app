import 'package:flutter/foundation.dart' hide Category;
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
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        icon TEXT,
        parent_id INTEGER,
        FOREIGN KEY (parent_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
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
    ''');

    await db.execute('''
      CREATE TABLE reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        user_name TEXT NOT NULL,
        rating REAL NOT NULL,
        comment TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE cart_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL UNIQUE,
        quantity INTEGER NOT NULL DEFAULT 1,
        added_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        product_id INTEGER PRIMARY KEY,
        added_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    await db.execute("INSERT INTO categories (name, description, icon, parent_id) VALUES ('Electronics', 'Gadgets and devices', 'devices', NULL)");
    await db.execute("INSERT INTO categories (name, description, icon, parent_id) VALUES ('Smartphones', 'Mobile phones', 'phone_android', 1)");
    await db.execute("INSERT INTO categories (name, description, icon, parent_id) VALUES ('Laptops', 'Computers', 'laptop', 1)");

    await db.execute("INSERT INTO products (name, description, price, discount_price, category_id, image_url, stock_quantity, rating, review_count, is_featured) VALUES ('iPhone 15 Pro', 'Flagship smartphone', 1200.0, 1100.0, 2, 'https://picsum.photos/200', 10, 4.8, 1, 1)");
    await db.execute("INSERT INTO products (name, description, price, discount_price, category_id, image_url, stock_quantity, rating, review_count, is_featured) VALUES ('MacBook Pro 16', 'Powerful laptop', 2500.0, NULL, 3, 'https://picsum.photos/201', 5, 5.0, 1, 1)");
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

    final query = 'SELECT p.*, (CASE WHEN f.product_id IS NOT NULL THEN 1 ELSE 0 END) as is_favorite FROM products p LEFT JOIN favorites f ON p.id = f.product_id ' + (whereClause.isNotEmpty ? 'WHERE ' + whereClause : '') + ' ORDER BY ' + orderBy;

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