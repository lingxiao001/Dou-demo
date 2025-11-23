import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:douyin_demo/common/repositories/video_repository.dart';
import 'package:douyin_demo/common/services/user_prefs_service.dart';
import 'package:douyin_demo/common/LLMapi/llm_api.dart';
import 'package:douyin_demo/common/services/ai_chat_service.dart';

final videoRepositoryProvider = Provider((ref) => VideoRepository());
final userPrefsServiceProvider = Provider((ref) => UserPrefsService());
final llmApiProvider = Provider((ref) => LLMapi());
final aiChatServiceProvider = Provider((ref) => AiChatService());

