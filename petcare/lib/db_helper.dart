import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DBHelper {
  static Database? _database;
  static const String tableName = 'pets';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    sqfliteFfiInit();
    databaseFactoryOrNull = databaseFactoryFfi;

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'pets.db');

    // Prints db location
    print('Database Path: $path');

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $tableName (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              age INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
  }

  Future<int> addPet(String name, String type, int age) async {
    final db = await database;
    return await db.insert(tableName, {'name': name, 'type': type, 'age': age});
  }

  Future<List<Map<String, dynamic>>> getPets() async {
    final db = await database;
    return await db.query(tableName);
  }

  Future<int> deletePet(int id) async {
    final db = await database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
