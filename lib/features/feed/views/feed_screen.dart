import 'package:douyin_demo/features/feed/views/feed_grid_screen.dart';
import 'package:douyin_demo/features/profile/views/profile_screen.dart' as douyin_profile;
import 'package:flutter/material.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _bottomIndex = 0;

  final List<String> _tabs = ["热点", "直播", "精选", "团购", "经"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: 2);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    PreferredSizeWidget? appBar;
    if (_bottomIndex == 0) {
      appBar = AppBar(
        title: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 16),
          tabs: _tabs.map((title) => Tab(text: title)).toList(),
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey.shade600,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 28),
            onPressed: () {},
          ),
        ],
      );
      body = TabBarView(
        controller: _tabController,
        children: [
          const Center(child: Text("热点内容")),
          const Center(child: Text("直播内容")),
          FeedGridScreen(onSwitchTab: (i) {
            _tabController.animateTo(i);
          }),
          const Center(child: Text("团购内容")),
          const Center(child: Text("经内容")),
        ],
      );
    } else if (_bottomIndex == 4) {
      body = const SizedBox.expand(child: douyin_profile.ProfileScreen());
    } else {
      body = const Center(child: Text('暂未实现'));
    }

    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: '朋友',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_rounded, size: 36),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: '消息',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我',
          ),
        ],
        currentIndex: _bottomIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (i) {
          setState(() {
            _bottomIndex = i;
          });
        },
      ),
    );
  }
}
