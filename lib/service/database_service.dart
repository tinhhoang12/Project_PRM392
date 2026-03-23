import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('shopping.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        email TEXT,
        full_name TEXT,
        phone TEXT,
        address TEXT,
        avatar TEXT,
        role TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        category_id INTEGER,
        price REAL,
        image TEXT,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        payment_method TEXT,   -- 🔥 thêm
        address_id INTEGER,
        total REAL,
        status TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER,
        quantity INTEGER,
        price REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER,
        product_id INTEGER,
        quantity INTEGER,
        price REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE addresses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT,
        phone TEXT,
        address TEXT,
        is_default INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE session (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER
      )
    ''');

    // Add notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        body TEXT,
        user_id INTEGER,
        is_read INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    // seed data
await db.insert('categories', {'id': 1, 'name': 'Audio'});
await db.insert('categories', {'id': 2, 'name': 'Wearables'});
await db.insert('categories', {'id': 3, 'name': 'Computing'});
await db.insert('categories', {'id': 4, 'name': 'Gaming'});
await db.insert('orders', {
  'user_id': 1,
  'total': 156.4,
  'status': 'Pending',
  'created_at': DateTime.now().toString(),
});

await db.insert('orders', {
  'user_id': 2,
  'total': 89,
  'status': 'Pending',
  'created_at': DateTime.now().toString(),
});

    // Seed order_items để đơn hàng có sản phẩm và hiển thị ảnh đúng
    await db.insert('order_items', {
      'order_id': 1,
      'product_id': 1, // Wireless Headphones
      'quantity': 1,
      'price': 199
    });
    await db.insert('order_items', {
      'order_id': 2,
      'product_id': 2, // Wrist Watch
      'quantity': 1,
      'price': 145
    });
await db.insert('products', {
  'name': 'Wireless Headphones',
'category_id': 1,
  'price': 199,
  'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCIisXVTWaOfArSeyaPjmi87SUIa3BCPHizz_uGn7vXvkpWpzViACNUfp41hgukN6xPdfSlTpmrzgCgWuQwULW-HhV3UkBUIRNYKC2CDalqpdHif4EF9e6L-_dxLdZTbkOusZ0CB3fS3Qc6KF25cIGGDvfQf_JoThU62kgX9HehsN1A5hv4r4aOlZAk482jCbFf41SCJwPXUn5Rl2uK8v8g3QCUpNLrUlM-airZGxf5jNH2aimLRnKNlSnofA3_uGLtHXD3KUuabLc'
});

await db.insert('products', {
  'name': 'Wrist Watch',
  'category_id': 2,
  'price': 145,
  'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCQggNAnepb2iDv7YfGh-dbzHukMzQzg-gPzGU588oIaTza6CNfXz19ARflHnm3tGs3drglZqP-lE-lHx8lUVA0kSVx2sAqJAy6QycqRL6ATXqIYnKN2HhPQ_mquRi3sqPsRps9N4cNhAweuFVD5DMLctK4OTcXMf_8Mvl4tY1U8QrMU_COoebu7S8B0Val3NQqFQF6gpTEZLH64X8zh1LC6eypgPcgO1cd6-H_Cer5MbT_tiCmrNH0V1_9VIZHpZLLMePaIdCP-v4'
});

    // seed data
    await db.insert('users', {
      'username': 'admin',
      'password': '1',
      'role': 'admin',
      'full_name': 'Administrator',
      'created_at': DateTime.now().toString()
    });

    await db.insert('users', {
      'username': 'user',
      'password': '2',
      'role': 'user',
      'full_name': 'Normal User',
      'created_at': DateTime.now().toString()
    });
  }
}