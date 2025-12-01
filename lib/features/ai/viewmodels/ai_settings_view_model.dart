import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:douyin_demo/common/services/api_key_service.dart';

class AiSettings {
  final String baseUrl;
  final String apiKey;
  const AiSettings({required this.baseUrl, required this.apiKey});
}

class AiSettingsViewModel extends AsyncNotifier<AiSettings> {
  @override
  Future<AiSettings> build() async {
    final sp = await SharedPreferences.getInstance();
    final savedBase = sp.getString('ark_base_url');
    final envBase = const String.fromEnvironment('ARK_BASE_URL', defaultValue: '');
    final baseDefault = 'https://ark.cn-beijing.volces.com/api/v3';
    final base = (savedBase != null && savedBase.isNotEmpty) ? savedBase : (envBase.isNotEmpty ? envBase : baseDefault);

    final envKey = const String.fromEnvironment('ARK_API_KEY', defaultValue: '');
    final key = envKey.isNotEmpty ? envKey : (await ApiKeyService().loadArkKey() ?? '');

    return AiSettings(baseUrl: base, apiKey: key);
  }

  Future<void> saveApiKey(String apiKey) async {
    await ApiKeyService().saveArkKey(apiKey);
    final s = state.valueOrNull;
    state = AsyncData(AiSettings(baseUrl: s?.baseUrl ?? 'https://ark.cn-beijing.volces.com/api/v3', apiKey: apiKey));
  }

  Future<void> saveBaseUrl(String baseUrl) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('ark_base_url', baseUrl.trim());
    final s = state.valueOrNull;
    state = AsyncData(AiSettings(baseUrl: baseUrl.trim(), apiKey: s?.apiKey ?? ''));
  }
}

final aiSettingsProvider = AsyncNotifierProvider<AiSettingsViewModel, AiSettings>(AiSettingsViewModel.new);
