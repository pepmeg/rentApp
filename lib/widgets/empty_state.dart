import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String? svgAsset;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final double iconSize;
  final double titleSize;
  final double subtitleSize;
  final EdgeInsets padding;
  final MainAxisAlignment mainAxisAlignment;

  const EmptyState({
    super.key,
    this.icon,
    this.svgAsset,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.iconSize = 64,
    this.titleSize = 18,
    this.subtitleSize = 14,
    this.padding = EdgeInsets.zero,
    this.mainAxisAlignment = MainAxisAlignment.center,
  }) : assert(icon != null || svgAsset != null, 'Either icon or svgAsset must be provided');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Center(
        child: Column(
          mainAxisAlignment: mainAxisAlignment,
          children: [
            if (svgAsset != null)
              SvgPicture.asset(
                svgAsset!,
                width: iconSize,
                height: iconSize,
                colorFilter: ColorFilter.mode(
                  theme.colorScheme.onSurface.withOpacity(0.3),
                  BlendMode.srcIn,
                ),
              )
            else if (icon != null)
              Icon(
                icon!,
                size: iconSize,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.refresh),
                label: Text(buttonText!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}