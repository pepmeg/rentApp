import 'package:flutter/material.dart';

class LocationSearchWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const LocationSearchWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          color: theme.colorScheme.surface,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Поиск адреса',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 16,
              ),
              prefixIcon: Icon(Icons.search, color: theme.primaryColor),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.5)),
                onPressed: onClear,
              )
                  : null,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            ),
          ),
        ),
      ),
    );
  }
}