import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../entity/user.dart';
import 'database_service.dart';

class AuthService {
  static const _hashPrefix = 'sha256:';

  String hashPassword(String raw) {
    final digest = sha256.convert(utf8.encode(raw));
    return '$_hashPrefix${digest.toString()}';
  }

  bool isHashedPassword(String value) {
    return value.startsWith(_hashPrefix);
  }

  bool verifyPassword({
    required String rawPassword,
    required String storedPassword,
  }) {
    if (isHashedPassword(storedPassword)) {
      return hashPassword(rawPassword) == storedPassword;
    }
    return rawPassword == storedPassword;
  }

  Future<User?> login(String username, String password) async {
    final db = await DatabaseService.instance.database;

    final normalizedUsername = username.trim().toLowerCase();
    final result = await db.query(
      'users',
      where: 'LOWER(username) = ? AND COALESCE(is_active, 1) = 1',
      whereArgs: [normalizedUsername],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final foundUser = User.fromMap(result.first);
    final storedPassword = foundUser.password;
    final valid = verifyPassword(
      rawPassword: password,
      storedPassword: storedPassword,
    );

    if (!valid) return null;

    if (!isHashedPassword(storedPassword)) {
      await db.update(
        'users',
        {'password': hashPassword(password)},
        where: 'id = ?',
        whereArgs: [foundUser.id],
      );
    }

    await db.delete('session');
    await db.insert('session', {
      'user_id': foundUser.id,
    });

    final refreshed = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [foundUser.id],
      limit: 1,
    );
    return refreshed.isNotEmpty ? User.fromMap(refreshed.first) : foundUser;
  }

  Future<bool> register(User user) async {
    final db = await DatabaseService.instance.database;

    final normalizedUsername = user.username.trim().toLowerCase();
    final normalizedEmail = user.email?.trim().toLowerCase();

    final existingByUsername = await db.query(
      'users',
      where: 'LOWER(username) = ?',
      whereArgs: [normalizedUsername],
      limit: 1,
    );
    if (existingByUsername.isNotEmpty) {
      return false;
    }

    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      final existingByEmail = await db.query(
        'users',
        where: 'LOWER(email) = ?',
        whereArgs: [normalizedEmail],
        limit: 1,
      );
      if (existingByEmail.isNotEmpty) {
        return false;
      }
    }

    await db.insert('users', {
      ...user.toMap(),
      'username': normalizedUsername,
      'email': normalizedEmail,
      'password': isHashedPassword(user.password)
          ? user.password
          : hashPassword(user.password),
    });

    return true;
  }

  Future<int?> getCurrentUserId() async {
    final db = await DatabaseService.instance.database;

    final session = await db.query('session', limit: 1);

    if (session.isEmpty) return null;
    final userId = session.first['user_id'] as int?;
    if (userId == null) return null;

    final activeUser = await db.query(
      'users',
      columns: ['id'],
      where: 'id = ? AND COALESCE(is_active, 1) = 1',
      whereArgs: [userId],
      limit: 1,
    );

    if (activeUser.isEmpty) {
      await db.delete('session');
      return null;
    }

    return userId;
  }

  Future<void> logout() async {
    final db = await DatabaseService.instance.database;
    await db.delete('session');
  }
}
