import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/absen_services.dart';

class AbsenKeluarLokasiScreen extends StatefulWidget {
  const AbsenKeluarLokasiScreen({super.key});

  @override
  State<AbsenKeluarLokasiScreen> createState() =>
      _AbsenKeluarLokasiScreenState();
}

class _AbsenKeluarLokasiScreenState extends State<AbsenKeluarLokasiScreen> {
  final LatLng kantorLocation = const LatLng(
    -6.21090,
    106.812946,
  ); // Lokasi kantor
  static const double allowedRadius = 20; // meter
  Position? _currentPosition;
  GoogleMapController? _mapController;
  bool _isInRadius = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
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

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
      _isInRadius =
          Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            kantorLocation.latitude,
            kantorLocation.longitude,
          ) <=
          allowedRadius;
    });
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    final address = await _getAddressFromLatLng(lat, lng);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        return "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}";
      }
    } catch (e) {
      print('Gagal ambil alamat: $e');
    }
    return 'Alamat tidak ditemukan';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Absen Keluar via Lokasi')),
      body:
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: kantorLocation,
                        zoom: 20,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('kantor'),
                          position: kantorLocation,
                          infoWindow: const InfoWindow(
                            title: 'Titik Lokasi Kantor',
                          ),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                        Marker(
                          markerId: const MarkerId('user'),
                          position: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          infoWindow: const InfoWindow(title: 'Posisi Kamu'),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure,
                          ),
                        ),
                      },
                      circles: {
                        Circle(
                          circleId: const CircleId('radius'),
                          center: kantorLocation,
                          radius: allowedRadius,
                          fillColor: Colors.green.withOpacity(0.3),
                          strokeColor: Colors.green,
                          strokeWidth: 2,
                        ),
                      },
                      onMapCreated: (controller) => _mapController = controller,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Absen Keluar Sekarang'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor:
                            _isInRadius ? Colors.orange : Colors.grey,
                      ),
                      onPressed:
                          _isInRadius
                              ? () async {
                                await AbsenServices.absenKeluar(context);
                                if (context.mounted) Navigator.pop(context);
                              }
                              : null,
                    ),
                  ),
                ],
              ),
    );
  }
}
