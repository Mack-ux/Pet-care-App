import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DBHelper {
  static sqflite.Database? _database;
  static Future<sqflite.Database>? _initDBOnce;
  static const String tableName = 'pets';

  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _initDBOnce ??= _initDB();
    _database = await _initDBOnce!;
    return _database!;
  }

  Future<sqflite.Database> _initDB() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'pets.db');

    print('Database Path: $path');

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      final db = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await createAllTables(db);
          },
        ),
      );
      return db;
    } else {
      final db = await sqflite.openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await createAllTables(db);
        },
      );
      return db;
    }
  }

  Future<void> createAllTables(sqflite.Database db) async {
    await db.execute(createPetsTableSQL());
    await db.execute(createRemindersTableSQL());
    await db.execute(createLogsTableSQL());
  }

  String createPetsTableSQL() {
    return '''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        age INTEGER NOT NULL
      )
    ''';
  }

  String createRemindersTableSQL() {
    return '''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        text TEXT NOT NULL,
        FOREIGN KEY(pet_id) REFERENCES pets(id)
      )
    ''';
  }

  String createLogsTableSQL() {
    return '''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petId INTEGER,
        type TEXT,
        timestamp TEXT,
        FOREIGN KEY(petId) REFERENCES pets(id)
      )
    ''';
  }

  Future<int> addPet(String name, String type, int age) async {
    final db = await database;
    return await db.insert(tableName, {'name': name, 'type': type, 'age': age});
  }

  Future<int> deletePet(int id) async {
    final db = await database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getPets() async {
    final db = await database;
    return await db.query(tableName);
  }

  // Reminder Methods
  Future<int> addReminder(int petId, String text) async {
    final db = await database;
    return await db.insert('reminders', {'pet_id': petId, 'text': text});
  }

  Future<int> deleteReminder(int id) async {
    final db = await database;
    return await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getRemindersForPet(int petId) async {
    final db = await database;
    return await db.query('reminders', where: 'pet_id = ?', whereArgs: [petId]);
  }

  Future<List<Map<String, dynamic>>> getAllReminders() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT reminders.id, reminders.text, pets.name as pet_name
      FROM reminders
      JOIN pets ON reminders.pet_id = pets.id
    ''');
  }

  // Food/Water Log Methods
  Future<int> addLog(int petId, String type) async {
    final db = await database;
    int result = await db.insert('logs', {
      'petId': petId,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
    });

    final existingLogs = await db.query(
      'logs',
      where: 'petId = ? AND type = ?',
      whereArgs: [petId, type],
      orderBy: 'timestamp DESC',
    );

    if (existingLogs.length > 7) {
      final logsToDelete = existingLogs.sublist(7);
      for (var log in logsToDelete) {
        await db.delete('logs', where: 'id = ?', whereArgs: [log['id']]);
      }
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> getLogsForPet(int petId) async {
    final db = await database;
    return await db.query(
      'logs',
      where: 'petId = ?',
      whereArgs: [petId],
      orderBy: 'timestamp DESC',
    );
  }
}
