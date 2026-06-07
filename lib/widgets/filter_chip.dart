import 'package:flutter/material.dart';

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final EdgeInsets margin;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        child: Chip(
          label: Text(label),
          backgroundColor: isSelected
              ? theme.primaryColor.withOpacity(0.1)
              : (theme.cardTheme.color ?? theme.colorScheme.surface),
          labelStyle: TextStyle(
            color: isSelected ? theme.primaryColor : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}