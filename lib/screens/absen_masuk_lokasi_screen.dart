import 'package:absen_sqflite/services/absen_services.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../models/attendance_model.dart';
import '../services/pref_services.dart';

class AbsenMasukLokasiScreen extends StatefulWidget {
  const AbsenMasukLokasiScreen({Key? key}) : super(key: key);

  @override
  State<AbsenMasukLokasiScreen> createState() => _AbsenMasukLokasiScreenState();
}

class _AbsenMasukLokasiScreenState extends State<AbsenMasukLokasiScreen> {
  GoogleMapController? _mapController; //Controller Google Maps
  Position? _currentPosition; // Lokasi GPS user saat ini
  final LatLng kantorLocation = const LatLng(
    -6.21090,
    106.812946,
  ); // Titik lokasi kantor
  bool isInsideRadius = false; //Apakah user di dalam radius kantor?
  double distance = 0.0; //Jarak user ke kantor
  static const double allowedRadius = 15; // Radius area absensi dalam meter
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    double jarak = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      kantorLocation.latitude,
      kantorLocation.longitude,
    );

    setState(() {
      _currentPosition = position;
      distance = jarak;
      isInsideRadius = jarak <= allowedRadius;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Absen Masuk via Lokasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _getCurrentLocation,
            tooltip: 'Refresh Lokasi',
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.indigo),
                    SizedBox(height: 16),
                    Text(
                      'Mendapatkan lokasi...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.indigo,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Status Bar
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color:
                          isInsideRadius
                              ? Colors.green.shade500
                              : Colors.orange.shade500,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isInsideRadius
                            ? 'Anda berada dalam radius kantor ✅'
                            : 'Anda berada di luar radius kantor ⚠️',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  // Map
                  Expanded(
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: kantorLocation,
                            zoom: 20,
                          ),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: true,
                          mapToolbarEnabled: true,
                          markers: {
                            Marker(
                              markerId: const MarkerId('kantor'),
                              position: kantorLocation,
                              infoWindow: const InfoWindow(
                                title: 'Titik Lokasi Kantor',
                                snippet: 'Area untuk absen',
                              ),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed,
                              ), // kantor = merah
                            ),
                            Marker(
                              markerId: const MarkerId('user'),
                              position: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              infoWindow: const InfoWindow(
                                title: 'Posisi Anda',
                                snippet: 'Lokasi Anda saat ini',
                              ),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueAzure,
                              ), // user = biru muda
                            ),
                          },
                          circles: {
                            Circle(
                              circleId: const CircleId('radius'),
                              center: kantorLocation,
                              radius: allowedRadius, // radius dalam meter
                              fillColor: Colors.green.withOpacity(0.3),
                              strokeColor: Colors.green,
                              strokeWidth: 2,
                            ),
                          },
                          onMapCreated:
                              (controller) => _mapController = controller,
                        ),

                        // Legend di pojok kanan atas
                        Positioned(
                          top: 60,
                          right: 16,
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Lokasi Kantor',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Posisi Anda',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.green,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Area Absensi',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Panel
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Jarak ke kantor dengan indikator visual
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    isInsideRadius
                                        ? Colors.green.shade100
                                        : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isInsideRadius
                                    ? Icons.location_on
                                    : Icons.wrong_location,
                                color:
                                    isInsideRadius
                                        ? Colors.green
                                        : Colors.orange,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Jarak ke kantor:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '${distance.toStringAsFixed(1)} meter',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isInsideRadius
                                              ? Colors.green.shade700
                                              : Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Indikator status
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isInsideRadius
                                        ? Colors.green.shade100
                                        : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      isInsideRadius
                                          ? Colors.green
                                          : Colors.orange,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                isInsideRadius ? 'Di dalam' : 'Di luar',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isInsideRadius
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // Informasi absensi
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.indigo.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.indigo),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Radius absensi masuk adalah ${allowedRadius.toInt()} meter dari lokasi kantor.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.indigo.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24),

                        // Tombol absen
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            icon: Icon(
                              isInsideRadius
                                  ? Icons.check_circle
                                  : Icons.warning_rounded,
                              size: 24,
                            ),
                            label: Text(
                              'Absen Masuk Sekarang',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed:
                                isInsideRadius
                                    ? () async {
                                      setState(() {
                                        _isLoading = true;
                                      });

                                      await AbsenServices.absenMasuk(context);

                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    }
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isInsideRadius
                                      ? Colors.green
                                      : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                              elevation: isInsideRadius ? 4 : 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),

                        if (!isInsideRadius)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Anda harus berada dalam radius kantor untuk absen masuk',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red.shade700,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
