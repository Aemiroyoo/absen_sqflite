import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
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

    // Cek apakah sudah absen Masuk hari ini
    final check = await db.query(
      'attendance',
      where: 'date = ? AND type = ? AND user_email = ?',
      whereArgs: [formattedDate, 'Masuk', email],
    );

    final currentHour = now.hour;
    // Cek jam absen Masuk dan Keluar
    if (currentHour < 6 || currentHour >= 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Absen Masuk hanya bisa antara jam 06:00 AM sampai 12:00 PM.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (currentHour < 12 || currentHour >= 24) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Absen Keluar hanya bisa antara jam 12:00 PM sampai 23:59 PM.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (check.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Anda sudah absen Masuk hari inii.')),
      );
      return;
    }

    // Dapatkan lokasi user
    Position position = await Geolocator.getCurrentPosition();
    double lat = position.latitude;
    double lng = position.longitude;

    // 🔄 Reverse Geocoding ke alamat
    String address = await AbsenServices.getAddressFromLatLng(lat, lng);
    print('📍 Alamat yang akan disimpan: $address');

    Attendance att = Attendance(
      type: 'Masuk',
      date: formattedDate,
      time: formattedTime,
      userEmail: email!,
      address: address,
    );

    await DBHelper.insertAttendance(att);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('✅ Absen Masuk dari: $address')));
  }

  static Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        return "${place.street}, ${place.locality}, ${place.administrativeArea}";
      }
    } catch (e) {
      print('Error get address: $e');
    }
    return 'Alamat tidak ditemukan';
  }

  static Future<void> absenKeluar(BuildContext context) async {
    final email = await PrefService.getEmail();
    final now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    String formattedTime = DateFormat('HH:mm:ss').format(now);
    final db = await DBHelper.initDb();

    // Cek apakah user sudah absen Masuk hari ini
    final todayAttendance = await db.query(
      'attendance',
      where: 'date = ? AND user_email = ?',
      whereArgs: [formattedDate, email],
    );

    bool hasMasuk = todayAttendance.any((att) => att['type'] == 'Masuk');
    bool hasKeluar = todayAttendance.any((att) => att['type'] == 'Keluar');

    if (!hasMasuk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Anda belum absen Masuk. Tidak bisa absen Keluar.'),
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

    // Lokasi & Alamat
    Position position = await Geolocator.getCurrentPosition();
    double lat = position.latitude;
    double lng = position.longitude;
    String address = await AbsenServices.getAddressFromLatLng(lat, lng);

    Attendance att = Attendance(
      type: 'Keluar',
      date: formattedDate,
      time: formattedTime,
      userEmail: email!,
      address: address,
    );

    await DBHelper.insertAttendance(att);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Absen Keluar dari: $address'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
