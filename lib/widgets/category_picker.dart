import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_node.dart';
import '../services/category_service.dart';
import '../utils/form_fields.dart';

class CategoryPicker extends StatefulWidget {
  final List<String>? initialPath;
  final ValueChanged<List<String>> onPathChanged;

  const CategoryPicker({
    super.key,
    this.initialPath,
    required this.onPathChanged,
  });

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  List<CategoryNode> _selectedNodes = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialPath != null && widget.initialPath!.isNotEmpty) {
      _restorePath();
    }
  }

  @override
  void didUpdateWidget(covariant CategoryPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.initialPath, widget.initialPath)) {
      if (widget.initialPath == null || widget.initialPath!.isEmpty) {
        setState(() {
          _selectedNodes = [];
        });
      } else {
        _restorePath();
      }
    }
  }

  Future<void> _restorePath() async {
    final service = context.read<CategoryService>();
    final path = widget.initialPath!;
    final nodes = <CategoryNode>[];

    for (final id in path) {
      final node = service.getCategoryById(id);
      if (node != null) {
        nodes.add(node);
      } else {
        break;
      }
    }

    final resolvedPath = nodes.map((n) => n.id).toList();
    if (!mounted) return;

    if (!listEquals(resolvedPath, _selectedNodes.map((n) => n.id).toList())) {
      setState(() {
        _selectedNodes = nodes;
      });
    }

    if (!listEquals(resolvedPath, path)) {
      widget.onPathChanged(resolvedPath);
    }
  }

  void _selectCategory(CategoryNode node, int level) {
    final newNodes = _selectedNodes.sublist(0, level)..add(node);
    final newPath = newNodes.map((n) => n.id).toList();
    final oldPath = _selectedNodes.map((n) => n.id).toList();

    if (!listEquals(newPath, oldPath)) {
      setState(() {
        _selectedNodes = newNodes;
      });
      widget.onPathChanged(newPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<CategoryService>();
    final roots = service.rootCategories;

    final levels = <Widget>[];
    for (int i = 0; i <= _selectedNodes.length; i++) {
      final parentId = i == 0 ? null : _selectedNodes[i - 1].id;
      final children = parentId == null ? roots : service.getChildren(parentId);

      if (children.isEmpty && i == _selectedNodes.length) break;

      final currentValue = i < _selectedNodes.length ? _selectedNodes[i] : null;

      levels.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppDropdownMenu(
            key: ValueKey('cat_${i}_${parentId ?? 'root'}'),
            value: currentValue?.name,
            hint: i == 0 ? 'Выберите категорию' : 'Выберите подкатегорию',
            options: children.map((c) => c.name).toList(),
            onChanged: (selectedName) {
              if (selectedName == null) return;
              final selected = children.firstWhere((c) => c.name == selectedName);
              _selectCategory(selected, i);
            },
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: levels,
    );
  }
}