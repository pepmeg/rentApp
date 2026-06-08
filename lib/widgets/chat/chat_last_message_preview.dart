import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
                    return CachedNetworkImage(
                      imageUrl: snapshot.data!,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.primaryColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    );
                  }
                  return Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
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