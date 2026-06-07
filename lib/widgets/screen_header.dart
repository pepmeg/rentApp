import 'package:flutter/material.dart';

class ScreenHeader extends StatelessWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final double titleSize;
  final EdgeInsets padding;
  final bool useSafeArea;

  const ScreenHeader({
    super.key,
    this.title,
    this.actions,
    this.showBackButton = true,
    this.titleSize = 24,
    this.padding = const EdgeInsets.only(left: 20, right: 20, top: 40),
    this.useSafeArea = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = Padding(
      padding: padding,
      child: Row(
        children: [
          if (showBackButton) ...[
            IconButton(
              icon: Icon(Icons.arrow_back, size: 24, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 5),
          ],
          if (title != null)
            Expanded(
              child: Text(
                title!,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Spacer(),
          if (actions != null && actions!.isNotEmpty) ...actions!,
        ],
      ),
    );

    if (useSafeArea) {
      return SafeArea(child: content);
    }
    return content;
  }
}