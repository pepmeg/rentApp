import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/storage_service.dart';

class ChatInputWidget extends StatefulWidget {
  final TextEditingController messageController;
  final bool isEditing;
  final bool hasImagesInOriginalMessage;
  final VoidCallback onSend;
  final VoidCallback onCancelEdit;
  final Function(List<String>) onImagesSelected;
  final Function(int)? onReplaceImage;
  final bool isUploading;

  const ChatInputWidget({
    super.key,
    required this.messageController,
    required this.isEditing,
    this.hasImagesInOriginalMessage = false,
    required this.onSend,
    required this.onCancelEdit,
    required this.onImagesSelected,
    this.onReplaceImage,
    this.isUploading = false,
  });

  @override
  State<ChatInputWidget> createState() => ChatInputWidgetState();
}

class ChatInputWidgetState extends State<ChatInputWidget> {
  final List<String> _selectedImagePaths = [];
  static const int maxImagesPerMessage = 10;

  void setInitialImages(List<String> paths) {
    setState(() {
      _selectedImagePaths.clear();
      _selectedImagePaths.addAll(paths);
      widget.onImagesSelected(_selectedImagePaths);
    });
  }

  Future<String> _saveImagePermanently(String sourcePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final chatDir = Directory('${directory.path}/chat_images');
      if (!await chatDir.exists()) {
        await chatDir.create(recursive: true);
      }
      final fileName = 'chat_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File('${chatDir.path}/$fileName');
      await File(sourcePath).copy(savedImage.path);
      return savedImage.path;
    } catch (e) {
      return sourcePath;
    }
  }

  Future<void> _pickImages() async {
    final remaining = maxImagesPerMessage - _selectedImagePaths.length;
    if (remaining <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Можно добавить не более 10 фото')),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (!mounted) return;
    if (pickedFiles.isEmpty) return;

    final filesToAdd = pickedFiles.take(remaining);
    for (final file in filesToAdd) {
      final placeholder = '__uploading__${DateTime.now().millisecondsSinceEpoch}';
      final idx = _selectedImagePaths.length;
      setState(() => _selectedImagePaths.add(placeholder));
      widget.onImagesSelected(_selectedImagePaths);

      final localPath = await _saveImagePermanently(file.path);
      if (!mounted) return;
      setState(() => _selectedImagePaths[idx] = localPath);
      widget.onImagesSelected(_selectedImagePaths);
    }
  }

  void _removeImage(int index) {
    final path = _selectedImagePaths[index];
    if (!path.startsWith('__uploading__')) {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    }
    setState(() {
      _selectedImagePaths.removeAt(index);
      widget.onImagesSelected(_selectedImagePaths);
    });
  }

  void replaceImageAt(int index, List<String> newPaths) {
    if (index < 0 || index >= _selectedImagePaths.length) return;
    setState(() {
      _selectedImagePaths.removeAt(index);
      _selectedImagePaths.insertAll(index, newPaths);
      widget.onImagesSelected(_selectedImagePaths);
    });
  }

  Widget _buildUploadingPlaceholder(ThemeData theme) {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 3, color: theme.primaryColor),
      ),
    );
  }

  Widget _buildImagePreviews(ThemeData theme) {
    if (_selectedImagePaths.isEmpty && !widget.isEditing) return const SizedBox.shrink();
    if (widget.isEditing) {
      if (widget.hasImagesInOriginalMessage) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 20),
          child: Row(
            children: [
              InkWell(
                onTap: () => widget.onReplaceImage?.call(-1),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.background,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.onSurface.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz, size: 16, color: theme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        'Заменить',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    }
    return Container(
      height: 80,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImagePaths.length,
              itemBuilder: (_, i) {
                final path = _selectedImagePaths[i];
                if (path.startsWith('__uploading__')) {
                  return _buildUploadingPlaceholder(theme);
                }
                final file = File(path);
                if (file.existsSync()) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => _removeImage(i),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FutureBuilder<String?>(
                          future: StorageService.getDownloadUrl(path, cache: true),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return Image.network(
                                snapshot.data!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: theme.primaryColor,
                                        value: progress.expectedTotalBytes != null
                                            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                                  child: Icon(Icons.broken_image, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                ),
                              );
                            }
                            return Container(
                              width: 80,
                              height: 80,
                              color: theme.colorScheme.onSurface.withOpacity(0.3),
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 3, color: theme.primaryColor),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => _removeImage(i),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool get _canSend {
    final text = widget.messageController.text.trim();
    return text.isNotEmpty || _selectedImagePaths.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildImagePreviews(theme),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file, color: theme.colorScheme.onSurface),
                  onPressed: _pickImages,
                ),
                Expanded(
                  child: TextField(
                    controller: widget.messageController,
                    maxLines: 6,
                    minLines: 1,
                    maxLength: 500,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Сообщение...',
                      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      filled: true,
                      fillColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      counterText: '',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (widget.isEditing)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: IconButton(
                      icon: widget.isUploading
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : Icon(
                        widget.isEditing ? Icons.check : Icons.arrow_upward,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: (_canSend && !widget.isUploading) ? widget.onSend : null,
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: widget.isUploading
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Icon(
                      widget.isEditing ? Icons.check : Icons.arrow_upward,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: (_canSend && !widget.isUploading) ? widget.onSend : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}