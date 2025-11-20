import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPrefsService {
  static const _kId = 'user_id';
  static const _kNickname = 'user_nickname';
  static const _kAvatarPath = 'user_avatar_path';

  Future<Map<String, String>> load() async {
    final sp = await SharedPreferences.getInstance();
    final id = sp.getString(_kId) ?? 'me';
    final nickname = sp.getString(_kNickname) ?? 'linging';
    final avatar = sp.getString(_kAvatarPath) ?? '';
    return {'id': id, 'nickname': nickname, 'avatar': avatar};
  }

  Future<void> saveNickname(String nickname) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kNickname, nickname);
  }

  Future<String> saveAvatarFile(File file) async {
    final dir = await getApplicationSupportDirectory();
    final dst = File(p.join(dir.path, 'profile_avatar.jpg'));
    await dst.writeAsBytes(await file.readAsBytes());
    final path = 'file://${dst.path}';
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAvatarPath, path);
    return path;
  }
}

