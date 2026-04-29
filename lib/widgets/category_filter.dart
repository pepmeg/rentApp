import 'package:flutter/material.dart';
import '../data/product_data.dart';
import '../data/category.dart';
import '../models/product.dart';
import '../utils/colors.dart';
import '../utils/form_fields.dart';

class CategoryFilterSheet extends StatefulWidget {
  final String? initialCategory;
  final String? initialSubcategory;
  final int? initialMinPrice;
  final int? initialMaxPrice;
  final String? initialBrand;
  final String? initialRegion;
  final String? initialCity;
  final String? initialSort;
  final Function(String? category, String? subcategory, int? minPrice, int? maxPrice,
      String? brand, String? region, String? city, String? sort) onApply;

  const CategoryFilterSheet({
    super.key,
    this.initialCategory,
    this.initialSubcategory,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialBrand,
    this.initialRegion,
    this.initialCity,
    this.initialSort,
    required this.onApply,
  });

  @override
  State<CategoryFilterSheet> createState() => _CategoryFilterSheetState();
}

class _CategoryFilterSheetState extends State<CategoryFilterSheet> {
  late String? selectedCategory;
  late String? selectedSubcategory;
  final TextEditingController minPriceController = TextEditingController();
  final TextEditingController maxPriceController = TextEditingController();
  late String? selectedBrand;
  late String? selectedRegion;
  late String? selectedCity;
  late String? selectedSort;

  String? _minPriceError;
  String? _maxPriceError;

  List<Product> get allProducts => ProductData.getAllProducts();

  List<String> get brandOptions {
    final brands = allProducts
        .map((p) => p.brand)
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return brands;
  }

  List<String> get regionOptions {
    final regions = allProducts
        .map((p) => p.region)
        .where((r) => r.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return regions;
  }

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
    selectedSubcategory = widget.initialSubcategory;
    minPriceController.text = widget.initialMinPrice?.toString() ?? '';
    maxPriceController.text = widget.initialMaxPrice?.toString() ?? '';
    selectedBrand = widget.initialBrand;
    selectedRegion = widget.initialRegion;
    selectedCity = widget.initialCity;
    selectedSort = widget.initialSort;
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
      selectedCategory,
      selectedSubcategory,
      minPrice,
      maxPrice,
      selectedBrand,
      selectedRegion,
      selectedCity,
      selectedSort,
    );
    Navigator.pop(context);
  }

  void _clearAll() {
    setState(() {
      selectedCategory = null;
      selectedSubcategory = null;
      minPriceController.clear();
      maxPriceController.clear();
      selectedBrand = null;
      selectedRegion = null;
      selectedCity = null;
      selectedSort = null;
      _minPriceError = null;
      _maxPriceError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
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
                const Text('Фильтры',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.oliveGray)),
                const Spacer(),
                TextButton(
                  onPressed: _clearAll,
                  style: TextButton.styleFrom(foregroundColor: AppColors.copper),
                  child: const Text('Сбросить всё',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Сортировка',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.oliveGray)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSortChip('Сначала новые', 'date_desc'),
                _buildSortChip('Сначала дешёвые', 'price_asc'),
                _buildSortChip('Сначала дорогие', 'price_desc'),
                _buildSortChip('По рейтингу', 'rating'),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Категория',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.oliveGray)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = selectedCategory == cat.name;
                return ChoiceChip(
                  label: Text(cat.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedCategory = selected ? cat.name : null;
                      selectedSubcategory = null;
                    });
                  },
                  selectedColor: AppColors.copper.withOpacity(0.2),
                  backgroundColor: AppColors.spaceCream,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.copper : AppColors.oliveGray,
                    fontSize: 14,
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              }).toList(),
            ),
            if (selectedCategory != null) ...[
              const SizedBox(height: 16),
              const Text('Подкатегория',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.oliveGray)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: categories
                    .firstWhere((c) => c.name == selectedCategory)
                    .subcategories
                    .map((sub) {
                  final isSelected = selectedSubcategory == sub;
                  return ChoiceChip(
                    label: Text(sub),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => selectedSubcategory = selected ? sub : null);
                    },
                    selectedColor: AppColors.copper.withOpacity(0.2),
                    backgroundColor: AppColors.spaceCream,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.copper : AppColors.oliveGray,
                      fontSize: 14,
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Цена (₽)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.oliveGray)),
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
                        style: TextStyle(color: AppColors.oliveGray, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'От',
                          hintStyle: TextStyle(color: AppColors.oliveGray.withOpacity(0.5), fontSize: 16),
                          filled: true,
                          fillColor: AppColors.whiteAntique,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.oliveGray.withOpacity(0.5), width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.copper.withOpacity(0.7), width: 2),
                          ),
                          errorBorder: _minPriceError != null
                              ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.copper, width: 2),
                          )
                              : null,
                          focusedErrorBorder: _minPriceError != null
                              ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.copper, width: 2),
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
                            style: const TextStyle(color: AppColors.copper, fontSize: 12),
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
                        style: TextStyle(color: AppColors.oliveGray, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'До',
                          hintStyle: TextStyle(color: AppColors.oliveGray.withOpacity(0.5), fontSize: 16),
                          filled: true,
                          fillColor: AppColors.whiteAntique,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.oliveGray.withOpacity(0.5), width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.copper.withOpacity(0.7), width: 2),
                          ),
                          errorBorder: _maxPriceError != null
                              ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.copper, width: 2),
                          )
                              : null,
                          focusedErrorBorder: _maxPriceError != null
                              ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.copper, width: 2),
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
                            style: const TextStyle(color: AppColors.copper, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Бренд',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.oliveGray)),
            const SizedBox(height: 8),
            AppDropdownMenu(
              key: ValueKey('brand_$selectedBrand'),
              value: selectedBrand,
              hint: 'Бренд',
              options: ['Все бренды', ...brandOptions],
              onChanged: (v) => setState(() => selectedBrand = (v == 'Все бренды') ? null : v),
            ),
            const SizedBox(height: 16),
            const Text('Регион',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.oliveGray)),
            const SizedBox(height: 8),
            AppDropdownMenu(
              key: ValueKey('region_$selectedRegion'),
              value: selectedRegion,
              hint: 'Регион',
              options: ['Все регионы', ...regionOptions],
              onChanged: (v) => setState(() {
                selectedRegion = (v == 'Все регионы') ? null : v;
                selectedCity = null;
              }),
            ),
            if (selectedRegion != null) ...[
              const SizedBox(height: 16),
              const Text('Город',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.oliveGray)),
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final cities = allProducts
                    .where((p) => p.region == selectedRegion)
                    .map((p) => p.city)
                    .where((c) => c.isNotEmpty)
                    .toSet()
                    .toList()
                  ..sort();
                return AppDropdownMenu(
                  key: ValueKey('city_$selectedCity'),
                  value: selectedCity,
                  hint: 'Город',
                  options: ['Все города', ...cities],
                  onChanged: (v) => setState(() => selectedCity = (v == 'Все города') ? null : v),
                );
              }),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.copper,
                  foregroundColor: AppColors.whiteAntique,
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

  Widget _buildSortChip(String label, String value) {
    final selected = selectedSort == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (isSelected) {
        setState(() => selectedSort = isSelected ? value : null);
      },
      selectedColor: AppColors.copper.withOpacity(0.2),
      backgroundColor: AppColors.spaceCream,
      labelStyle: TextStyle(
        color: selected ? AppColors.copper : AppColors.oliveGray,
        fontSize: 14,
      ),
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}