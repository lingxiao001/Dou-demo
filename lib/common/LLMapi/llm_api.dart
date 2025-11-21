import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:douyin_demo/common/services/api_key_service.dart';
import 'package:douyin_demo/common/LLMapi/key_injected.dart';

class LLMapi {
  final String base;
  final String model;
  final String? apiKey;
  LLMapi({String? base, String? model, String? apiKey})
      : base = base ?? 'https://ark.cn-beijing.volces.com/api/v3',
        model = model ?? 'doubao-1-5-vision-pro-32k-250115',
        apiKey = apiKey;

  Future<String> chatVision({required String imageUrl, required String prompt}) async {
    final url = Uri.parse(_join(base, '/chat/completions'));
    final body = {
      'model': model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image_url',
              'image_url': {'url': imageUrl}
            },
            {
              'type': 'text',
              'text': prompt
            }
          ]
        }
      ]
    };
    final env = const String.fromEnvironment('ARK_API_KEY', defaultValue: '');
    String key = '';
    if (kInjectedArkApiKey.isNotEmpty) {
      key = kInjectedArkApiKey;
    } else if ((apiKey ?? '').isNotEmpty) {
      key = apiKey!;
    } else if (env.isNotEmpty) {
      key = env;
    } else {
      key = await ApiKeyService().loadArkKey() ?? '';
    }
    final headers1 = {
      'Content-Type': 'application/json',
      if (key.isNotEmpty) 'Authorization': 'Bearer $key',
    };
    final resp = await http.post(url, headers: headers1, body: json.encode(body));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final data = json.decode(resp.body);
      final choices = data['choices'];
      if (choices is List && choices.isNotEmpty) {
        final msg = choices[0]['message'];
        final c = msg['content'];
        if (c is String) return c;
      }
      throw StateError('响应解析失败');
    }
    final headers2 = {
      'Content-Type': 'application/json',
      if (key.isNotEmpty) 'X-API-Key': key,
    };
    final resp2 = await http.post(url, headers: headers2, body: json.encode(body));
    if (resp2.statusCode >= 200 && resp2.statusCode < 300) {
      final data = json.decode(resp2.body);
      final choices = data['choices'];
      if (choices is List && choices.isNotEmpty) {
        final msg = choices[0]['message'];
        final c = msg['content'];
        if (c is String) return c;
      }
      throw StateError('响应解析失败');
    }
    throw HttpException('接口错误 ${resp2.statusCode}: ${resp2.body}');
  }

  String _join(String base, String path) {
    final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return '$b$path';
  }
}
