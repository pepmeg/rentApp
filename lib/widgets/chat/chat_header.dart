import 'package:flutter/material.dart';
import '../../models/messager_model/chat.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../pages/productScreen.dart';
import '../../services/storage_service.dart';
import '../../utils/avatar.dart';

class ChatHeader extends StatelessWidget {
  final Chat chat;
  final UserModel? companion;
  final Product? product;
  final bool isImageSelectionMode;
  final int? selectedImageMessageIndex;
  final int? selectedMessageIndex;
  final Set<int> selectedImageIndices;
  final bool isAdmin;
  final bool selectedMessageIsMe;
  final VoidCallback onDeselectMessage;
  final VoidCallback onCopyMessage;
  final VoidCallback onEditMessage;
  final VoidCallback onDeleteMessage;
  final VoidCallback onModerateMessage;
  final VoidCallback onDeselectImages;
  final VoidCallback onReplaceImages;
  final VoidCallback onDeleteSelectedImages;
  final void Function()? onSellerTap;
  final bool isSupportChat;
  final bool isCurrentUserSupport;
  final bool aiMode;
  final bool humanRequested;
  final String? assignedOperatorId;
  final VoidCallback? onRequestHumanOperator;
  final VoidCallback? onToggleAiMode;
  final bool isParticipant;
  final bool isReady;

  const ChatHeader({
    super.key,
    required this.chat,
    this.companion,
    this.product,
    required this.isImageSelectionMode,
    this.selectedImageMessageIndex,
    this.selectedMessageIndex,
    required this.selectedImageIndices,
    required this.isAdmin,
    required this.selectedMessageIsMe,
    required this.onDeselectMessage,
    required this.onCopyMessage,
    required this.onEditMessage,
    required this.onDeleteMessage,
    required this.onModerateMessage,
    required this.onDeselectImages,
    required this.onReplaceImages,
    required this.onDeleteSelectedImages,
    this.onSellerTap,
    required this.isSupportChat,
    required this.isCurrentUserSupport,
    required this.aiMode,
    required this.humanRequested,
    this.assignedOperatorId,
    this.onRequestHumanOperator,
    this.onToggleAiMode,
    required this.isParticipant,
    required this.isReady,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 40, bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isImageSelectionMode)
            ChatImageActionBar(
              selectedCount: selectedImageIndices.length,
              onClose: onDeselectImages,
              onReplace: onReplaceImages,
              onDelete: onDeleteSelectedImages,
            )
          else if (selectedMessageIndex != null)
            ChatActionBar(
              isAdmin: isAdmin,
              isOwn: selectedMessageIsMe,
              onClose: onDeselectMessage,
              onCopy: onCopyMessage,
              onEdit: onEditMessage,
              onDelete: onDeleteMessage,
              onModerate: onModerateMessage,
            )
          else
            ChatSellerRow(
              chat: chat,
              companion: companion,
              product: product,
              onTap: onSellerTap,
              isSupportChat: isSupportChat,
              isCurrentUserSupport: isCurrentUserSupport,
              isParticipant: isParticipant,
              aiMode: aiMode,
              humanRequested: humanRequested,
              assignedOperatorId: assignedOperatorId,
              onRequestHumanOperator: onRequestHumanOperator,
              onToggleAiMode: onToggleAiMode,
              isReady: isReady,
            ),
          if (product != null) ...[
            const SizedBox(height: 6),
            Divider(color: theme.dividerColor, height: 1),
            const SizedBox(height: 6),
            ChatProductRow(product: product!),
          ],
        ],
      ),
    );
  }
}

class ChatSellerRow extends StatelessWidget {
  final Chat chat;
  final UserModel? companion;
  final Product? product;
  final VoidCallback? onTap;
  final bool isSupportChat;
  final bool isCurrentUserSupport;
  final bool aiMode;
  final bool humanRequested;
  final String? assignedOperatorId;
  final VoidCallback? onRequestHumanOperator;
  final VoidCallback? onToggleAiMode;
  final bool isParticipant;
  final bool isReady;

  const ChatSellerRow({
    super.key,
    required this.chat,
    this.companion,
    this.product,
    this.onTap,
    required this.isSupportChat,
    required this.isCurrentUserSupport,
    required this.aiMode,
    required this.humanRequested,
    this.assignedOperatorId,
    this.onRequestHumanOperator,
    this.onToggleAiMode,
    required this.isParticipant,
    required this.isReady,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final companionNotNull = companion;
    String name;
    if (companionNotNull != null) {
      name = '${companionNotNull.firstName} ${companionNotNull.lastName}';
    } else {
      name = chat.companionName ?? 'Собеседник';
    }

    String subtitle;
    if (companionNotNull?.role == 'admin') {
      subtitle = 'Администратор';
    } else if (companionNotNull?.role == 'support') {
      subtitle = 'Поддержка';
    } else {
      subtitle = product != null ? 'По товару' : 'Чат';
    }

    final bool showUserAiBadge = isReady && !isCurrentUserSupport && isSupportChat && aiMode && !humanRequested && assignedOperatorId == null && isParticipant;
    final bool showRequestOperator = isReady && !isCurrentUserSupport && isSupportChat && aiMode && !humanRequested && assignedOperatorId == null && isParticipant;
    final bool showSupportToggle = isReady && isCurrentUserSupport && isSupportChat && companion?.role == 'user' && isParticipant;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, size: 22, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 8),
          buildUserAvatar(companion, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (showUserAiBadge) _buildAiIndicator(theme),
                    if (showSupportToggle) _buildAiToggle(theme),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              ],
            ),
          ),
          if (showRequestOperator) _buildOperatorButton(theme),
        ],
      ),
    );
  }

  Widget _buildAiIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: theme.primaryColor),
          const SizedBox(width: 4),
          Text(
            'ИИ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiToggle(ThemeData theme) {
    return GestureDetector(
      onTap: onToggleAiMode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: aiMode ? theme.primaryColor : theme.colorScheme.onSurface.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 12,
              color: aiMode ? Colors.white : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 4),
            Text(
              aiMode ? 'ИИ' : 'ИИ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: aiMode ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorButton(ThemeData theme) {
    return GestureDetector(
      onTap: onRequestHumanOperator,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: theme.primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'Оператор',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatProductRow extends StatelessWidget {
  final Product product;

  const ChatProductRow({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductScreen(product: product)));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.images.isNotEmpty
                  ? (product.images[0].startsWith('assets/')
                  ? Image.asset(product.images[0], width: 40, height: 40, fit: BoxFit.cover)
                  : (product.images[0].startsWith('http')
                  ? Image.network(product.images[0], width: 40, height: 40, fit: BoxFit.cover)
                  : FutureBuilder<String?>(
                future: StorageService.getDownloadUrl(product.images[0]),
                builder: (ctx, snap) {
                  if (snap.hasData && snap.data != null)
                    return Image.network(snap.data!, width: 40, height: 40, fit: BoxFit.cover);
                  return Container(
                    width: 40,
                    height: 40,
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                    child: Icon(Icons.image, color: theme.colorScheme.onSurface, size: 20),
                  );
                },
              )))
                  : Container(
                width: 40,
                height: 40,
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                child: Icon(Icons.image, color: theme.colorScheme.onSurface, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${product.price} ₽',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatActionBar extends StatelessWidget {
  final bool isAdmin;
  final bool isOwn;
  final VoidCallback onClose;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onModerate;

  const ChatActionBar({
    super.key,
    required this.isAdmin,
    required this.isOwn,
    required this.onClose,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
    required this.onModerate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.close, size: 22, color: theme.colorScheme.onSurface),
          onPressed: onClose,
          constraints: const BoxConstraints(),
        ),
        const Spacer(),
        if (isAdmin) ...[
          IconButton(
            icon: Icon(Icons.copy, size: 22, color: theme.colorScheme.onSurface),
            onPressed: onCopy,
          ),
          IconButton(
            icon: Icon(Icons.delete, size: 22, color: theme.colorScheme.onSurface),
            onPressed: onModerate,
          ),
          if (isOwn) ...[
            IconButton(
              icon: Icon(Icons.edit, size: 22, color: theme.colorScheme.onSurface),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete, size: 22, color: theme.colorScheme.onSurface),
              onPressed: onDelete,
            ),
          ],
        ] else ...[
          IconButton(
            icon: Icon(Icons.copy, size: 22, color: theme.colorScheme.onSurface),
            onPressed: onCopy,
          ),
          if (isOwn) ...[
            IconButton(
              icon: Icon(Icons.edit, size: 22, color: theme.colorScheme.onSurface),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete, size: 22, color: theme.colorScheme.onSurface),
              onPressed: onDelete,
            ),
          ],
        ],
      ],
    );
  }
}

class ChatImageActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClose;
  final VoidCallback onReplace;
  final VoidCallback onDelete;

  const ChatImageActionBar({
    super.key,
    required this.selectedCount,
    required this.onClose,
    required this.onReplace,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.close, size: 22, color: theme.colorScheme.onSurface),
          onPressed: onClose,
          constraints: const BoxConstraints(),
        ),
        if (selectedCount > 0) ...[
          const SizedBox(width: 6),
          Text('$selectedCount', style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface)),
        ],
        const Spacer(),
        IconButton(
          icon: Icon(Icons.swap_horiz, size: 22, color: theme.colorScheme.onSurface),
          onPressed: onReplace,
        ),
        IconButton(
          icon: Icon(Icons.delete, size: 22, color: theme.colorScheme.error),
          onPressed: onDelete,
        ),
      ],
    );
  }
}