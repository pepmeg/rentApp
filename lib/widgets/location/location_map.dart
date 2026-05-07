import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import '../../utils/colors.dart';
import '../../utils/location_service/location_service.dart';
import '../../utils/location_service/yandex_geocoder_service.dart';

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
  Point? _selectedPoint;
  bool _isMapReady = false;
  final YandexGeocoderService _geocoderService =
  YandexGeocoderService('0e18582f-c18f-4f3c-afba-11388e46ba46');

  double _selectedLat = 55.7558;
  double _selectedLon = 37.6173;

  @override
  void initState() {
    super.initState();
    _selectedLat = widget.initialLat ?? 55.7558;
    _selectedLon = widget.initialLon ?? 37.6173;
    _selectedPoint = Point(latitude: _selectedLat, longitude: _selectedLon);
  }

  @override
  void didUpdateWidget(covariant LocationMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newLat = widget.initialLat ?? _selectedLat;
    final newLon = widget.initialLon ?? _selectedLon;
    if (newLat != _selectedLat || newLon != _selectedLon) {
      _selectedLat = newLat;
      _selectedLon = newLon;
      _selectedPoint = Point(latitude: _selectedLat, longitude: _selectedLon);
      _moveToPoint(_selectedPoint!);
    }
  }

  void _onMapCreated(YandexMapController controller) {
    _mapController = controller;
    if (_selectedPoint != null) {
      _moveToPoint(_selectedPoint!);
    }
    setState(() => _isMapReady = true);
  }

  void _moveToPoint(Point point) {
    if (!_isMapReady) return;
    _mapController.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: point, zoom: 15),
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      final point = Point(latitude: pos.latitude, longitude: pos.longitude);
      setState(() {
        _selectedPoint = point;
        _selectedLat = pos.latitude;
        _selectedLon = pos.longitude;
      });
      widget.onPointChanged(pos.latitude, pos.longitude);
      _moveToPoint(point);
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
              _selectedPoint = position.target;
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