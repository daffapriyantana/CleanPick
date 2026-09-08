import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class PickedLocation {
  final double latitude;
  final double longitude;
  final String address;

  const PickedLocation(
      {required this.latitude, required this.longitude, required this.address});
}

class LocationPickerPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  const LocationPickerPage(
      {super.key, this.initialLatitude, this.initialLongitude});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;
  late LatLng _selectedPoint;
  String _address = 'Geser peta dan letakkan pin di lokasi pickup';
  bool _loadingAddress = false;
  bool _followCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    _selectedPoint = LatLng(
      widget.initialLatitude ?? kCleanPickDepotLatitude,
      widget.initialLongitude ?? kCleanPickDepotLongitude,
    );
    _reverseGeocode(_selectedPoint);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleCurrentLocation() async {
    if (_followCurrentLocation) {
      await _positionSubscription?.cancel();
      setState(() => _followCurrentLocation = false);
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi diperlukan')));
      }
      return;
    }
    setState(() => _followCurrentLocation = true);
    final current = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    final currentPoint = LatLng(current.latitude, current.longitude);
    setState(() => _selectedPoint = currentPoint);
    _mapController.move(currentPoint, 17);
    _reverseGeocode(currentPoint);
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((position) {
      final point = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _selectedPoint = point);
      _mapController.move(point, 17);
      _reverseGeocode(point);
    });
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _loadingAddress = true);
    try {
      final places =
          await placemarkFromCoordinates(point.latitude, point.longitude);
      if (!mounted) return;
      if (places.isNotEmpty) {
        final place = places.first;
        final parts = [
          place.street,
          place.subLocality,
          place.locality,
          place.postalCode,
        ]
            .where((part) => part != null && part.trim().isNotEmpty)
            .map((part) => part!.trim())
            .toList();
        setState(() => _address = parts.join(', '));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _address = 'Alamat belum ditemukan, silakan isi manual');
      }
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Titik Pickup')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedPoint,
                initialZoom: 15,
                onTap: (_, point) {
                  setState(() => _selectedPoint = point);
                  _reverseGeocode(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.cleanpick.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint,
                      width: 48,
                      height: 48,
                      child: const Icon(Icons.location_pin,
                          color: AppColors.error, size: 44),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Lokasi Pickup',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: AppColors.primary, size: 19),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(
                            _loadingAddress ? 'Mencari alamat...' : _address,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary))),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _toggleCurrentLocation,
                  icon: Icon(_followCurrentLocation
                      ? Icons.location_disabled
                      : Icons.my_location),
                  label: Text(_followCurrentLocation
                      ? 'Hentikan Lokasi Realtime'
                      : 'Gunakan Lokasi Saat Ini Realtime'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadingAddress
                      ? null
                      : () => Navigator.of(context).pop(PickedLocation(
                          latitude: _selectedPoint.latitude,
                          longitude: _selectedPoint.longitude,
                          address: _address)),
                  child: const Text('Gunakan Lokasi Ini'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
