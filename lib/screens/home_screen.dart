import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/attendance_model.dart';
import '../services/pref_services.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _absenMasukTime;
  String? _absenKeluarTime;
  String _statusHarian = 'Loading status...';

  @override
  void initState() {
    super.initState();
    // DBHelper.deleteDb(); // panggil sekali saja di awal
    _loadTodayAttendance();
  }

  Future<void> _absenIzin(BuildContext context, String reason) async {
    final now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now); // <-- FIXED
    String formattedTime = DateFormat('HH:mm:ss').format(now);

    final db = await DBHelper.initDb();

    final todayAttendance = await db.query(
      'attendance',
      where: 'date = ?',
      whereArgs: [formattedDate],
    );

    bool hasMasuk = todayAttendance.any((att) => att['type'] == 'Masuk');
    bool hasIzin = todayAttendance.any((att) => att['type'] == 'Izin');

    if (hasMasuk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ Anda sudah Absen Masuk hari ini. Tidak bisa mengajukan Izin.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (hasIzin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Anda sudah mengajukan Izin hari ini.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Attendance att = Attendance(
      type: 'Izin',
      date: formattedDate,
      time: formattedTime,
      reason: reason,
    );
    await DBHelper.insertAttendance(att);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Berhasil mengajukan Izin pada $formattedTime'),
        backgroundColor: Colors.green,
      ),
    );

    _loadTodayAttendance();
  }

  void _loadTodayAttendance() async {
    final now = DateTime.now();
    String today = DateFormat('yyyy-MM-dd').format(now);

    final db = await DBHelper.initDb();
    final result = await db.query(
      'attendance',
      where: 'date = ?',
      whereArgs: [today],
    );

    String? masuk;
    String? keluar;
    bool hasIzin = false;

    for (var item in result) {
      if (item['type'] == 'Masuk') {
        masuk = item['time']?.toString();
      } else if (item['type'] == 'Keluar') {
        keluar = item['time']?.toString();
      } else if (item['type'] == 'Izin') {
        hasIzin = true;
      }
    }

    // Set status harian
    String status = 'Anda belum absen hari ini.';
    if (hasIzin) {
      status = 'Anda sudah mengajukan Izin hari ini.';
    } else if (masuk != null && keluar != null) {
      status = 'Anda sudah absen Masuk dan Keluar hari ini.';
    } else if (masuk != null) {
      status = 'Anda sudah absen Masuk hari ini.';
    }

    setState(() {
      _absenMasukTime = masuk;
      _absenKeluarTime = keluar;
      _statusHarian = status;
    });
  }

  void _absen(BuildContext context, String type) async {
    final now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    String formattedTime = DateFormat('HH:mm:ss').format(now);

    final db = await DBHelper.initDb();

    // Ambil semua absen hari ini
    final todayAttendance = await db.query(
      'attendance',
      where: 'date = ?',
      whereArgs: [formattedDate],
    );

    bool hasMasuk = todayAttendance.any((att) => att['type'] == 'Masuk');
    bool hasIzin = todayAttendance.any((att) => att['type'] == 'Izin');

    // Validasi
    if (type == 'Masuk' && hasIzin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ Anda sudah mengajukan Izin hari ini. Tidak bisa Absen Masuk.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (type == 'Keluar') {
      if (!hasMasuk) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Anda belum Absen Masuk hari ini. Tidak bisa Absen Keluar.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Validasi jam kerja
    final currentHour = now.hour;

    if (type == 'Masuk') {
      if (currentHour < 6 || currentHour >= 12) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Absen Masuk hanya bisa antara jam 06:00 sampai 12:00.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else if (type == 'Keluar') {
      if (currentHour < 12 || currentHour >= 24) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Absen Keluar hanya bisa antara jam 12:00 sampai 23:59.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Cek apakah sudah absen type sama
    final existing = await DBHelper.checkAttendance(formattedDate, type);

    if (existing) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Anda sudah absen $type hari ini.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      Attendance att = Attendance(
        type: type,
        date: formattedDate,
        time: formattedTime,
      );
      await DBHelper.insertAttendance(att);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Berhasil Absen $type pada $formattedTime'),
          backgroundColor: Colors.green,
        ),
      );

      _loadTodayAttendance();
    }
  }

  void _showIzinDialog(BuildContext context) {
    TextEditingController _reasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Ajukan Izin'),
            content: TextField(
              controller: _reasonController,
              decoration: InputDecoration(hintText: 'Alasan Izin'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  String reason = _reasonController.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Alasan tidak boleh kosong.')),
                    );
                    return;
                  }

                  Navigator.pop(context); // Tutup dialog
                  await _absenIzin(context, reason); // Lanjutkan absen izin
                },
                child: Text('Ajukan'),
              ),
            ],
          ),
    );
  }

  void _logout(BuildContext context) async {
    await PrefService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home Absensi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Card Info Absen
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Absensi Hari Ini',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        DateFormat(
                          'EEEE, dd MMMM yyyy',
                        ).format(DateTime.now()), // <- Tambahan
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      _statusHarian,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Masuk:', style: TextStyle(fontSize: 16)),
                        Text(
                          _absenMasukTime ?? 'Belum Absen',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Keluar:', style: TextStyle(fontSize: 16)),
                        Text(
                          _absenKeluarTime ?? 'Belum Absen',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            // Menu Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(
                    context,
                    icon: Icons.login,
                    label: 'Absen Masuk',
                    color: Colors.green,
                    onTap: () => _absen(context, 'Masuk'),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.logout,
                    label: 'Absen Keluar',
                    color: Colors.orange,
                    onTap: () => _absen(context, 'Keluar'),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.history,
                    label: 'Riwayat Absensi',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => HistoryScreen()),
                      ).then((value) {
                        _loadTodayAttendance();
                      });
                    },
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.assignment_turned_in,
                    label: 'Absen Izin',
                    color: Colors.blueGrey,
                    onTap: () => _showIzinDialog(context),
                  ),

                  _buildMenuCard(
                    context,
                    icon: Icons.exit_to_app,
                    label: 'Logout',
                    color: Colors.red,
                    onTap: () => _logout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
