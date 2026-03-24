import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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

    return openDatabase(
      path,
      version: 10,
      onConfigure: _onConfigure,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final cartColumns = await db.rawQuery('PRAGMA table_info(cart)');
      final hasCartUserId =
          cartColumns.any((c) => (c['name'] as String?) == 'user_id');

      if (!hasCartUserId) {
        await db.execute('ALTER TABLE cart ADD COLUMN user_id INTEGER');
        await db.rawUpdate('UPDATE cart SET user_id = 1 WHERE user_id IS NULL');
      }

      final orderColumns = await db.rawQuery('PRAGMA table_info(orders)');
      final hasPaymentMethod =
          orderColumns.any((c) => (c['name'] as String?) == 'payment_method');
      final hasAddressId =
          orderColumns.any((c) => (c['name'] as String?) == 'address_id');

      if (!hasPaymentMethod) {
        await db.execute('ALTER TABLE orders ADD COLUMN payment_method TEXT');
      }
      if (!hasAddressId) {
        await db.execute('ALTER TABLE orders ADD COLUMN address_id INTEGER');
      }
    }

    if (oldVersion < 3) {
      final productColumns = await db.rawQuery('PRAGMA table_info(products)');
      final hasQuantity =
          productColumns.any((c) => (c['name'] as String?) == 'quantity');
      if (!hasQuantity) {
        await db
            .execute('ALTER TABLE products ADD COLUMN quantity INTEGER DEFAULT 0');
      }

      await db.rawUpdate(
          'UPDATE products SET quantity = 10 WHERE quantity IS NULL OR quantity = 0');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS audit_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          actor_user_id INTEGER,
          action TEXT,
          target_type TEXT,
          target_id INTEGER,
          old_value TEXT,
          new_value TEXT,
          created_at TEXT
        )
      ''');
    }

    if (oldVersion < 5) {
      final existingStaff = await db.query(
        'users',
        columns: ['id'],
        where: 'LOWER(username) = ?',
        whereArgs: ['staff'],
        limit: 1,
      );

      if (existingStaff.isEmpty) {
        await db.insert('users', {
          'username': 'staff',
          'password':
              'sha256:4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce',
          'role': 'staff',
          'full_name': 'Staff User',
          'created_at': DateTime.now().toString(),
        });
      }
    }

    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS low_stock_alert_preferences (
          product_id INTEGER PRIMARY KEY,
          muted_at TEXT
        )
      ''');
    }

    if (oldVersion < 7) {
      final orderColumns = await db.rawQuery('PRAGMA table_info(orders)');
      final hasPaymentStatus =
          orderColumns.any((c) => (c['name'] as String?) == 'payment_status');
      final hasReceiverName =
          orderColumns.any((c) => (c['name'] as String?) == 'receiver_name');
      final hasReceiverPhone =
          orderColumns.any((c) => (c['name'] as String?) == 'receiver_phone');
      final hasReceiverAddress =
          orderColumns.any((c) => (c['name'] as String?) == 'receiver_address');
      final hasSubtotal =
          orderColumns.any((c) => (c['name'] as String?) == 'subtotal');
      final hasDiscountAmount =
          orderColumns.any((c) => (c['name'] as String?) == 'discount_amount');
      final hasShippingFee =
          orderColumns.any((c) => (c['name'] as String?) == 'shipping_fee');

      if (!hasPaymentStatus) {
        await db.execute(
            'ALTER TABLE orders ADD COLUMN payment_status TEXT DEFAULT \'pending\'');
      }
      if (!hasReceiverName) {
        await db.execute('ALTER TABLE orders ADD COLUMN receiver_name TEXT');
      }
      if (!hasReceiverPhone) {
        await db.execute('ALTER TABLE orders ADD COLUMN receiver_phone TEXT');
      }
      if (!hasReceiverAddress) {
        await db.execute('ALTER TABLE orders ADD COLUMN receiver_address TEXT');
      }
      if (!hasSubtotal) {
        await db.execute('ALTER TABLE orders ADD COLUMN subtotal REAL DEFAULT 0');
      }
      if (!hasDiscountAmount) {
        await db
            .execute('ALTER TABLE orders ADD COLUMN discount_amount REAL DEFAULT 0');
      }
      if (!hasShippingFee) {
        await db.execute('ALTER TABLE orders ADD COLUMN shipping_fee REAL DEFAULT 0');
      }

      await db.execute('''
        UPDATE orders
        SET subtotal = COALESCE(total, 0),
            discount_amount = COALESCE(discount_amount, 0),
            shipping_fee = COALESCE(shipping_fee, 0)
        WHERE subtotal IS NULL OR subtotal = 0
      ''');
      await db.execute('''
        UPDATE orders
        SET payment_status =
          CASE
            WHEN LOWER(COALESCE(payment_method, '')) = 'cod' THEN 'pending'
            ELSE 'paid'
          END
        WHERE payment_status IS NULL OR payment_status = ''
      ''');

      await db.execute('''
        DELETE FROM cart
        WHERE id NOT IN (
          SELECT MIN(id)
          FROM cart
          GROUP BY user_id, product_id
        )
      ''');
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_cart_user_product ON cart(user_id, product_id)',
      );

      final users = await db.query('users', columns: ['id', 'password']);
      for (final row in users) {
        final id = row['id'] as int?;
        final pw = row['password']?.toString() ?? '';
        if (id == null || pw.isEmpty || pw.startsWith('sha256:')) continue;
        await db.update(
          'users',
          {'password': _hashPassword(pw)},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }

    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS product_reviews (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          rating INTEGER NOT NULL,
          comment TEXT,
          created_at TEXT,
          FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');

      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_product_reviews_product_user ON product_reviews(product_id, user_id)',
      );
    }

    if (oldVersion < 9) {
      final orderColumns = await db.rawQuery('PRAGMA table_info(orders)');
      final hasUserReceivedConfirmed = orderColumns
          .any((c) => (c['name'] as String?) == 'user_received_confirmed');
      if (!hasUserReceivedConfirmed) {
        await db.execute(
          'ALTER TABLE orders ADD COLUMN user_received_confirmed INTEGER DEFAULT 0',
        );
      }
      await db.execute('''
        UPDATE orders
        SET user_received_confirmed = 0
        WHERE user_received_confirmed IS NULL
      ''');
    }

    if (oldVersion < 10) {
      final userColumns = await db.rawQuery('PRAGMA table_info(users)');
      final hasIsActive =
          userColumns.any((c) => (c['name'] as String?) == 'is_active');
      if (!hasIsActive) {
        await db
            .execute('ALTER TABLE users ADD COLUMN is_active INTEGER DEFAULT 1');
      }
      await db.execute('''
        UPDATE users
        SET is_active = 1
        WHERE is_active IS NULL
      ''');
    }
  }

  String _hashPassword(String raw) {
    final digest = sha256.convert(utf8.encode(raw));
    return 'sha256:${digest.toString()}';
  }

  Future<void> _createDB(Database db, int version) async {
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
        is_active INTEGER DEFAULT 1,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        category_id INTEGER,
        price REAL,
        quantity INTEGER DEFAULT 0,
        image TEXT,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        payment_method TEXT,
        payment_status TEXT DEFAULT 'pending',
        user_received_confirmed INTEGER DEFAULT 0,
        address_id INTEGER,
        receiver_name TEXT,
        receiver_phone TEXT,
        receiver_address TEXT,
        subtotal REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0,
        shipping_fee REAL DEFAULT 0,
        total REAL,
        status TEXT,
        created_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (address_id) REFERENCES addresses(id)
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
        user_id INTEGER,
        product_id INTEGER,
        quantity INTEGER,
        price REAL,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_cart_user_product ON cart(user_id, product_id)',
    );

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER,
        product_id INTEGER,
        quantity INTEGER,
        price REAL,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE addresses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT,
        phone TEXT,
        address TEXT,
        is_default INTEGER,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE session (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        body TEXT,
        user_id INTEGER,
        is_read INTEGER DEFAULT 0,
        created_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        actor_user_id INTEGER,
        action TEXT,
        target_type TEXT,
        target_id INTEGER,
        old_value TEXT,
        new_value TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE low_stock_alert_preferences (
        product_id INTEGER PRIMARY KEY,
        muted_at TEXT,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE product_reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        rating INTEGER NOT NULL,
        comment TEXT,
        created_at TEXT,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_product_reviews_product_user ON product_reviews(product_id, user_id)',
    );

    await db.insert('categories', {'id': 1, 'name': 'Audio'});
    await db.insert('categories', {'id': 2, 'name': 'Wearables'});
    await db.insert('categories', {'id': 3, 'name': 'Computing'});
    await db.insert('categories', {'id': 4, 'name': 'Gaming'});

    await db.insert('products', {
      'name': 'Wireless Headphones',
      'category_id': 1,
      'price': 199,
      'quantity': 12,
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCIisXVTWaOfArSeyaPjmi87SUIa3BCPHizz_uGn7vXvkpWpzViACNUfp41hgukN6xPdfSlTpmrzgCgWuQwULW-HhV3UkBUIRNYKC2CDalqpdHif4EF9e6L-_dxLdZTbkOusZ0CB3fS3Qc6KF25cIGGDvfQf_JoThU62kgX9HehsN1A5hv4r4aOlZAk482jCbFf41SCJwPXUn5Rl2uK8v8g3QCUpNLrUlM-airZGxf5jNH2aimLRnKNlSnofA3_uGLtHXD3KUuabLc'
    });

    await db.insert('products', {
      'name': 'Wrist Watch',
      'category_id': 2,
      'price': 145,
      'quantity': 3,
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCQggNAnepb2iDv7YfGh-dbzHukMzQzg-gPzGU588oIaTza6CNfXz19ARflHnm3tGs3drglZqP-lE-lHx8lUVA0kSVx2sAqJAy6QycqRL6ATXqIYnKN2HhPQ_mquRi3sqPsRps9N4cNhAweuFVD5DMLctK4OTcXMf_8Mvl4tY1U8QrMU_COoebu7S8B0Val3NQqFQF6gpTEZLH64X8zh1LC6eypgPcgO1cd6-H_Cer5MbT_tiCmrNH0V1_9VIZHpZLLMePaIdCP-v4'
    });

    await db.insert('users', {
      'id': 1,
      'username': 'admin',
      'password':
          'sha256:6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b',
      'role': 'admin',
      'full_name': 'Administrator',
      'created_at': DateTime.now().toString(),
    });

    await db.insert('users', {
      'id': 2,
      'username': 'user',
      'password':
          'sha256:d4735e3a265e16eee03f59718b9b5d03019c07d8b6c51f90da3a666eec13ab35',
      'role': 'user',
      'full_name': 'Normal User',
      'created_at': DateTime.now().toString(),
    });

    await db.insert('users', {
      'id': 3,
      'username': 'staff',
      'password':
          'sha256:4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce',
      'role': 'staff',
      'full_name': 'Staff User',
      'created_at': DateTime.now().toString(),
    });

    await db.insert('orders', {
      'user_id': 1,
      'subtotal': 156.4,
      'discount_amount': 0,
      'shipping_fee': 0,
      'total': 156.4,
      'status': 'Pending',
      'payment_method': 'cod',
      'payment_status': 'pending',
      'user_received_confirmed': 0,
      'receiver_name': 'Administrator',
      'receiver_phone': '0900000000',
      'receiver_address': 'Default Address',
      'address_id': null,
      'created_at': DateTime.now().toString(),
    });

    await db.insert('orders', {
      'user_id': 2,
      'subtotal': 89,
      'discount_amount': 0,
      'shipping_fee': 0,
      'total': 89,
      'status': 'Pending',
      'payment_method': 'card',
      'payment_status': 'paid',
      'user_received_confirmed': 0,
      'receiver_name': 'Normal User',
      'receiver_phone': '0900000001',
      'receiver_address': 'Default Address',
      'address_id': null,
      'created_at': DateTime.now().toString(),
    });

    await db.insert('order_items', {
      'order_id': 1,
      'product_id': 1,
      'quantity': 1,
      'price': 199,
    });

    await db.insert('order_items', {
      'order_id': 2,
      'product_id': 2,
      'quantity': 1,
      'price': 145,
    });
  }
}

