import 'package:douyin_demo/features/feed/views/feed_screen.dart';
import 'package:douyin_demo/features/viewer/views/viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:douyin_demo/common/providers/app_providers.dart';
import 'package:douyin_demo/common/services/video_asset_cache_service.dart';
import 'package:flutter/foundation.dart';
import 'package:douyin_demo/features/profile/views/profile_screen.dart' as douyin_profile;

void main() {
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _warmUp());
  }

  Future<void> _warmUp() async {
    try {
      final repo = ref.read(videoRepositoryProvider);
      final posts = await repo.fetchVideoPosts();
      if (!kIsWeb) {
        final svc = VideoAssetCacheService();
        final toPrefetch = posts.take(5).map((p) => p.videoUrl).toList();
        await svc.prefetch(toPrefetch);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        if (name == 'profile') {
          return MaterialPageRoute(builder: (_) => const douyin_profile.ProfileScreen());
        }
        if (name.startsWith('viewer/')) {
          final parts = name.split('/');
          final idx = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
          return MaterialPageRoute(builder: (_) => ViewerScreen(initialIndex: idx));
        }
        return MaterialPageRoute(builder: (_) => const FeedScreen());
      },
    );
  }
}
