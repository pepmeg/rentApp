import 'package:flutter/material.dart';
import 'package:untitled/utils/colors.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final bool isPassword;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.isPassword = false,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.minLines,
    this.maxLines,
    this.maxLength,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      validator: widget.validator,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      style: const TextStyle(fontSize: 16, color: AppColors.oliveGray),
      decoration: InputDecoration(
        hintText: widget.hint,
        counterText: widget.maxLength != null ? '' : null,
        hintStyle: TextStyle(
          color: AppColors.oliveGray.withOpacity(0.5),
          fontSize: 16,
        ),
        filled: true,
        fillColor: AppColors.whiteAntique,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.oliveGray.withOpacity(0.5), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.copper.withOpacity(0.7), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.oliveGray.withOpacity(0.8), width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.oliveGray, width: 2),
        ),
        errorStyle: const TextStyle(
          color: AppColors.copper,
          fontSize: 12,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        suffixIcon: widget.isPassword
            ? Padding(
          padding: const EdgeInsets.only(left: 10),
          child: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off : Icons.visibility,
              color: AppColors.oliveGray,
            ),
            onPressed: () {
              setState(() {
                _obscure = !_obscure;
              });
            },
          ),
        )
            : null,
      ),
    );
  }
}

class AppDropdownMenu extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> options;
  final ValueChanged<String?>? onChanged;
  final String? errorText;

  const AppDropdownMenu({
    Key? key,
    required this.value,
    required this.hint,
    required this.options,
    this.onChanged,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownMenu<String>(
          key: key,
          initialSelection: value,
          requestFocusOnTap: false,
          expandedInsets: EdgeInsets.zero,
          onSelected: (selected) {
            onChanged?.call(selected);
          },
          hintText: hint,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.whiteAntique,
            hintStyle: TextStyle(
              color: AppColors.oliveGray.withOpacity(0.5),
              fontSize: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: hasError
                    ? AppColors.oliveGray.withOpacity(0.8)
                    : AppColors.oliveGray.withOpacity(0.5),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: hasError
                    ? AppColors.oliveGray
                    : AppColors.copper.withOpacity(0.7),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
            constraints: const BoxConstraints(minHeight: 36, maxHeight: 48),
          ),
          textStyle: const TextStyle(fontSize: 16, color: AppColors.oliveGray),
          menuStyle: MenuStyle(
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)) {
                return AppColors.copper.withOpacity(0.1);
              }
              return AppColors.whiteAntique;
            }),
          ),
          dropdownMenuEntries: options.map<DropdownMenuEntry<String>>((option) {
            final isSelected = option == value;
            return DropdownMenuEntry<String>(
              value: option,
              label: option,
              style: MenuItemButton.styleFrom(
                foregroundColor: AppColors.oliveGray,
                backgroundColor: isSelected
                    ? AppColors.copper.withOpacity(0.15)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );
          }).toList(),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: AppColors.copper,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}