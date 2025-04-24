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
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
      CREATE TABLE attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT,
        date TEXT,
        time TEXT,
        reason TEXT,
        user_email TEXT,
        address TEXT
      )
    ''');
        await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT
      )
    ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS attendance');
        await db.execute('DROP TABLE IF EXISTS users');
        await db.execute('''
      CREATE TABLE attendance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT,
        date TEXT,
        time TEXT,
        reason TEXT,
        user_email TEXT,
        address TEXT
      )
    ''');
        await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
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
  static Future<List<Attendance>> getAllAttendanceByEmail(String email) async {
    final db = await initDb();
    final result = await db.query(
      'attendance',
      where: 'user_email = ?',
      whereArgs: [email],
    );
    return result.map((e) => Attendance.fromMap(e)).toList();
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

  static Future<UserModel?> getUser(String email, String password) async {
    final db = await initDb();
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  static Future<void> updateUserName(String email, String newName) async {
    final db = await initDb();
    await db.update(
      'users',
      {'name': newName},
      where: 'email = ?',
      whereArgs: [email],
    );
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
