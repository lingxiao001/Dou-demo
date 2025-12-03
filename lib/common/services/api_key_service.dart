import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'ark_asset_loader_stub.dart' if (dart.library.ui) 'ark_asset_loader_flutter.dart';

class ApiKeyService {
  Future<String?> loadArkKey() async {
    final env = const String.fromEnvironment('ARK_API_KEY', defaultValue: '');
    if (env.isNotEmpty) return env;
    try {
      final support = await getApplicationSupportDirectory();
      final f1 = File(p.join(support.path, 'ark.key'));
      if (await f1.exists()) {
        final v = (await f1.readAsString()).trim();
        if (v.isNotEmpty) return v;
      }
    } catch (_) {}
    try {
      final f2 = File('.ark.key');
      if (await f2.exists()) {
        final v = (await f2.readAsString()).trim();
        if (v.isNotEmpty) return v;
      }
    } catch (_) {}
    try {
      final f3 = File('d\\douyin_demo\\.ark.key');
      if (await f3.exists()) {
        final v = (await f3.readAsString()).trim();
        if (v.isNotEmpty) return v;
      }
    } catch (_) {}
    try {
      final v = (await loadArkKeyFromAssets())?.trim();
      if (v != null && v.isNotEmpty) return v;
    } catch (_) {}
    return null;
  }

  Future<void> saveArkKey(String key) async {
    final support = await getApplicationSupportDirectory();
    final f = File(p.join(support.path, 'ark.key'));
    await f.writeAsString(key.trim());
  }
}

