import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DBHelper {
  static sqflite.Database? _database;
  static const String tableName = 'pets';

  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<sqflite.Database> _initDB() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'pets.db');

    print('Database Path: $path');

    if (Platform.isWindows || Platform.isLinux) {
      // Initialize FFI only on Windows/Linux
      sqfliteFfiInit();
      final db = await databaseFactoryFfi.openDatabase(path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute(_createTableSQL());
          },
        ),
      );
      return db;
    } else {
      // On Android/iOS/macOS, use regular sqflite
      final db = await sqflite.openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute(_createTableSQL());
        },
      );
      return db;
    }
  }

  String _createTableSQL() {
    return '''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        age INTEGER NOT NULL
      )
    ''';
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
