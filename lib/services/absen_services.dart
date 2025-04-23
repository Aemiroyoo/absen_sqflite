import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/attendance_model.dart';
import '../services/pref_services.dart';

class AbsenServices {
  static Future<void> absenMasuk(BuildContext context) async {
    final email = await PrefService.getEmail();
    final now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    String formattedTime = DateFormat('HH:mm:ss').format(now);

    final db = await DBHelper.initDb();
    final check = await db.query(
      'attendance',
      where: 'date = ? AND type = ? AND user_email = ?',
      whereArgs: [formattedDate, 'Masuk', email],
    );

    if (check.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Anda sudah absen Masuk hari ini.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Attendance att = Attendance(
      type: 'Masuk',
      date: formattedDate,
      time: formattedTime,
      userEmail: email!,
    );

    await DBHelper.insertAttendance(att);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Berhasil absen Masuk!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  static Future<void> absenKeluar(BuildContext context) async {
    final email = await PrefService.getEmail();
    final now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    String formattedTime = DateFormat('HH:mm:ss').format(now);

    final db = await DBHelper.initDb();
    final today = await db.query(
      'attendance',
      where: 'date = ? AND user_email = ?',
      whereArgs: [formattedDate, email],
    );

    bool hasMasuk = today.any((item) => item['type'] == 'Masuk');
    bool hasKeluar = today.any((item) => item['type'] == 'Keluar');

    if (!hasMasuk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Anda belum absen Masuk hari ini.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (hasKeluar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Anda sudah absen Keluar hari ini.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Attendance att = Attendance(
      type: 'Keluar',
      date: formattedDate,
      time: formattedTime,
      userEmail: email!,
    );

    await DBHelper.insertAttendance(att);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Berhasil absen Keluar!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
