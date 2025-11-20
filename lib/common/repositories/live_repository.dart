import 'dart:convert';
import 'package:douyin_demo/common/models/group_deal.dart';
import 'package:douyin_demo/common/models/live_room.dart';
import 'package:douyin_demo/common/models/user.dart';
import 'package:flutter/services.dart';

class LiveRepository {
  Future<List<LiveRoom>> fetchLiveRooms() async {
    final s = await rootBundle.loadString('assets/mock/live_rooms.json');
    final List<dynamic> j = json.decode(s);
    return j.map((e) {
      final h = e['host'];
      return LiveRoom(
        id: e['id'],
        title: e['title'],
        coverUrl: e['coverUrl'],
        viewerCount: e['viewerCount'],
        host: User(id: h['id'], nickname: h['nickname'], avatarUrl: h['avatarUrl']),
      );
    }).toList();
  }

  Future<List<GroupDeal>> fetchGroupDeals() async {
    final s = await rootBundle.loadString('assets/mock/group_deals.json');
    final List<dynamic> j = json.decode(s);
    return j.map((e) {
      return GroupDeal(
        id: e['id'],
        title: e['title'],
        imageUrl: e['imageUrl'],
        price: (e['price'] as num).toDouble(),
        originalPrice: (e['originalPrice'] as num).toDouble(),
        soldCount: e['soldCount'],
      );
    }).toList();
  }
}

