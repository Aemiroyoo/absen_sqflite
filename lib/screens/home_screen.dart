import 'package:absen_sqflite/screens/absen_keluar_lokasi_screen.dart';
import 'package:absen_sqflite/screens/absen_masuk_lokasi_screen.dart';
import 'package:absen_sqflite/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/attendance_model.dart';
import '../services/pref_services.dart';
import '../services/absen_services.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userName;
  String? _absenMasukTime;
  String? _absenKeluarTime;
  String _statusHarian = 'Loading status...';

  @override
  void initState() {
    super.initState();
    _loadTodayAttendance();
    _loadUserName();
  }

  void _loadUserName() async {
    final name = await PrefService.getName();
    setState(() {
      userName = name;
    });
  }

  void _loadTodayAttendance() async {
    final email = await PrefService.getEmail();
    final now = DateTime.now();
    String today = DateFormat('yyyy-MM-dd').format(now);

    final db = await DBHelper.initDb();
    final result = await db.query(
      'attendance',
      where: 'date = ? AND user_email = ?',
      whereArgs: [today, email],
    );

    String? masuk;
    String? keluar;
    bool hasIzin = false;

    // looping data hasil query
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

    // menjalankan update state
    setState(() {
      _absenMasukTime = masuk;
      _absenKeluarTime = keluar;
      _statusHarian = status;
    });
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
      appBar: AppBar(
        title: Text(
          'Home Absensi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Card Info Absen dengan desain yang lebih baik
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                shadowColor: Colors.indigo.withOpacity(0.3),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Colors.indigo.shade50],
                    ),
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.calendar_today,
                              color: Colors.indigo,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Absensi Hari Ini',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.indigo,
                                radius: 18,
                                child: Text(
                                  userName?.isNotEmpty == true
                                      ? userName![0].toUpperCase()
                                      : "U",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Halo, ${userName ?? "User"} 👋',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.indigo.shade800,
                                    ),
                                  ),
                                  Text(
                                    DateFormat(
                                      'EEEE, dd MMMM yyyy',
                                    ).format(DateTime.now()),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.indigo.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _statusHarian.contains('belum')
                                  ? Colors.orange.shade50
                                  : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                _statusHarian.contains('belum')
                                    ? Colors.orange.shade300
                                    : Colors.green.shade300,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _statusHarian.contains('belum')
                                    ? Icons.info_outline
                                    : Icons.check_circle_outline,
                                color:
                                    _statusHarian.contains('belum')
                                        ? Colors.orange
                                        : Colors.green,
                              ),
                              SizedBox(width: 8),
                              Text(
                                _statusHarian,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _statusHarian.contains('belum')
                                          ? Colors.orange.shade800
                                          : Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 24, color: Colors.indigo.shade100),
                      _buildAttendanceStatusItem(
                        icon: Icons.login,
                        label: 'Masuk',
                        value: _absenMasukTime ?? 'Belum Absen',
                        isRecorded: _absenMasukTime != null,
                      ),
                      SizedBox(height: 12),
                      _buildAttendanceStatusItem(
                        icon: Icons.logout,
                        label: 'Keluar',
                        value: _absenKeluarTime ?? 'Belum Absen',
                        isRecorded: _absenKeluarTime != null,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),
              // Menu Grid dengan desain yang lebih menarik
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
                      color: Colors.green.shade600,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AbsenMasukLokasiScreen(),
                          ),
                        ).then((value) {
                          _loadTodayAttendance();
                        });
                      },
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.logout,
                      label: 'Absen Keluar',
                      color: Colors.orange.shade600,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AbsenKeluarLokasiScreen(),
                          ),
                        ).then((value) {
                          _loadTodayAttendance();
                        });
                      },
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.history,
                      label: 'Riwayat Absensi',
                      color: Colors.blue.shade600,
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
                      icon: Icons.edit,
                      label: 'Edit Profile',
                      color: Colors.blueGrey.shade600,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(),
                          ),
                        ).then((value) {
                          _loadUserName();
                        });
                      },
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.exit_to_app,
                      label: 'Logout',
                      color: Colors.red.shade600,
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceStatusItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isRecorded,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRecorded ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isRecorded ? Colors.green.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isRecorded ? Colors.green : Colors.grey,
                  size: 16,
                ),
              ),
              SizedBox(width: 12),
              Text(
                '$label:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isRecorded ? Colors.black87 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isRecorded ? FontWeight.w600 : FontWeight.normal,
              color: isRecorded ? Colors.green.shade700 : Colors.grey.shade600,
            ),
          ),
        ],
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: Colors.white),
              ),
              SizedBox(height: 16),
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
