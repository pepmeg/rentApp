import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_node.dart';
import '../services/brand_service.dart';
import '../services/category_service.dart';
import '../utils/form_fields.dart';

class CategoryFilterSheet extends StatefulWidget {
  final List<String>? initialCategoryPath;
  final int? initialMinPrice;
  final int? initialMaxPrice;
  final String? initialBrand;
  final String? initialRegion;
  final String? initialCity;
  final String? initialSort;
  final List<String> availableRegions;
  final Map<String, List<String>> regionToCities;
  final Function(List<String>? categoryPath, int? minPrice, int? maxPrice,
      String? brand, String? region, String? city, String? sort) onApply;

  const CategoryFilterSheet({
    super.key,
    this.initialCategoryPath,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialBrand,
    this.initialRegion,
    this.initialCity,
    this.initialSort,
    required this.availableRegions,
    required this.regionToCities,
    required this.onApply,
  });

  @override
  State<CategoryFilterSheet> createState() => _CategoryFilterSheetState();
}

class _CategoryFilterSheetState extends State<CategoryFilterSheet> {
  List<String> _selectedPath = [];
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();
  String? _selectedBrand;
  String? _selectedRegion;
  String? _selectedCity;
  String? _selectedSort;

  String? _minPriceError;
  String? _maxPriceError;

  @override
  void initState() {
    super.initState();
    _selectedPath = List.from(widget.initialCategoryPath ?? []);
    minPriceController.text = widget.initialMinPrice?.toString() ?? '';
    maxPriceController.text = widget.initialMaxPrice?.toString() ?? '';
    _selectedBrand = widget.initialBrand;
    _selectedRegion = widget.initialRegion;
    _selectedCity = widget.initialCity;
    _selectedSort = widget.initialSort;
  }

  @override
  void dispose() {
    minPriceController.dispose();
    maxPriceController.dispose();
    super.dispose();
  }

  void _validatePrices() {
    setState(() {
      _minPriceError = null;
      _maxPriceError = null;
    });

    final minText = minPriceController.text.trim();
    final maxText = maxPriceController.text.trim();
    final minPrice = int.tryParse(minText);
    final maxPrice = int.tryParse(maxText);

    if (minText.isNotEmpty && minPrice == null) {
      _minPriceError = 'Введите число';
    }
    if (maxText.isNotEmpty && maxPrice == null) {
      _maxPriceError = 'Введите число';
    }
    if (minPrice != null && maxPrice != null && minPrice >= maxPrice) {
      _minPriceError = 'Мин. цена не может быть больше макс.';
      _maxPriceError = 'Мин. цена не может быть больше макс.';
    }
  }

  void _apply() {
    _validatePrices();
    if (_minPriceError != null || _maxPriceError != null) {
      return;
    }

    final minText = minPriceController.text.trim();
    final maxText = maxPriceController.text.trim();
    final minPrice = int.tryParse(minText);
    final maxPrice = int.tryParse(maxText);

    widget.onApply(
      _selectedPath.isEmpty ? null : _selectedPath,
      minPrice,
      maxPrice,
      _selectedBrand,
      _selectedRegion,
      _selectedCity,
      _selectedSort,
    );
    Navigator.pop(context);
  }

  void _clearAll() {
    setState(() {
      _selectedPath = [];
      minPriceController.clear();
      maxPriceController.clear();
      _selectedBrand = null;
      _selectedRegion = null;
      _selectedCity = null;
      _selectedSort = null;
      _minPriceError = null;
      _maxPriceError = null;
    });
  }

  void _selectCategory(CategoryNode node, int level) {
    setState(() {
      _selectedPath = _selectedPath.sublist(0, level);
      _selectedPath.add(node.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<CategoryService>();
    final roots = service.rootCategories;
    final brandService = context.watch<BrandService>();
    final brandOptions = ['Все бренды', ...brandService.brands];
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Фильтры',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearAll,
                  style: TextButton.styleFrom(foregroundColor: theme.primaryColor),
                  child: const Text('Сбросить всё', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Сортировка',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSortChip(theme, 'Сначала новые', 'date_desc'),
                _buildSortChip(theme, 'Сначала дешёвые', 'price_asc'),
                _buildSortChip(theme, 'Сначала дорогие', 'price_desc'),
                _buildSortChip(theme, 'По рейтингу', 'rating'),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Column(
                key: ValueKey(_selectedPath.join(',')),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildCategorySelectors(service, roots, theme),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Цена (₽)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: minPriceController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'От',
                          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 16),
                          filled: true,
                          fillColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.5), width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.primaryColor, width: 2),
                          ),
                          errorBorder: _minPriceError != null
                              ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
                          )
                              : null,
                          focusedErrorBorder: _minPriceError != null
                              ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
                          )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      if (_minPriceError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 8),
                          child: Text(
                            _minPriceError!,
                            style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: maxPriceController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'До',
                          hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 16),
                          filled: true,
                          fillColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.5), width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.primaryColor, width: 2),
                          ),
                          errorBorder: _maxPriceError != null
                              ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
                          )
                              : null,
                          focusedErrorBorder: _maxPriceError != null
                              ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
                          )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      if (_maxPriceError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 8),
                          child: Text(
                            _maxPriceError!,
                            style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Бренд',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            AppDropdownMenu(
              key: ValueKey('brand_$_selectedBrand'),
              value: _selectedBrand,
              hint: 'Бренд',
              options: brandOptions,
              onChanged: (v) => setState(() => _selectedBrand = (v == 'Все бренды') ? null : v),
            ),
            const SizedBox(height: 16),
            Text(
              'Регион',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            AppDropdownMenu(
              key: ValueKey('region_$_selectedRegion'),
              value: _selectedRegion,
              hint: 'Регион',
              options: ['Все регионы', ...widget.availableRegions],
              onChanged: (v) => setState(() {
                _selectedRegion = (v == 'Все регионы') ? null : v;
                _selectedCity = null;
              }),
            ),
            if (_selectedRegion != null) ...[
              const SizedBox(height: 16),
              Text(
                'Город',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              AppDropdownMenu(
                key: ValueKey('city_$_selectedCity'),
                value: _selectedCity,
                hint: 'Город',
                options: ['Все города', ...(widget.regionToCities[_selectedRegion] ?? [])],
                onChanged: (v) => setState(() => _selectedCity = (v == 'Все города') ? null : v),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text('Применить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategorySelectors(CategoryService service, List<CategoryNode> roots, ThemeData theme) {
    final List<Widget> widgets = [];
    int level = 0;
    List<CategoryNode> currentNodes = roots;

    while (true) {
      if (currentNodes.isEmpty) break;

      final capturedLevel = level;
      final capturedNodes = List<CategoryNode>.from(currentNodes);

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            level == 0 ? 'Категория' : 'Подкатегория',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
          ),
        ),
      );

      final String keyPath = _selectedPath.take(capturedLevel + 1).join('_');
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppDropdownMenu(
            key: ValueKey('cat_${capturedLevel}_$keyPath'),
            value: level < _selectedPath.length
                ? service.getCategoryById(_selectedPath[level])?.name
                : null,
            hint: '',
            options: capturedNodes.map((c) => c.name).toList(),
            onChanged: (selectedName) {
              if (selectedName == null) return;
              final selected = capturedNodes.firstWhere(
                    (c) => c.name == selectedName,
                orElse: () => throw Exception('Категория "$selectedName" не найдена'),
              );
              _selectCategory(selected, capturedLevel);
            },
          ),
        ),
      );
      if (level < _selectedPath.length) {
        final selectedId = _selectedPath[level];
        final nextChildren = service.getChildren(selectedId);
        if (nextChildren.isEmpty) break;
        currentNodes = nextChildren;
        level++;
      } else {
        break;
      }
    }
    return widgets;
  }

  Widget _buildSortChip(ThemeData theme, String label, String value) {
    final selected = _selectedSort == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (isSelected) {
        setState(() => _selectedSort = isSelected ? value : null);
      },
      selectedColor: theme.primaryColor.withOpacity(0.2),
      backgroundColor: theme.colorScheme.background,
      labelStyle: TextStyle(
        color: selected ? theme.primaryColor : theme.colorScheme.onSurface,
        fontSize: 14,
      ),
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}