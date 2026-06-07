import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SearchField extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final Widget? suffixIcon;
  final bool showClearButton;
  final VoidCallback? onClear;
  final bool autofocus;
  final EdgeInsets padding;
  final TextInputType keyboardType;

  const SearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.controller,
    this.suffixIcon,
    this.showClearButton = true,
    this.onClear,
    this.autofocus = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.keyboardType = TextInputType.text,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late TextEditingController _controller;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _isInternalController = true;
    }
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged(_controller.text);
    if (mounted) setState(() {});
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget? suffix;
    if (widget.suffixIcon != null) {
      suffix = widget.suffixIcon;
    } else if (widget.showClearButton && _controller.text.isNotEmpty) {
      suffix = IconButton(
        icon: Icon(
          Icons.clear_rounded,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        onPressed: _clearText,
      );
    }

    return Padding(
      padding: widget.padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          color: theme.colorScheme.surface,
          child: TextField(
            controller: _controller,
            autofocus: widget.autofocus,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 16,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: SvgPicture.asset(
                  'assets/icons/search.svg',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    theme.primaryColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              suffixIcon: suffix,
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