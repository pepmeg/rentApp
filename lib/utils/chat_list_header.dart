import 'package:flutter/material.dart';

class ChatListHeader extends StatelessWidget {
  final bool selectionMode;
  final int selectedCount;
  final VoidCallback onCloseSelection;
  final VoidCallback onDeleteSelected;

  const ChatListHeader({
    super.key,
    required this.selectionMode,
    required this.selectedCount,
    required this.onCloseSelection,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Сообщения',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (selectionMode) _buildActionBar(context),
      ],
    );
  }

  Widget _buildActionBar(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onCloseSelection,
            child: Icon(Icons.close, size: 28, color: theme.colorScheme.onSurface),
          ),
          const Spacer(),
          GestureDetector(
            onTap: selectedCount == 0 ? null : onDeleteSelected,
            child: Icon(
              Icons.delete,
              size: 28,
              color: selectedCount == 0
                  ? theme.colorScheme.onSurface.withOpacity(0.5)
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}