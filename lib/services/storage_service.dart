import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:minio/minio.dart';
import 'package:minio/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';

class StorageService {
  static const String _bucketName = 'apprent-storage';
  static const String _endpoint = 's3.cloud.ru';
  static Minio? _minio;
  static bool _isInitialized = false;

  static Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    final keys = await SecureStorageService().getMinioKeys();
    if (keys['access'] == null || keys['access']!.isEmpty || keys['secret'] == null || keys['secret']!.isEmpty) {
      throw Exception('Minio keys not found in secure storage');
    }
    _minio = Minio(
      endPoint: _endpoint,
      accessKey: keys['access']!,
      secretKey: keys['secret']!,
      region: 'ru-central-1',
      useSSL: true,
      pathStyle: true,
    );
    _isInitialized = true;
  }

  static const String _cacheKey = 'presigned_url_cache_v2';
  static Map<String, _CachedEntry> _urlCache = {};

  static Future<void> _loadCache() async {
    if (_urlCache.isNotEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_cacheKey);
    if (data != null) {
      try {
        final decoded = json.decode(data) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          final entry = _CachedEntry.fromJson(value);
          if (!entry.isExpired()) {
            _urlCache[key] = entry;
          }
        });
      } catch (_) {}
    }
  }

  static Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _urlCache.map((key, entry) => MapEntry(key, entry.toJson()));
    await prefs.setString(_cacheKey, json.encode(map));
  }

  static Future<String> _upload(String localPath, String folder, {String? oldKey}) async {
    await _ensureInitialized();
    if (oldKey != null && oldKey.isNotEmpty) {
      await _deleteObject(oldKey);
      _urlCache.remove(oldKey);
      await _saveCache();
    }
    final objectKey = '$folder/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _minio!.fPutObject(_bucketName, objectKey, localPath);
    return objectKey;
  }

  static Future<String> uploadProductImage(String localPath, {String? oldKey}) =>
      _upload(localPath, 'products', oldKey: oldKey);

  static Future<String> uploadAvatar(String localPath, {String? oldKey}) =>
      _upload(localPath, 'avatars', oldKey: oldKey);

  static Future<String> uploadChatImage(String localPath) =>
      _upload(localPath, 'chat_images');

  static Future<String> getDownloadUrl(String objectKey, {bool cache = false}) async {
    await _ensureInitialized();
    await _loadCache();

    if (_urlCache.containsKey(objectKey)) {
      final entry = _urlCache[objectKey]!;
      if (!entry.isExpired()) {
        return entry.url;
      } else {
        _urlCache.remove(objectKey);
      }
    }

    try {
      final expiresInSeconds = 7 * 24 * 60 * 60;
      final url = await _minio!.presignedGetObject(
        _bucketName,
        objectKey,
        expires: expiresInSeconds,
      ).timeout(const Duration(seconds: 15));

      _urlCache[objectKey] = _CachedEntry(
        url: url,
        expiresAt: DateTime.now().add(Duration(seconds: expiresInSeconds)),
      );
      if (cache) await _saveCache();
      return url;
    } catch (e) {
      if (_urlCache.containsKey(objectKey)) {
        return _urlCache[objectKey]!.url;
      }
      rethrow;
    }
  }

  static String? getCachedUrlSync(String objectKey) {
    final entry = _urlCache[objectKey];
    if (entry != null && !entry.isExpired()) {
      return entry.url;
    }
    return null;
  }

  static Future<String?> getCachedUrl(String objectKey) async {
    await _loadCache();
    final entry = _urlCache[objectKey];
    if (entry != null && !entry.isExpired()) {
      return entry.url;
    }
    return null;
  }

  static Future<void> deleteImage(String objectKey) async {
    await _ensureInitialized();
    try {
      await _minio!.removeObject(_bucketName, objectKey);
    } catch (e) {
      debugPrint('Ошибка удаления $objectKey: $e');
    }
  }

  static Future<void> _deleteObject(String objectKey) async {
    await _ensureInitialized();
    await _minio!.removeObject(_bucketName, objectKey);
  }
}

class _CachedEntry {
  final String url;
  final DateTime expiresAt;

  _CachedEntry({required this.url, required this.expiresAt});

  bool isExpired() => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
    'url': url,
    'expiresAt': expiresAt.toIso8601String(),
  };

  factory _CachedEntry.fromJson(dynamic data) {
    final map = data as Map<String, dynamic>;
    return _CachedEntry(
      url: map['url'] as String,
      expiresAt: DateTime.parse(map['expiresAt'] as String),
    );
  }
}
