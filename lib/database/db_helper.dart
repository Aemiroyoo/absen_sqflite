import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';

class DBHelper {
  static Database? _db;

  // Init database
  static Future<Database> initDb() async {
    if (_db != null) return _db!;

    String path = join(await getDatabasesPath(), 'attendance.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Membuat tabel attendance
        await db.execute('''
          CREATE TABLE attendance(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT,
            date TEXT,
            time TEXT,
            reason TEXT
          )
        ''');

        // Membuat tabel users
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT
          )
        ''');
      },
    );
    return _db!;
  }

  // ================================
  // Fungsi untuk tabel Attendance
  // ================================

  // Insert Attendance
  static Future<int> insertAttendance(Attendance att) async {
    final db = await initDb();
    return await db.insert('attendance', att.toMap());
  }

  // Get All Attendance
  static Future<List<Attendance>> getAllAttendance() async {
    final db = await initDb();
    final List<Map<String, dynamic>> maps = await db.query('attendance');
    return List.generate(maps.length, (i) {
      return Attendance.fromMap(maps[i]);
    });
  }

  // Delete Attendance by id
  static Future<int> deleteAttendance(int id) async {
    final db = await initDb();
    return await db.delete('attendance', where: 'id = ?', whereArgs: [id]);
  }

  // ================================
  // Fungsi untuk tabel Users
  // ================================

  // Insert User (Register)
  static Future<int> insertUser(UserModel user) async {
    final db = await initDb();
    return await db.insert('users', user.toMap());
  }

  // Get User (Login)
  static Future<UserModel?> getUser(String username, String password) async {
    final db = await initDb();
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  // Check if attendance exists
  static Future<bool> checkAttendance(String date, String type) async {
    final db = await initDb();
    final result = await db.query(
      'attendance',
      where: 'date = ? AND type = ?',
      whereArgs: [date, type],
    );
    return result.isNotEmpty;
  }

  // Delete all attendance records
  static Future<void> deleteDb() async {
    String path = join(await getDatabasesPath(), 'attendance.db');
    await deleteDatabase(path);
  }
}
