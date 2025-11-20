import 'package:douyin_demo/common/models/live_room.dart';
import 'package:douyin_demo/common/repositories/live_repository.dart';
import 'package:flutter/material.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  late Future<List<LiveRoom>> _future;

  @override
  void initState() {
    super.initState();
    _future = LiveRepository().fetchLiveRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F4),
      body: FutureBuilder<List<LiveRoom>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3 / 4,
            ),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final r = list[i];
              return Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, spreadRadius: 1, offset: const Offset(0, 2))]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(child: Image.network(r.coverUrl, fit: BoxFit.cover)),
                            Positioned(
                              left: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                                child: const Text('直播中', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                                child: Row(children: [const Icon(Icons.visibility, color: Colors.white, size: 14), const SizedBox(width: 4), Text('${r.viewerCount}', style: const TextStyle(color: Colors.white, fontSize: 12))]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            CircleAvatar(radius: 12, backgroundImage: NetworkImage(r.host.avatarUrl)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

