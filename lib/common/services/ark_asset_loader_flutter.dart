import 'package:flutter/services.dart' show rootBundle;

Future<String?> loadArkKeyFromAssets() async {
  try {
    final v = await rootBundle.loadString('assets/ark.key');
    return v.trim();
  } catch (_) {
    return null;
  }
}
