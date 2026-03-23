import '../entity/address.dart';
import '../service/database_service.dart';

class AddressService {
  final db = DatabaseService.instance;

  Future<List<Address>> getAll(int userId) async {
    final database = await db.database;

    final result = await database.query(
      'addresses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'is_default DESC, id DESC',
    );

    return result.map((e) => Address.fromMap(e)).toList();
  }

  Future<Address?> getById(int id) async {
    final database = await db.database;
    final result = await database.query(
      'addresses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Address.fromMap(result.first);
  }

  Future<void> insert(Address address) async {
    final database = await db.database;

    if (address.isDefault == 1) {
      await database.update(
        'addresses',
        {'is_default': 0},
        where: 'user_id = ?',
        whereArgs: [address.userId],
      );
    }

    await database.insert('addresses', {
      'user_id': address.userId,
      'name': address.name,
      'phone': address.phone,
      'address': address.address,
      'is_default': address.isDefault,
    });
  }

  Future<void> update(Address address) async {
    final dbClient = await db.database;

    if (address.isDefault == 1) {
      await dbClient.update(
        'addresses',
        {'is_default': 0},
        where: 'user_id = ?',
        whereArgs: [address.userId],
      );
    }

    await dbClient.update(
      'addresses',
      {
        'name': address.name,
        'phone': address.phone,
        'address': address.address,
        'is_default': address.isDefault,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [address.id, address.userId],
    );
  }

  Future<void> delete(int id, int userId) async {
    final dbClient = await db.database;

    await dbClient.delete(
      'addresses',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }
}
