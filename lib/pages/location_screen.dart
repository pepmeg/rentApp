import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/location_service/location_service.dart';
import '../utils/location_service/yandex_geocoder_service.dart';
import '../widgets/location/location_map.dart';
import '../widgets/screen_header.dart';
import '../widgets/search_field.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final YandexGeocoderService _geocoderService = YandexGeocoderService();

  double? _userLat, _userLon;
  double? _selectedLat, _selectedLon;
  bool _showMap = false;
  String? _selectedAddress;

  List<YandexSuggestItem> _suggestions = [];
  bool _isLoading = false;
  int _selectedIndex = -1;
  bool _showSuggestions = false;
  bool _isSelectingSuggestion = false; // 🚀 Флаг для предотвращения повторного поиска

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
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _onSearchChanged(String query) async {
    // 🚀 Игнорируем изменения текста во время выбора подсказки
    if (_isSelectingSuggestion) return;

    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _selectedIndex = -1;
      });
      return;
    }
    setState(() => _isLoading = true);
    try {
      final items = await _geocoderService.getSuggestions(
        query,
        userLat: _userLat,
        userLon: _userLon,
      );
      setState(() {
        _suggestions = items;
        _isLoading = false;
        _showSuggestions = items.isNotEmpty;
        _selectedIndex = -1;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _selectSuggestion(int index) {
    final item = _suggestions[index];

    // 🚀 Устанавливаем флаг ПЕРЕД изменением текста
    _isSelectingSuggestion = true;

    setState(() {
      _suggestions = [];
      _showSuggestions = false;
      _selectedIndex = -1;
      _selectedLat = item.latitude;
      _selectedLon = item.longitude;
      _searchController.text = item.title;
      _selectedAddress = item.title;
      _showMap = true;
    });

    // 🚀 Сбрасываем флаг после следующего кадра
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _isSelectingSuggestion = false;
      }
    });
  }

  void _onMapPointChanged(double lat, double lon) {
    setState(() {
      _selectedLat = lat;
      _selectedLon = lon;
      _selectedAddress = null;
    });
  }

  Future<void> _confirmSelection() async {
    if (_selectedLat == null || _selectedLon == null) return;

    String address = _searchController.text.isNotEmpty
        ? _searchController.text
        : 'Выбранная точка';

    try {
      await setLocaleIdentifier('ru_RU');
      final placemarks = await placemarkFromCoordinates(
        _selectedLat!,
        _selectedLon!,
      );
      if (placemarks.isNotEmpty) {
        address = _formatPlacemark(placemarks.first);
      }
    } catch (_) {
      try {
        final geoAddress = await _geocoderService.getAddressByCoordinates(
          _selectedLat!,
          _selectedLon!,
        );
        if (geoAddress != 'Местоположение не найдено') {
          address = geoAddress;
        }
      } catch (_) {}
    }

    if (!mounted) return;

    _searchController.text = address;
    _selectedAddress = address;

    if (!mounted) return;
    Navigator.pop(context, {
      'latitude': _selectedLat,
      'longitude': _selectedLon,
      'address': address,
    });
  }

  String _formatPlacemark(Placemark place) {
    final parts = <String>[];
    String? region = place.administrativeArea;
    if (region != null && region.isNotEmpty) {
      region = region.replaceAll('область', 'обл.');
      parts.add(region);
    }

    String? city = place.locality;
    if (city != null && city.isNotEmpty) {
      city = city.replaceFirst(RegExp(r'^город\s+', caseSensitive: false), '');
      if (!parts.contains('г. $city')) {
        parts.add('г. $city');
      }
    }

    String? district = place.subAdministrativeArea;
    if (district != null && district.isNotEmpty) {
      final cleanDistrict = district.replaceFirst(
          RegExp(r'^город\s+', caseSensitive: false), '');
      if (cleanDistrict != city && cleanDistrict != region) {
        parts.add(cleanDistrict);
      }
    }

    String street = '';
    if (place.street != null && place.street!.isNotEmpty) {
      street = place.street!;
      street =
          street.replaceFirst(RegExp(r'^ул\.\s*', caseSensitive: false), '');
      street =
          street.replaceFirst(RegExp(r'\s*ул\.\s*$', caseSensitive: false), '');
      street = street.replaceAll(RegExp(r'\bул\.\b', caseSensitive: false), '');
      street = street.trim();
      if (street.isNotEmpty) {
        if (place.subThoroughfare != null &&
            place.subThoroughfare!.isNotEmpty) {
          street += ', ${place.subThoroughfare!}';
        }
        parts.add('ул. $street');
      }
    }

    if (parts.isEmpty) return 'Выбранная точка';
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            color: theme.scaffoldBackgroundColor,
            padding: EdgeInsets.only(top: MediaQuery
                .of(context)
                .padding
                .top),
            child: Column(
              children: [
                const ScreenHeader(
                  title: 'Местоположение',
                  titleSize: 20,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                SearchField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  hintText: 'Поиск адреса',
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  onClear: () {
                    _isSelectingSuggestion = false; // 🚀 Сбрасываем флаг при очистке
                    setState(() {
                      _suggestions = [];
                      _showSuggestions = false;
                      _selectedIndex = -1;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                _showMap && _selectedLat != null && _selectedLon != null
                    ? LocationMapWidget(
                  key: const ValueKey('map'),
                  initialLat: _selectedLat,
                  initialLon: _selectedLon,
                  onPointChanged: (double lat, double lon) {
                    _onMapPointChanged(lat, lon);
                  },
                  onConfirm: _confirmSelection,
                )
                    : Container(key: const ValueKey('empty'),
                    color: theme.scaffoldBackgroundColor),
                if (_showSuggestions && _suggestions.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: theme.scaffoldBackgroundColor,
                      elevation: 4,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _suggestions.length,
                        itemBuilder: (ctx, i) {
                          final item = _suggestions[i];
                          final isSelected = i == _selectedIndex;
                          return InkWell(
                            onTap: () => _selectSuggestion(i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.primaryColor.withOpacity(0.15)
                                    : theme.scaffoldBackgroundColor,
                                border: i < _suggestions.length - 1
                                    ? Border(bottom: BorderSide(
                                    color: theme.dividerColor))
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? theme.primaryColor
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (item.subtitle != null &&
                                      item.subtitle!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        item.subtitle!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
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