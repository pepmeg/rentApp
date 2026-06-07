import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ImageFileService {
  static Future<String> saveImage(
      String sourcePath, {
        required String folder,
        required String prefix,
      }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${directory.path}/$folder');

      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File('${targetDir.path}/$fileName');
      await File(sourcePath).copy(savedImage.path);

      return savedImage.path;
    } catch (e) {
      debugPrint('Ошибка сохранения изображения в $folder: $e');
      return sourcePath;
    }
  }

  /// Упрощённые методы для часто используемых папок
  static Future<String> saveProductImage(String sourcePath) {
    return saveImage(sourcePath, folder: 'product_images', prefix: 'product');
  }

  static Future<String> saveChatImage(String sourcePath) {
    return saveImage(sourcePath, folder: 'chat_images', prefix: 'chat');
  }

  static Future<String> saveAvatar(String sourcePath) {
    return saveImage(sourcePath, folder: 'avatars', prefix: 'avatar');
  }
}