import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/location_service/yandex_geocoder_service.dart';

class LocationSearchWidget extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<YandexSuggestItem> onSuggestionSelected;
  final double? userLat;
  final double? userLon;

  const LocationSearchWidget({
    super.key,
    required this.controller,
    required this.onSuggestionSelected,
    this.userLat,
    this.userLon,
  });

  @override
  State<LocationSearchWidget> createState() => _LocationSearchWidgetState();
}

class _LocationSearchWidgetState extends State<LocationSearchWidget> {
  final YandexGeocoderService _geocoderService =
  YandexGeocoderService('0e18582f-c18f-4f3c-afba-11388e46ba46');
  List<YandexSuggestItem> _suggestions = [];
  bool _isLoading = false;
  int _selectedIndex = -1;
  bool _showSuggestions = false;

  Future<void> _onSearchChanged(String query) async {
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
        userLat: widget.userLat,
        userLon: widget.userLon,
      );
      setState(() {
        _suggestions = items;
        _isLoading = false;
        _showSuggestions = items.isNotEmpty;
        _selectedIndex = -1;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  void _selectSuggestion(int index) {
    final item = _suggestions[index];
    setState(() {
      _selectedIndex = index;
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      widget.onSuggestionSelected(item);
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _selectedIndex = -1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // важно: не растягиваться без нужды
      children: [
        // Поисковая строка
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              controller: widget.controller,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 16, color: AppColors.oliveGray),
              decoration: InputDecoration(
                hintText: 'Поиск адреса',
                hintStyle: TextStyle(
                    color: AppColors.oliveGray.withOpacity(0.5), fontSize: 16),
                prefixIcon: Icon(Icons.search, color: AppColors.copper),
                suffixIcon: widget.controller.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      color: AppColors.oliveGray.withOpacity(0.5)),
                  onPressed: () {
                    widget.controller.clear();
                    setState(() {
                      _suggestions = [];
                      _showSuggestions = false;
                    });
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
            ),
          ),
        ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: Material(
              color: AppColors.spaceCream,
              elevation: 4,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: ListView.builder(
                  key: ValueKey(_suggestions.length),
                  padding: EdgeInsets.zero,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final item = _suggestions[index];
                    final isSelected = index == _selectedIndex;
                    final showDivider = index < _suggestions.length - 1;
                    return InkWell(
                      onTap: () => _selectSuggestion(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.copper.withOpacity(0.15)
                              : AppColors.spaceCream,
                          border: showDivider
                              ? Border(
                              bottom: BorderSide(
                                  color: AppColors.oliveGray
                                      .withOpacity(0.08)))
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
                                    ? AppColors.copper
                                    : AppColors.oliveGray,
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
                                    color:
                                    AppColors.oliveGray.withOpacity(0.7),
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
          ),
      ],
    );
  }
}