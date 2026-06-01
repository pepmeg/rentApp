import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/messager_model/message.dart';
import '../../models/user.dart';
import '../../services/storage_service.dart';
import '../../utils/avatar.dart';

class ChatMessageWidget extends StatefulWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final bool showDate;
  final bool showTime;
  final String dateText;
  final String timeText;
  final UserModel? companion;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final Function(int)? onImageLongPress;
  final Function(int)? onImageTap;
  final Set<int> selectedImageIndices;
  final bool forceRightForAi;

  const ChatMessageWidget({
    super.key,
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.showDate,
    required this.showTime,
    required this.dateText,
    required this.timeText,
    this.companion,
    this.onLongPress,
    this.isSelected = false,
    this.onImageLongPress,
    this.onImageTap,
    this.selectedImageIndices = const <int>{},
    this.forceRightForAi = false,
  });

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends State<ChatMessageWidget> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) setState(() => _opacity = 1.0);
    });
  }

  Widget _buildImageGrid(BuildContext context, ThemeData theme) {
    final images = widget.message.images!;
    final count = images.length;
    final availableWidth = MediaQuery.of(context).size.width * 0.75 - 28;
    const double spacing = 4;
    const double borderRadius = 8;

    switch (count) {
      case 1:
        return _buildImageTile(images[0], 0, theme,
            width: availableWidth, height: 220, borderRadius: borderRadius);
      case 2:
        final itemWidth = (availableWidth - spacing) / 2;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImageTile(images[0], 0, theme,
                width: itemWidth, height: itemWidth, borderRadius: borderRadius),
            SizedBox(width: spacing),
            _buildImageTile(images[1], 1, theme,
                width: itemWidth, height: itemWidth, borderRadius: borderRadius),
          ],
        );
      case 3:
        final smallWidth = (availableWidth - spacing) / 2;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImageTile(images[0], 0, theme,
                width: availableWidth, height: 220, borderRadius: borderRadius),
            SizedBox(height: spacing),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImageTile(images[1], 1, theme,
                    width: smallWidth, height: smallWidth, borderRadius: borderRadius),
                SizedBox(width: spacing),
                _buildImageTile(images[2], 2, theme,
                    width: smallWidth, height: smallWidth, borderRadius: borderRadius),
              ],
            ),
          ],
        );
      case 4:
        final itemWidth = (availableWidth - spacing) / 2;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImageTile(images[0], 0, theme,
                    width: itemWidth, height: itemWidth, borderRadius: borderRadius),
                SizedBox(width: spacing),
                _buildImageTile(images[1], 1, theme,
                    width: itemWidth, height: itemWidth, borderRadius: borderRadius),
              ],
            ),
            SizedBox(height: spacing),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImageTile(images[2], 2, theme,
                    width: itemWidth, height: itemWidth, borderRadius: borderRadius),
                SizedBox(width: spacing),
                _buildImageTile(images[3], 3, theme,
                    width: itemWidth, height: itemWidth, borderRadius: borderRadius),
              ],
            ),
          ],
        );
      default:
        return _buildAdaptiveGrid(
            images, availableWidth, spacing, borderRadius, theme);
    }
  }

  Widget _buildAdaptiveGrid(List<String> images, double availableWidth,
      double spacing, double borderRadius, ThemeData theme) {
    const int cols = 3;
    final int count = images.length;
    final itemWidth = (availableWidth - (cols - 1) * spacing) / cols;
    final int rows = (count / cols).ceil();
    final List<Widget> rowWidgets = [];

    for (int r = 0; r < rows; r++) {
      final List<Widget> rowChildren = [];
      int itemsInRow = 0;
      for (int c = 0; c < cols; c++) {
        final idx = r * cols + c;
        if (idx < count) {
          itemsInRow++;
          rowChildren.add(_buildImageTile(images[idx], idx, theme,
              width: itemWidth, height: itemWidth, borderRadius: borderRadius));
          if (c < cols - 1) rowChildren.add(SizedBox(width: spacing));
        }
      }
      if (r == rows - 1 && itemsInRow < cols) {
        final expandedWidth = (availableWidth - (itemsInRow - 1) * spacing) / itemsInRow;
        rowChildren.clear();
        for (int c = 0; c < itemsInRow; c++) {
          final idx = r * cols + c;
          rowChildren.add(_buildImageTile(images[idx], idx, theme,
              width: expandedWidth, height: itemWidth, borderRadius: borderRadius));
          if (c < itemsInRow - 1) rowChildren.add(SizedBox(width: spacing));
        }
      }
      rowWidgets.add(Row(mainAxisSize: MainAxisSize.min, children: rowChildren));
      if (r < rows - 1) rowWidgets.add(SizedBox(height: spacing));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rowWidgets,
    );
  }

  Widget _buildImageTile(String key, int index, ThemeData theme,
      {required double width, required double height, required double borderRadius}) {
    final cachedUrl = StorageService.getCachedUrlSync(key);

    if (cachedUrl != null) {
      return _buildCachedImage(cachedUrl, index, width, height, borderRadius, theme);
    }

    return FutureBuilder<String?>(
      future: StorageService.getDownloadUrl(key, cache: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 3, color: theme.primaryColor),
            ),
          );
        }
        final url = snapshot.data;
        if (url == null || url.isEmpty) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Icon(Icons.broken_image, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          );
        }
        return _buildCachedImage(url, index, width, height, borderRadius, theme);
      },
    );
  }

  Widget _buildCachedImage(String url, int index, double width, double height,
      double borderRadius, ThemeData theme) {
    return GestureDetector(
      onLongPress: () => widget.onImageLongPress?.call(index),
      onTap: () => widget.onImageTap?.call(index),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(borderRadius)),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: CachedNetworkImage(
                imageUrl: url,
                width: width,
                height: height,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 3, color: theme.primaryColor),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                  child: Icon(Icons.broken_image, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
              ),
            ),
            if (widget.selectedImageIndices.contains(index))
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle, color: Colors.white, size: 32),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 300),
      child: _buildMessageContent(context),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasImages = widget.message.images != null && widget.message.images!.isNotEmpty;
    final bool hasText = widget.message.text.isNotEmpty;
    final bool isAiAssistant = widget.message.senderId == 'ai_assistant';
    final bool isMe = widget.isMe || (isAiAssistant && widget.forceRightForAi);
    final bool isMyMessage = isMe;

    final imageBlock = hasImages
        ? Padding(
      padding: const EdgeInsets.only(top: 6),
      child: _buildImageGrid(context, theme),
    )
        : const SizedBox.shrink();

    final textBlock = hasText
        ? Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      decoration: BoxDecoration(
        color: isMyMessage
            ? theme.primaryColor.withOpacity(0.15)
            : (theme.cardTheme.color ?? theme.colorScheme.surface),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: isMyMessage ? const Radius.circular(16) : const Radius.circular(4),
          bottomRight: isMyMessage ? const Radius.circular(4) : const Radius.circular(16),
        ),
      ),
      child: Text(
        widget.message.text,
        style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
        softWrap: true,
      ),
    )
        : const SizedBox.shrink();

    final contentColumn = Column(
      crossAxisAlignment: isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasImages) imageBlock,
        if (hasImages && hasText) const SizedBox(height: 4),
        if (hasText) textBlock,
      ],
    );

    Widget timeRow = const SizedBox.shrink();
    if (widget.showTime || widget.message.edited || isAiAssistant) {
      final children = <Widget>[];
      if (widget.message.edited && widget.isMe) {
        children.add(Text(
          'изменено',
          style: TextStyle(
            fontSize: 10,
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ));
        if (widget.showTime) children.add(const SizedBox(width: 4));
      }
      if (widget.showTime) {
        children.add(Text(
          widget.timeText,
          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5)),
        ));
      }
      if (isAiAssistant && !widget.isMe) {
        if (widget.showTime) children.add(const SizedBox(width: 4));
        children.add(Text(
          'ИИ-помощник',
          style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: theme.primaryColor),
        ));
      }
      if (widget.message.edited && !widget.isMe) {
        if (widget.showTime || isAiAssistant) children.add(const SizedBox(width: 4));
        children.add(Text(
          'изменено',
          style: TextStyle(
            fontSize: 10,
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ));
      }
      timeRow = Padding(
        padding: EdgeInsets.only(top: 2, left: isMyMessage ? 0 : 3, right: isMyMessage ? 10 : 0),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (widget.showDate)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.dateText,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  ),
                ),
              ),
            ),
          GestureDetector(
            onLongPress: widget.onLongPress,
            behavior: HitTestBehavior.translucent,
            child: Container(
              decoration: widget.isSelected
                  ? BoxDecoration(
                color: theme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              )
                  : null,
              padding: widget.isSelected ? const EdgeInsets.all(6) : EdgeInsets.zero,
              child: Row(
                mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isMyMessage && widget.showAvatar && !isAiAssistant)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: buildUserAvatar(widget.companion, radius: 16),
                    )
                  else if (!isMyMessage)
                    const SizedBox(width: 40),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        contentColumn,
                        timeRow,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}