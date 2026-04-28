import 'dart:io';
import 'package:flutter/material.dart';
import 'package:untitled/models/message.dart';
import 'package:untitled/models/user.dart';
import 'package:untitled/utils/colors.dart';

class ChatMessageWidget extends StatelessWidget {
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

  const ChatMessageWidget({
    Key? key,
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
  }) : super(key: key);

  Widget _buildImageGrid(BuildContext context) {
    final images = message.images!;
    final count = images.length;
    final availableWidth = MediaQuery.of(context).size.width * 0.75 - 28;
    const double spacing = 4;
    const double borderRadius = 8;

    switch (count) {
      case 1:
        return _buildImageTile(images[0], 0,
            width: availableWidth, height: 260, borderRadius: borderRadius);
      case 2:
        final itemWidth = (availableWidth - spacing) / 2;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImageTile(images[0], 0, width: itemWidth, height: itemWidth, borderRadius: borderRadius),
            SizedBox(width: spacing),
            _buildImageTile(images[1], 1, width: itemWidth, height: itemWidth, borderRadius: borderRadius),
          ],
        );
      case 3:
        final smallWidth = (availableWidth - spacing) / 2;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImageTile(images[0], 0, width: availableWidth, height: 220, borderRadius: borderRadius),
            SizedBox(height: spacing),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImageTile(images[1], 1, width: smallWidth, height: smallWidth, borderRadius: borderRadius),
                SizedBox(width: spacing),
                _buildImageTile(images[2], 2, width: smallWidth, height: smallWidth, borderRadius: borderRadius),
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
                _buildImageTile(images[0], 0, width: itemWidth, height: itemWidth, borderRadius: borderRadius),
                SizedBox(width: spacing),
                _buildImageTile(images[1], 1, width: itemWidth, height: itemWidth, borderRadius: borderRadius),
              ],
            ),
            SizedBox(height: spacing),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImageTile(images[2], 2, width: itemWidth, height: itemWidth, borderRadius: borderRadius),
                SizedBox(width: spacing),
                _buildImageTile(images[3], 3, width: itemWidth, height: itemWidth, borderRadius: borderRadius),
              ],
            ),
          ],
        );
      default:
        return _buildAdaptiveGrid(images, availableWidth, spacing, borderRadius);
    }
  }

  Widget _buildAdaptiveGrid(List<String> images, double availableWidth, double spacing, double borderRadius) {
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
          rowChildren.add(_buildImageTile(images[idx], idx,
              width: itemWidth, height: itemWidth, borderRadius: borderRadius));
          if (c < cols - 1) rowChildren.add(SizedBox(width: spacing));
        }
      }
      if (r == rows - 1 && itemsInRow < cols) {
        final expandedWidth = (availableWidth - (itemsInRow - 1) * spacing) / itemsInRow;
        rowChildren.clear();
        for (int c = 0; c < itemsInRow; c++) {
          final idx = r * cols + c;
          rowChildren.add(_buildImageTile(images[idx], idx,
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

  Widget _buildImageTile(String path, int index,
      {required double width, required double height, required double borderRadius}) {
    return GestureDetector(
      onLongPress: () => onImageLongPress?.call(index),
      onTap: () => onImageTap?.call(index),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(borderRadius)),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Image.file(
                File(path),
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
            if (selectedImageIndices.contains(index))
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.copper.withOpacity(0.4),
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
    final bool hasImages = message.images != null && message.images!.isNotEmpty;
    final bool hasText = message.text.isNotEmpty;
    final imageBlock = hasImages
        ? Padding(
      padding: const EdgeInsets.only(top: 6),
      child: _buildImageGrid(context),
    )
        : const SizedBox.shrink();
    final textBlock = hasText
        ? Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.copper.withOpacity(0.15)
            : AppColors.whiteAntique,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft:
          isMe ? const Radius.circular(16) : const Radius.circular(4),
          bottomRight:
          isMe ? const Radius.circular(4) : const Radius.circular(16),
        ),
      ),
      child: Text(
        message.text,
        style: const TextStyle(fontSize: 15, color: AppColors.oliveGray),
        softWrap: true,
      ),
    )
        : const SizedBox.shrink();
    final contentColumn = Column(
      crossAxisAlignment:
      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasImages) imageBlock,
        if (hasImages && hasText) const SizedBox(height: 4),
        if (hasText) textBlock,
      ],
    );

    // Строка времени и "изменено"
    Widget timeRow = const SizedBox.shrink();
    final bool hasEdited = message.edited;
    final bool hasTime = showTime;
    if (hasTime || hasEdited) {
      final children = <Widget>[];
      if (hasEdited) {
        children.addAll([
          if (isMe) ...[
            Text('изменено',
                style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: AppColors.oliveGray.withOpacity(0.4))),
            if (hasTime) const SizedBox(width: 4),
          ],
        ]);
      }
      if (hasTime) {
        children.add(Text(timeText,
            style: TextStyle(
                fontSize: 11,
                color: AppColors.oliveGray.withOpacity(0.5))));
      }
      if (hasEdited && !isMe) {
        children.addAll([
          if (hasTime) const SizedBox(width: 4),
          Text('изменено',
              style: TextStyle(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: AppColors.oliveGray.withOpacity(0.4))),
        ]);
      }
      timeRow = Padding(
        padding: EdgeInsets.only(
            top: 2, left: isMe ? 0 : 3, right: isMe ? 10 : 0),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment:
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showDate)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.oliveGray.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(dateText,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.oliveGray.withOpacity(0.7))),
                ),
              ),
            ),
          GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              margin: isSelected
                  ? const EdgeInsets.symmetric(horizontal: 4)
                  : EdgeInsets.zero,
              decoration: isSelected
                  ? BoxDecoration(
                color: AppColors.copper.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              )
                  : null,
              padding: isSelected ? const EdgeInsets.all(6) : EdgeInsets.zero,
              child: Row(
                mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isMe && showAvatar)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.oliveGray.withOpacity(0.1),
                        backgroundImage: companion?.avatarPath != null
                            ? (companion!.avatarPath!.startsWith('assets/')
                            ? AssetImage(companion!.avatarPath!)
                            : FileImage(File(companion!.avatarPath!)))
                            : null,
                        child: companion?.avatarPath == null
                            ? const Icon(Icons.person,
                            size: 18, color: AppColors.oliveGray)
                            : null,
                      ),
                    )
                  else if (!isMe)
                    const SizedBox(width: 40),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
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