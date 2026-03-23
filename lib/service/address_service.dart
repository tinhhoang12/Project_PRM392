import '../service/database_service.dart';
import '../entity/address.dart';

class AddressService {
  final db = DatabaseService.instance;

  Future<List<Address>> getAll(int userId) async {
    final database = await db.database;

    final result = await database.query(
      'addresses',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return result.map((e) => Address.fromMap(e)).toList();
  }
  Future<void> insert(Address address) async {
  final database = await db.database;
   if (address.isDefault == 1) {
    await database.update('addresses', {'is_default': 0});
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
    await dbClient.update('addresses', {'is_default': 0});
  }

  await dbClient.update(
    'addresses',
    {
      'name': address.name,
      'phone': address.phone,
      'address': address.address,
      'is_default': address.isDefault,
    },
    where: 'id = ?',
    whereArgs: [address.id],
  );
}
Future<void> delete(int id) async {
  final dbClient = await db.database;

  await dbClient.delete(
    'addresses',
    where: 'id = ?',
    whereArgs: [id],
  );
}
}