import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../data/category.dart';

class CategoryFilterBar extends StatefulWidget {
  final Function(String? category, String? subcategory) onFilterChanged;

  const CategoryFilterBar({required this.onFilterChanged, super.key});

  @override
  State<CategoryFilterBar> createState() => _CategoryFilterBarState();
}

class _CategoryFilterBarState extends State<CategoryFilterBar> {
  String? selectedCategory;
  String? selectedSubcategory;

  void _clearCategory() {
    setState(() {
      selectedCategory = null;
      selectedSubcategory = null;
    });
    widget.onFilterChanged(null, null);
  }

  void _clearSubcategory() {
    setState(() {
      selectedSubcategory = null;
    });
    widget.onFilterChanged(selectedCategory, null);
  }

  void _selectCategory(String category) {
    setState(() {
      selectedCategory = category;
      selectedSubcategory = null;
    });
    widget.onFilterChanged(category, null);
  }

  void _selectSubcategory(String subcategory) {
    setState(() {
      selectedSubcategory = subcategory;
    });
    widget.onFilterChanged(selectedCategory, subcategory);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _buildChips(),
      ),
    );
  }

  List<Widget> _buildChips() {
    if (selectedSubcategory != null && selectedCategory != null) {
      return [
        _buildChip(
          label: selectedCategory!,
          onDeleted: _clearCategory,
        ),
        _buildChip(
          label: selectedSubcategory!,
          onDeleted: _clearSubcategory,
        ),
      ];
    }

    if (selectedCategory != null) {
      final category = categories.firstWhere((c) => c.name == selectedCategory);
      return [
        _buildChip(
          label: selectedCategory!,
          onDeleted: _clearCategory,
        ),
        const SizedBox(width: 8),
        ...category.subcategories.map((sub) => _buildChip(
          label: sub,
          onTap: () => _selectSubcategory(sub),
        )),
      ];
    }

    return categories.map((cat) => _buildChip(
      label: cat.name,
      onTap: () => _selectCategory(cat.name),
    )).toList();
  }

  Widget _buildChip({
    required String label,
    VoidCallback? onDeleted,
    VoidCallback? onTap,
  }) {
    final hasAction = onDeleted != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: hasAction
            ? GestureDetector(
          onTap: onDeleted,
          child: const Icon(Icons.close, size: 16, color: AppColors.oliveGray),
        )
            : const SizedBox.shrink(),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightGreen,
          foregroundColor: AppColors.oliveGray,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}