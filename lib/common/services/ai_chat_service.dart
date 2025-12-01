import 'dart:convert';
import 'package:http/http.dart' as http;

const String kForumHostBaseUrl = String.fromEnvironment('FORUM_HOST_BASE_URL', defaultValue: 'https://ai.da520.online/v1');
const String kForumHostApiKey = String.fromEnvironment('FORUM_HOST_API_KEY', defaultValue: '');
const String kForumHostModelName = String.fromEnvironment('FORUM_HOST_MODEL_NAME', defaultValue: 'gemini-2.5-flash');

class AiChatMessage {
  final String role;
  final String content;
  AiChatMessage(this.role, this.content);
}

class AiChatService {
  String? _lastError;
  Future<String> send(List<AiChatMessage> messages) async {
    var r1 = await _postChatCompletions(messages);
    if (r1 != null) return r1;
    var r2 = await _postResponses(messages);
    if (r2 != null) return r2;
    final alt = _altBase(kForumHostBaseUrl);
    if (alt != null) {
      r1 = await _postChatCompletions(messages, base: alt);
      if (r1 != null) return r1;
      r2 = await _postResponses(messages, base: alt);
      if (r2 != null) return r2;
    }
    return _lastError != null ? _lastError! : '接口不可用';
  }

  Future<String?> _postChatCompletions(List<AiChatMessage> messages, {String? base}) async {
    final url = Uri.parse(_join(base ?? kForumHostBaseUrl, '/chat/completions'));
    final body = {
      'model': kForumHostModelName,
      'messages': messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
      'temperature': 0.7,
    };
    final headers1 = {
      'Content-Type': 'application/json',
      if (kForumHostApiKey.isNotEmpty) 'Authorization': 'Bearer $kForumHostApiKey',
    };
    final resp1 = await http.post(url, headers: headers1, body: json.encode(body));
    if (resp1.statusCode >= 200 && resp1.statusCode < 300) {
      return _parseChoices(resp1.body);
    }
    _lastError = '接口错误 ${resp1.statusCode}: ${resp1.body}';
    final headers2 = {
      'Content-Type': 'application/json',
      if (kForumHostApiKey.isNotEmpty) 'X-API-Key': kForumHostApiKey,
    };
    final resp2 = await http.post(url, headers: headers2, body: json.encode(body));
    if (resp2.statusCode >= 200 && resp2.statusCode < 300) {
      return _parseChoices(resp2.body);
    }
    _lastError = '接口错误 ${resp2.statusCode}: ${resp2.body}';
    return null;
  }

  Future<String?> _postResponses(List<AiChatMessage> messages, {String? base}) async {
    final lastUser = messages.isNotEmpty ? messages.lastWhere((m) => m.role == 'user', orElse: () => AiChatMessage('user', '')) : AiChatMessage('user', '');
    final url = Uri.parse(_join(base ?? kForumHostBaseUrl, '/responses'));
    final body = {
      'model': kForumHostModelName,
      'input': lastUser.content,
      'temperature': 0.7,
    };
    final headers1 = {
      'Content-Type': 'application/json',
      if (kForumHostApiKey.isNotEmpty) 'Authorization': 'Bearer $kForumHostApiKey',
    };
    final resp1 = await http.post(url, headers: headers1, body: json.encode(body));
    if (resp1.statusCode >= 200 && resp1.statusCode < 300) {
      return _parseResponses(resp1.body);
    }
    _lastError = '接口错误 ${resp1.statusCode}: ${resp1.body}';
    final headers2 = {
      'Content-Type': 'application/json',
      if (kForumHostApiKey.isNotEmpty) 'X-API-Key': kForumHostApiKey,
    };
    final resp2 = await http.post(url, headers: headers2, body: json.encode(body));
    if (resp2.statusCode >= 200 && resp2.statusCode < 300) {
      return _parseResponses(resp2.body);
    }
    _lastError = '接口错误 ${resp2.statusCode}: ${resp2.body}';
    return null;
  }

  String _join(String base, String path) {
    final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return '$b$path';
  }

  String? _altBase(String base) {
    if (base.endsWith('/openai/v1')) return null;
    if (base.endsWith('/v1')) return base.replaceFirst(RegExp(r'/v1$'), '/openai/v1');
    return null;
  }

  String? _parseChoices(String body) {
    final data = json.decode(body);
    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final msg = choices[0]['message'];
      final c = msg['content'];
      if (c is String) return c;
      final t = choices[0]['text'];
      if (t is String) return t;
    }
    return null;
  }

  String? _parseResponses(String body) {
    final data = json.decode(body);
    final ot = data['output_text'];
    if (ot is String && ot.isNotEmpty) return ot;
    final output = data['output'];
    if (output is List && output.isNotEmpty) {
      final c = output[0]['content'];
      if (c is List && c.isNotEmpty) {
        final t = c[0]['text'];
        if (t is String) return t;
        final v = c[0]['content'];
        if (v is String) return v;
      }
    }
    return null;
  }
}
