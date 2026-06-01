import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';

class AIAssistant {
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _defaultModel = 'openai/gpt-4o-mini';
  static const int _maxTokens = 500;
  static const double _temperature = 0.7;

  static Future<String> sendMessage(String userMessage) async {
    final apiKey = await SecureStorageService().getOpenRouterKey();
    if (apiKey == null || apiKey.isEmpty) {
      return 'Ошибка: API-ключ не найден. Обратитесь в поддержку.';
    }

    final url = Uri.parse(_baseUrl);
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'model': _defaultModel,
      'messages': [
        {
          'role': 'system',
          'content': 'Ты — ассистент поддержки сервиса аренды. Отвечай вежливо, понятно и по делу. Если не знаешь ответа или проблема требует вмешательства человека, напиши фразу "Нужен оператор".'
        },
        {
          'role': 'user',
          'content': userMessage,
        },
      ],
      'max_tokens': _maxTokens,
      'temperature': _temperature,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'] as String;
        return reply;
      } else {
        debugPrint('OpenRouter error: ${response.statusCode} - ${response.body}');
        return 'Извините, произошла техническая ошибка. Попробуйте позже или обратитесь в поддержку.';
      }
    } catch (e) {
      debugPrint('OpenRouter exception: $e');
      return 'Не удалось связаться с сервером. Проверьте интернет-соединение.';
    }
  }

  static bool needsOperator(String aiResponse) {
    return aiResponse.contains('Нужен оператор');
  }
}