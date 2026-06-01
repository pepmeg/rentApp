import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_node.dart';
import '../services/category_service.dart';

class CategoryFilterBar extends StatefulWidget {
  final Function(List<String>? categoryPath) onFilterChanged;

  const CategoryFilterBar({required this.onFilterChanged, super.key});

  @override
  State<CategoryFilterBar> createState() => _CategoryFilterBarState();
}

class _CategoryFilterBarState extends State<CategoryFilterBar> {
  List<String> _selectedPath = [];

  void _clearFilter() {
    setState(() => _selectedPath = []);
    widget.onFilterChanged(null);
  }

  void _selectCategory(CategoryNode node, int level) {
    setState(() {
      _selectedPath = _selectedPath.sublist(0, level);
      _selectedPath.add(node.id);
    });
    widget.onFilterChanged(_selectedPath);
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<CategoryService>();
    final roots = service.rootCategories;
    final theme = Theme.of(context);

    List<Widget> chips = [];

    if (_selectedPath.isNotEmpty) {
      for (int i = 0; i < _selectedPath.length; i++) {
        final node = service.getCategoryById(_selectedPath[i]);
        if (node == null) continue;
        chips.add(
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Chip(
              label: Text(node.name),
              onDeleted: () {
                setState(() {
                  _selectedPath = _selectedPath.sublist(0, i);
                });
                widget.onFilterChanged(_selectedPath.isEmpty ? null : _selectedPath);
              },
              deleteIcon: Icon(Icons.close, size: 16, color: theme.colorScheme.onSurface),
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              labelStyle: TextStyle(color: theme.colorScheme.onSurface),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        );
      }
    } else {
      for (var root in roots) {
        chips.add(
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(root.name),
              selected: false,
              onSelected: (_) => _selectCategory(root, 0),
              selectedColor: theme.primaryColor,
              backgroundColor: theme.primaryColor.withOpacity(0.1),
              labelStyle: TextStyle(color: theme.colorScheme.onSurface),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        );
      }
    }
    if (_selectedPath.isNotEmpty) {
      final parentId = _selectedPath.last;
      final children = service.getChildren(parentId);
      if (children.isNotEmpty) {
        for (var child in children) {
          chips.add(
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(child.name),
                selected: false,
                onSelected: (_) => _selectCategory(child, _selectedPath.length),
                selectedColor: theme.primaryColor,
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                labelStyle: TextStyle(color: theme.colorScheme.onSurface),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          );
        }
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: chips),
    );
  }
}