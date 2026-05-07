import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/location_service/location_service.dart';
import '../utils/location_service/yandex_geocoder_service.dart';
import '../widgets/location/location_map.dart';
import '../widgets/location/location_search.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final YandexGeocoderService _geocoderService =
  YandexGeocoderService('0e18582f-c18f-4f3c-afba-11388e46ba46');

  double? _userLat, _userLon;
  double? _selectedLat, _selectedLon;
  bool _showMap = false;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _initUserLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initUserLocation() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      _userLat = pos.latitude;
      _userLon = pos.longitude;
    } catch (_) {
      _userLat = 55.7558;
      _userLon = 37.6173;
    }
    setState(() {});
  }

  void _onSuggestionSelected(YandexSuggestItem item) {
    setState(() {
      _selectedLat = item.latitude;
      _selectedLon = item.longitude;
      _searchController.text = item.title;
      _selectedAddress = item.title;
      _showMap = true;
    });
  }

  void _onMapPointChanged(double lat, double lon) {
    setState(() {
      _selectedLat = lat;
      _selectedLon = lon;
    });
  }

  Future<void> _confirmSelection() async {
    if (_selectedLat == null || _selectedLon == null) return;
    String address = _searchController.text.isNotEmpty
        ? _searchController.text
        : 'Выбранная точка';
    try {
      final geoAddress = await _geocoderService.getAddressByCoordinates(
        _selectedLat!,
        _selectedLon!,
      );
      if (geoAddress != 'Местоположение не найдено') {
        address = geoAddress;
      }
    } catch (_) {}
    Navigator.pop(context, {
      'latitude': _selectedLat,
      'longitude': _selectedLon,
      'address': address,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.spaceCream,
      body: Column(
        children: [
          Container(
            color: AppColors.spaceCream,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 24, color: AppColors.oliveGray),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Местоположение',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                      ),
                    ],
                  ),
                ),
                LocationSearchWidget(
                  controller: _searchController,
                  onSuggestionSelected: _onSuggestionSelected,
                  userLat: _userLat,
                  userLon: _userLon,
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showMap && _selectedLat != null && _selectedLon != null
                  ? LocationMapWidget(
                key: const ValueKey('map'),
                initialLat: _selectedLat,
                initialLon: _selectedLon,
                onPointChanged: (double lat, double lon) {
                  _onMapPointChanged(lat, lon);
                },
                onConfirm: _confirmSelection,
              )
                  : Container(
                key: const ValueKey('empty'),
                color: AppColors.spaceCream,
              ),
            ),
          ),
        ],
      ),
    );
  }
}