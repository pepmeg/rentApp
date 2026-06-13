import 'package:flutter/material.dart';

enum ButtonVariant {
  primary,
  secondary,
  destructive,
  outlined,
}

enum ButtonSize {
  normal,
  large,
}

class Button extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final double borderRadius;
  final Color? color;

  const Button({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.normal,
    this.isLoading = false,
    this.icon,
    this.borderRadius = 15, required,
    this.color,
  });

  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLarge = size == ButtonSize.large;
    final verticalPadding = isLarge ? 16.0 : 12.0;
    final fontSize = isLarge ? 20.0 : 18.0;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide? side;

    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = theme.primaryColor;
        foregroundColor = Colors.white;
        break;
      case ButtonVariant.secondary:
        backgroundColor = theme.colorScheme.onSurface;
        foregroundColor = theme.colorScheme.onPrimary;
        break;
      case ButtonVariant.destructive:
        backgroundColor = theme.colorScheme.error;
        foregroundColor = Colors.white;
        break;
      case ButtonVariant.outlined:
        backgroundColor = theme.cardTheme.color ?? theme.colorScheme.surface;
        foregroundColor = theme.colorScheme.onSurface;
        side = BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.5));
        break;
    }

    final disabledBackgroundColor = variant == ButtonVariant.outlined
        ? theme.colorScheme.onSurface.withOpacity(0.1)
        : theme.colorScheme.onSurface.withOpacity(0.3);
    final disabledForegroundColor = theme.colorScheme.onPrimary.withOpacity(0.5);

    Widget child;
    if (isLoading) {
      child = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: foregroundColor,
        ),
      );
    } else if (icon != null) {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
          ),
        ],
      );
    } else {
      child = Text(
        text,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
      );
    }

    if (variant == ButtonVariant.outlined) {
      return OutlinedButton(
        onPressed: _isEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          backgroundColor: _isEnabled ? backgroundColor : disabledBackgroundColor,
          foregroundColor: _isEnabled ? foregroundColor : disabledForegroundColor,
          side: side,
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: _isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isEnabled ? backgroundColor : disabledBackgroundColor,
        foregroundColor: _isEnabled ? foregroundColor : disabledForegroundColor,
        disabledBackgroundColor: disabledBackgroundColor,
        disabledForegroundColor: disabledForegroundColor,
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: child,
    );
  }
}