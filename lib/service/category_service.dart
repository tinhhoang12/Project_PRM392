import 'package:sqflite/sqflite.dart';
import '../entity/category.dart';
import 'database_service.dart';

class CategoryService {

  // GET ALL
  Future<List<Category>> getAll() async {
    final db = await DatabaseService.instance.database;
    final result = await db.query('categories');

    return result.map((e) => Category.fromMap(e)).toList();
  }

  // INSERT
  Future<int> insert(Category category) async {
    final db = await DatabaseService.instance.database;

    return await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // UPDATE
  Future<int> update(Category category) async {
    final db = await DatabaseService.instance.database;

    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // DELETE
  Future<int> delete(int id) async {
    final db = await DatabaseService.instance.database;

    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}