import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import '../../utils/colors.dart';
import '../../utils/location_service/location_service.dart';

class LocationMapWidget extends StatefulWidget {
  final double? initialLat;
  final double? initialLon;
  final void Function(double lat, double lon) onPointChanged;
  final VoidCallback? onConfirm;

  const LocationMapWidget({
    super.key,
    this.initialLat,
    this.initialLon,
    required this.onPointChanged,
    this.onConfirm,
  });

  @override
  State<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<LocationMapWidget> {
  late YandexMapController _mapController;
  bool _isMapReady = false;

  double _selectedLat = 55.7558;
  double _selectedLon = 37.6173;

  @override
  void initState() {
    super.initState();
    _selectedLat = widget.initialLat ?? _selectedLat;
    _selectedLon = widget.initialLon ?? _selectedLon;
  }

  @override
  void didUpdateWidget(covariant LocationMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newLat = widget.initialLat;
    final newLon = widget.initialLon;
    if (newLat != null && newLon != null &&
        (newLat != _selectedLat || newLon != _selectedLon)) {
      _selectedLat = newLat;
      _selectedLon = newLon;
      if (_isMapReady) {
        _mapController.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: Point(latitude: _selectedLat, longitude: _selectedLon),
              zoom: 15,
            ),
          ),
        );
      }
    }
  }

  void _onMapCreated(YandexMapController controller) {
    _mapController = controller;
    _isMapReady = true;
    _mapController.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: Point(latitude: _selectedLat, longitude: _selectedLon),
          zoom: 15,
        ),
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      setState(() {
        _selectedLat = pos.latitude;
        _selectedLon = pos.longitude;
      });
      if (_isMapReady) {
        _mapController.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: Point(latitude: _selectedLat, longitude: _selectedLon),
              zoom: 15,
            ),
          ),
        );
      }
      widget.onPointChanged(pos.latitude, pos.longitude);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось определить местоположение: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        YandexMap(
          onMapCreated: _onMapCreated,
          onCameraPositionChanged: (position, reason, finished) {
            setState(() {
              _selectedLat = position.target.latitude;
              _selectedLon = position.target.longitude;
            });
            widget.onPointChanged(position.target.latitude, position.target.longitude);
          },
        ),
        const Center(
          child: Icon(Icons.place, size: 48, color: AppColors.copper),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'location',
            mini: true,
            backgroundColor: AppColors.whiteAntique,
            onPressed: _goToCurrentLocation,
            child: const Icon(Icons.my_location, color: AppColors.oliveGray),
          ),
        ),
        if (widget.onConfirm != null)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: widget.onConfirm,
              icon: const Icon(Icons.check),
              label: const Text('Выбрать'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.copper,
                foregroundColor: AppColors.whiteAntique,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
      ],
    );
  }
}