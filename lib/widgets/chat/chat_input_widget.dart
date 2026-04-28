import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled/utils/colors.dart';

class ChatInputWidget extends StatefulWidget {
  final TextEditingController messageController;
  final bool isEditing;
  final VoidCallback onSend;
  final VoidCallback onCancelEdit;
  final Function(List<String>) onImagesSelected;
  final Function(int)? onReplaceImage;

  const ChatInputWidget({
    Key? key,
    required this.messageController,
    required this.isEditing,
    required this.onSend,
    required this.onCancelEdit,
    required this.onImagesSelected,
    this.onReplaceImage,
  }) : super(key: key);

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

  void replaceImageAt(int index, List<String> newPaths) {
    if (index < 0 || index >= _selectedImagePaths.length) return;
    setState(() {
      _selectedImagePaths.removeAt(index);
      _selectedImagePaths.insertAll(index, newPaths);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Можно добавить не более 10 фото')),
      );
      return;
    }
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles == null || pickedFiles.isEmpty) return;

    int added = 0;
    for (int i = 0; i < pickedFiles.length && added < remaining; i++) {
      final savedPath = await _saveImagePermanently(pickedFiles[i].path);
      setState(() => _selectedImagePaths.add(savedPath));
      added++;
    }
    widget.onImagesSelected(_selectedImagePaths);
    if (added < pickedFiles.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Добавлено $added из ${pickedFiles.length}. Лимит 10 фото.')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImagePaths.removeAt(index);
      widget.onImagesSelected(_selectedImagePaths);
    });
  }

  Widget _buildImagePreviews() {
    if (_selectedImagePaths.isEmpty && !widget.isEditing) return const SizedBox.shrink();
    if (widget.isEditing) {
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
                  color: AppColors.spaceCream,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.oliveGray.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz, size: 16, color: AppColors.copper),
                    const SizedBox(width: 6),
                    Text('Заменить',
                        style: TextStyle(
                            color: AppColors.copper,
                            fontWeight: FontWeight.w500,
                            fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
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
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedImagePaths[i]),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
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
              ),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.spaceCream.withOpacity(0.95),
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
          _buildImagePreviews(),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: AppColors.oliveGray),
                  onPressed: _pickImages,
                ),
                Expanded(
                  child: TextField(
                    controller: widget.messageController,
                    maxLines: 6,
                    minLines: 1,
                    maxLength: 500,
                    style: const TextStyle(color: AppColors.oliveGray),
                    decoration: InputDecoration(
                      hintText: 'Сообщение...',
                      hintStyle: TextStyle(color: AppColors.oliveGray.withOpacity(0.4)),
                      filled: true,
                      fillColor: AppColors.whiteAntique,
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
                      icon: const Icon(Icons.close, color: AppColors.oliveGray),
                      onPressed: widget.onCancelEdit,
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.copper,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(widget.isEditing ? Icons.check : Icons.arrow_upward,
                        color: AppColors.whiteAntique, size: 20),
                    onPressed: _canSend ? widget.onSend : null,
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