import 'package:absen_sqflite/services/pref_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/attendance_model.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Attendance> _listAttendance = [];
  Map<String, List<Attendance>> _groupedAttendance = {};

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd-MMMM-yyyy').format(date);
    } catch (e) {
      return dateString; // fallback kalau parsing gagal
    }
  }

  void _loadAttendance() async {
    final email = await PrefService.getEmail(); // ambil email user yang login
    if (email == null) return;

    _listAttendance = await DBHelper.getAllAttendanceByEmail(
      email,
    ); // kirim email ke sini

    // Grouping data by date
    _groupedAttendance.clear();
    for (var att in _listAttendance) {
      if (_groupedAttendance.containsKey(att.date)) {
        _groupedAttendance[att.date]!.add(att);
      } else {
        _groupedAttendance[att.date] = [att];
      }
    }

    setState(() {});
  }

  void _deleteAttendance(int id) async {
    await DBHelper.deleteAttendance(id);
    _loadAttendance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Riwayat Absensi')),
      body:
          _groupedAttendance.isEmpty
              ? Center(child: Text('Belum ada data absensi'))
              : ListView.builder(
                itemCount: _groupedAttendance.keys.length,
                itemBuilder: (context, index) {
                  String date = _groupedAttendance.keys.elementAt(index);
                  List<Attendance> attendances = _groupedAttendance[date]!;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8,
                    ),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                _formatDate(date),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            SizedBox(height: 12),
                            Column(
                              children:
                                  attendances.map((att) {
                                    return ListTile(
                                      leading: Icon(
                                        att.type == 'Masuk'
                                            ? Icons.login
                                            : att.type == 'Keluar'
                                            ? Icons.logout
                                            : Icons
                                                .assignment_turned_in, // <-- icon izin
                                        color:
                                            att.type == 'Masuk'
                                                ? Colors.green
                                                : att.type == 'Keluar'
                                                ? Colors.orange
                                                : Colors
                                                    .blueGrey, // <-- warna izin
                                      ),
                                      title: Text(
                                        att.type,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              att.type == 'Masuk'
                                                  ? Colors.green
                                                  : att.type == 'Keluar'
                                                  ? Colors.orange
                                                  : Colors.blueGrey,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: 4),
                                          Text('Jam: ${att.time}'),
                                          if (att.address != null &&
                                              att.address!.isNotEmpty) ...[
                                            SizedBox(height: 4),
                                            Text(
                                              'Lokasi: ${att.address}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                          if (att.type == 'Izin' &&
                                              att.reason != null) ...[
                                            SizedBox(height: 4),
                                            Text('Alasan: ${att.reason!}'),
                                          ],
                                        ],
                                      ),

                                      trailing: IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed:
                                            () => _showDeleteConfirmation(
                                              context,
                                              att.id!,
                                            ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int id) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Konfirmasi Hapus'),
            content: Text('Yakin ingin menghapus data ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  _deleteAttendance(id);
                  Navigator.pop(context);
                },
                child: Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
