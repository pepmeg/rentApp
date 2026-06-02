import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:version/version.dart';

class GitHubUpdateService {
  static const String repoOwner = 'pepmeg';
  static const String repoName = 'rentApp';
  static const String githubApiUrl = 'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);

      final response = await http.get(Uri.parse(githubApiUrl));
      if (response.statusCode != 200) {
        debugPrint('Не удалось получить информацию о релизе: ${response.statusCode}');
        return;
      }

      final data = jsonDecode(response.body);
      final tagName = data['tag_name'] as String;
      final body = data['body'] as String? ?? 'Исправлены ошибки и улучшена стабильность работы приложения.';

      String? apkUrl;
      final assets = data['assets'] as List;
      for (final asset in assets) {
        if (asset['name'].toString().endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String;
          break;
        }
      }

      if (apkUrl == null) {
        debugPrint('APK файл не найден в последнем релизе');
        return;
      }

      final cleanTag = tagName.startsWith('v') ? tagName.substring(1) : tagName;
      final latestVersion = Version.parse(cleanTag);

      if (latestVersion > currentVersion) {
        _showUpdateDialog(
          context,
          currentVersion: currentVersion.toString(),
          newVersion: latestVersion.toString(),
          releaseNotes: body,
          apkUrl: apkUrl,
        );
      }
    } catch (e) {
      debugPrint('Ошибка проверки обновлений: $e');
    }
  }

  static void _showUpdateDialog(
      BuildContext context, {
        required String currentVersion,
        required String newVersion,
        required String releaseNotes,
        required String apkUrl,
      }) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.rocket_launch, color: theme.primaryColor, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Доступно обновление!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Новая версия $newVersion уже ждет вас',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.primaryColor.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.new_releases, size: 18, color: theme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Что нового:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      releaseNotes,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Позже',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _showDownloadDialog(context, apkUrl, newVersion);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Обновить',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showDownloadDialog(BuildContext context, String url, String version) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DownloadProgressDialog(url: url, version: version),
    );
  }
}

class _DownloadProgressDialog extends StatefulWidget {
  final String url;
  final String version;
  const _DownloadProgressDialog({required this.url, required this.version});

  @override
  State<_DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0.0;
  String _status = 'Подготовка к загрузке...';

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.requestInstallPackages.request();
        if (!status.isGranted) {
          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Разрешите установку приложений из этого источника в настройках'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          );
          return;
        }
      }

      setState(() => _status = 'Скачивание обновления...');

      final dio = Dio();
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/rentapp_update_v${widget.version}.apk';

      await dio.download(
        widget.url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _progress = received / total;
              _status = 'Загружено ${_formatBytes(received)} из ${_formatBytes(total)}';
            });
          }
        },
      );

      if (!mounted) return;
      setState(() => _status = 'Запуск установщика...');

      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pop(context);

      final result = await OpenFile.open(savePath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка установки: ${result.message}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _progress >= 1.0 ? Icons.check_circle : Icons.downloading,
                  color: theme.primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _status,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_progress > 0 && _progress < 1.0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 10,
                    backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${(_progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ] else if (_progress >= 1.0) ...[
                const SizedBox(height: 12),
                Text(
                  'Готово! Устанавливаем...',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}