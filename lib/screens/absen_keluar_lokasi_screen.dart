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
  bool _isLoading = false;
  String _currentAddress = 'Memuat alamat...';
  double? _distance;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        setState(() {
          _isLoading = false;
          _currentAddress = 'Layanan lokasi tidak aktif';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _currentAddress = 'Izin lokasi ditolak';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _currentAddress = 'Izin lokasi ditolak secara permanen';
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        kantorLocation.latitude,
        kantorLocation.longitude,
      );

      String address = await _getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentPosition = position;
        _distance = distance;
        _isInRadius = distance <= allowedRadius;
        _currentAddress = address;
        _isLoading = false;
      });

      // Pindahkan kamera ke posisi pengguna
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          18,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentAddress = 'Gagal mendapatkan lokasi: $e';
      });
    }
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        return "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}";
      }
    } catch (e) {
      debugPrint('Gagal ambil alamat: $e');
    }
    return 'Alamat tidak ditemukan';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absen Keluar via Lokasi'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocation,
            tooltip: 'Perbarui Lokasi',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Mendapatkan lokasi Anda...'),
                  ],
                ),
              )
              : Column(
                children: [
                  // Status lokasi
                  Container(
                    color:
                        _isInRadius ? Colors.green.shade50 : Colors.red.shade50,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          _isInRadius ? Icons.check_circle : Icons.error,
                          color: _isInRadius ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isInRadius
                                    ? 'Anda berada dalam radius kantor'
                                    : 'Anda berada di luar radius kantor',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _isInRadius ? Colors.green : Colors.red,
                                ),
                              ),
                              if (_distance != null)
                                Text(
                                  'Jarak: ${_distance!.toStringAsFixed(1)} meter dari kantor',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              Text(
                                _currentAddress,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Peta Google Maps
                  Expanded(
                    child:
                        _currentPosition == null
                            ? const Center(child: Text('Lokasi tidak tersedia'))
                            : GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                zoom: 18,
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
                                  infoWindow: const InfoWindow(
                                    title: 'Posisi Anda',
                                  ),
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
                                  fillColor: Colors.green.withOpacity(0.2),
                                  strokeColor: Colors.green,
                                  strokeWidth: 2,
                                ),
                              },
                              myLocationEnabled: true,
                              compassEnabled: true,
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                              onMapCreated:
                                  (controller) => _mapController = controller,
                            ),
                  ),

                  // Button absen
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: ElevatedButton(
                        onPressed:
                            _isInRadius
                                ? () async {
                                  setState(() => _isLoading = true);
                                  try {
                                    await AbsenServices.absenKeluar(context);
                                    if (context.mounted) Navigator.pop(context);
                                  } finally {
                                    if (mounted)
                                      setState(() => _isLoading = false);
                                  }
                                }
                                : null,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              _isInRadius
                                  ? Colors.orange
                                  : Colors.grey.shade400,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: _isInRadius ? 2 : 0,
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.logout),
                                    SizedBox(width: 8),
                                    Text(
                                      'Absen Keluar Sekarang',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
