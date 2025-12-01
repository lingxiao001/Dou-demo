import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:douyin_demo/common/repositories/video_repository.dart';
import 'package:douyin_demo/common/services/user_prefs_service.dart';
import 'package:douyin_demo/common/LLMapi/llm_api.dart';
import 'package:douyin_demo/common/services/ai_chat_service.dart';
import 'package:douyin_demo/features/ai/viewmodels/ai_settings_view_model.dart';

final videoRepositoryProvider = Provider((ref) => VideoRepository());
final userPrefsServiceProvider = Provider((ref) => UserPrefsService());
final llmApiProvider = Provider((ref) {
  final settings = ref.watch(aiSettingsProvider).valueOrNull;
  if (settings == null) {
    return LLMapi();
  }
  return LLMapi(base: settings.baseUrl, apiKey: settings.apiKey);
});

final aiChatServiceProvider = Provider((ref) {
  final settings = ref.watch(aiSettingsProvider).valueOrNull;
  return AiChatService(baseUrl: settings?.baseUrl, apiKey: settings?.apiKey);
});
