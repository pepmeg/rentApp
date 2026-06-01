import 'package:flutter/material.dart';
import '../../services/storage_service.dart';

class ChatLastMessagePreview extends StatelessWidget {
  final List<String>? images;
  final String text;

  const ChatLastMessagePreview({super.key, this.images, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (images != null && images!.isNotEmpty) {
      final count = images!.length;
      final label = count == 1 ? 'Фотография' : '$count фото';
      final previewKeys = images!.take(3).toList();

      return Row(
        children: [
          ...previewKeys.map((key) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: FutureBuilder<String?>(
                future: StorageService.getDownloadUrl(key, cache: true),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.network(snapshot.data!,
                        width: 28, height: 28, fit: BoxFit.cover);
                  }
                  return Container(
                    width: 28,
                    height: 28,
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                  );
                },
              ),
            ),
          )),
          const SizedBox(width: 4),
          if (text.isNotEmpty)
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            )
          else
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
        ],
      );
    }

    if (text.isNotEmpty) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      );
    }

    return Text(
      'Нет сообщений',
      style: TextStyle(
        fontSize: 14,
        color: theme.colorScheme.onSurface.withOpacity(0.5),
      ),
    );
  }
}