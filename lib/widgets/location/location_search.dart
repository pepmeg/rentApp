import 'package:flutter/material.dart';
import '../../utils/colors.dart';

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.lightGreen,
          borderRadius: BorderRadius.circular(30),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 16, color: AppColors.oliveGray),
          decoration: InputDecoration(
            hintText: 'Поиск адреса',
            hintStyle: TextStyle(
                color: AppColors.oliveGray.withOpacity(0.5), fontSize: 16),
            prefixIcon: Icon(Icons.search, color: AppColors.copper),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear_rounded,
                  color: AppColors.oliveGray.withOpacity(0.5)),
              onPressed: onClear,
            )
                : null,
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),
      ),
    );
  }
}