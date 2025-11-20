import 'package:douyin_demo/common/models/group_deal.dart';
import 'package:douyin_demo/common/repositories/live_repository.dart';
import 'package:flutter/material.dart';

class GroupBuyScreen extends StatefulWidget {
  const GroupBuyScreen({super.key});

  @override
  State<GroupBuyScreen> createState() => _GroupBuyScreenState();
}

class _GroupBuyScreenState extends State<GroupBuyScreen> {
  late Future<List<GroupDeal>> _future;

  @override
  void initState() {
    super.initState();
    _future = LiveRepository().fetchGroupDeals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F4),
      body: FutureBuilder<List<GroupDeal>>(
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
              final d = list[i];
              return Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, spreadRadius: 1, offset: const Offset(0, 2))]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Column(
                    children: [
                      Expanded(child: Image.network(d.imageUrl, fit: BoxFit.cover, width: double.infinity)),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text('¥${d.price.toStringAsFixed(1)}', style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Text('¥${d.originalPrice.toStringAsFixed(1)}', style: const TextStyle(color: Colors.black38, decoration: TextDecoration.lineThrough)),
                                const Spacer(),
                                Text('已售${d.soldCount}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                              ],
                            ),
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

