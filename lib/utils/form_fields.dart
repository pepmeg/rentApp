import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/brand_service.dart';

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
  final List<TextInputFormatter>? inputFormatters;

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
    this.inputFormatters,
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
    final theme = Theme.of(context);
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      validator: widget.validator,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      inputFormatters: widget.inputFormatters ?? [],
      style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: widget.hint,
        counterText: widget.maxLength != null ? '' : null,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
          fontSize: 16,
        ),
        filled: true,
        fillColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.5), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.7), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
        errorStyle: const TextStyle(fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        suffixIcon: widget.isPassword
            ? Padding(
          padding: const EdgeInsets.only(left: 10),
          child: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off : Icons.visibility,
              color: theme.colorScheme.onSurface,
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

OutlinedBorder _popupMenuShape() => RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(15),
);

Color _popupMenuBackgroundColor(BuildContext context, Set<WidgetState> states) {
  final theme = Theme.of(context);
  if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) {
    return theme.primaryColor.withOpacity(0.1);
  }
  return theme.cardTheme.color ?? theme.colorScheme.surface;
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
    final theme = Theme.of(context);
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownMenu<String>(
          key: key,
          initialSelection: value,
          requestFocusOnTap: false,
          expandedInsets: EdgeInsets.zero,
          onSelected: (selected) => onChanged?.call(selected),
          hintText: hint,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: theme.cardTheme.color ?? theme.colorScheme.surface,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
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
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface.withOpacity(0.5),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: hasError
                    ? theme.colorScheme.error
                    : theme.primaryColor.withOpacity(0.7),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
            constraints: const BoxConstraints(minHeight: 36, maxHeight: 48),
          ),
          textStyle: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
          menuStyle: MenuStyle(
            shape: WidgetStateProperty.all(_popupMenuShape()),
            backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => _popupMenuBackgroundColor(context, states)),
          ),
          dropdownMenuEntries: options.map<DropdownMenuEntry<String>>((option) {
            final isSelected = option == value;
            return DropdownMenuEntry<String>(
              value: option,
              label: option,
              style: MenuItemButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface,
                backgroundColor: isSelected
                    ? theme.primaryColor.withOpacity(0.15)
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
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class AppPopupMenuButton<T> extends StatelessWidget {
  final List<PopupMenuEntry<T>> items;
  final void Function(T)? onSelected;
  final Widget? icon;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final OutlinedBorder? shape;

  const AppPopupMenuButton({
    super.key,
    required this.items,
    this.onSelected,
    this.icon,
    this.padding = EdgeInsets.zero,
    this.backgroundColor,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<T>(
      padding: padding,
      icon: icon ?? Icon(Icons.more_vert, color: theme.colorScheme.onSurface, size: 22),
      onSelected: onSelected,
      color: backgroundColor ?? _popupMenuBackgroundColor(context, {}),
      shape: shape ?? _popupMenuShape(),
      elevation: 2,
      shadowColor: theme.colorScheme.onSurface.withOpacity(0.08),
      itemBuilder: (context) => items,
    );
  }
}

class BrandInput extends StatefulWidget {
  final TextEditingController controller;
  const BrandInput({required this.controller, super.key});

  @override
  State<BrandInput> createState() => _BrandInputState();
}

class _BrandInputState extends State<BrandInput> {
  final TextEditingController _localController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _localController.text = widget.controller.text;
    widget.controller.addListener(_syncExternalToLocal);
    _localController.addListener(_syncLocalToExternal);
  }

  void _syncExternalToLocal() {
    if (_localController.text != widget.controller.text) {
      _localController.text = widget.controller.text;
    }
  }

  void _syncLocalToExternal() {
    if (widget.controller.text != _localController.text) {
      widget.controller.text = _localController.text;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncExternalToLocal);
    _localController.removeListener(_syncLocalToExternal);
    _localController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brandService = context.watch<BrandService>();
    final options = brandService.brands;
    final theme = Theme.of(context);

    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
        final lower = textEditingValue.text.toLowerCase();
        return options.where((b) => b.toLowerCase().contains(lower));
      },
      onSelected: (String selection) {
        widget.controller.text = selection;
      },
      optionsViewBuilder: (context, onSelected, options) {
        final nonEmptyOptions = options.where((o) => o.trim().isNotEmpty).toList();
        if (nonEmptyOptions.isEmpty) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(15),
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: nonEmptyOptions.length,
                itemBuilder: (context, index) {
                  final option = nonEmptyOptions[index];
                  final isSelected = option == widget.controller.text;
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.primaryColor.withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        textController.text = _localController.text;
        textController.addListener(() {
          _localController.text = textController.text;
        });
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          onFieldSubmitted: (_) => onFieldSubmitted(),
          style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Бренд',
            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 16),
            filled: true,
            fillColor: theme.cardTheme.color ?? theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.5), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: theme.primaryColor.withOpacity(0.7), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
          ),
        );
      },
    );
  }
}