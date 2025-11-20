import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:douyin_demo/common/services/user_prefs_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart' show MissingPluginException;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _prefs = UserPrefsService();
  String _nickname = '';
  String _avatarPath = '';
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final m = await _prefs.load();
    setState(() {
      _nickname = m['nickname'] ?? 'linging';
      _avatarPath = m['avatar'] ?? '';
    });
  }

  ImageProvider _avatarProvider() {
    if (_avatarPath.startsWith('file://')) {
      return FileImage(File(_avatarPath.replaceFirst('file://', '')));
    }
    return NetworkImage(_avatarPath.isNotEmpty
        ? _avatarPath
        : 'https://picsum.photos/seed/me/200');
  }

  Future<void> _pickAvatar() async {
    try {
      if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
        if (Platform.isAndroid) {
          try {
            final status = await Permission.storage.request();
            if (!status.isGranted) {
              // 不中断流程，交由 image_picker 处理或系统 Photo Picker 弹窗
            }
          } on MissingPluginException {
            // 插件未注册时忽略，直接尝试打开图库
          } catch (_) {
            // 其它异常忽略，直接尝试打开图库
          }
        }
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
        if (picked == null) return;
        final path = await _prefs.saveAvatarFile(File(picked.path));
        setState(() {
          _avatarPath = path;
        });
      } else {
        final group = const XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png']);
        final xf = await openFile(acceptedTypeGroups: [group]);
        if (xf == null) return;
        final path = await _prefs.saveAvatarFile(File(xf.path));
        setState(() {
          _avatarPath = path;
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('头像已更新')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('更换头像失败: $e')));
    }
  }

  Future<void> _editNickname() async {
    final controller = TextEditingController(text: _nickname);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('编辑昵称'),
          content: TextField(controller: controller, maxLength: 20),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('保存')),
          ],
        );
      },
    );
    if (newName != null && newName.isNotEmpty) {
      await _prefs.saveNickname(newName);
      setState(() {
        _nickname = newName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('我', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings, color: Colors.black87)),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(radius: 34, backgroundImage: _avatarProvider()),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: InkWell(
                          onTap: _pickAvatar,
                          child: Container(
                            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.add, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_nickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: Colors.blueAccent, size: 18),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Wrap(
                          spacing: 16,
                          runSpacing: 4,
                          children: [
                            _StatItem(label: '获赞', value: '6'),
                            _StatItem(label: '关注', value: '10'),
                            _StatItem(label: '粉丝', value: '0'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: _editNickname,
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 10)),
                      child: const Text('编辑主页'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F7), borderRadius: BorderRadius.circular(8)),
              child: const Text('( ु•͈ᴗ•͈)ु  添加标签更懂你', style: TextStyle(color: Colors.black54)),
            ),
          ),
          SliverToBoxAdapter(
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54,
              tabs: const [Tab(text: '作品'), Tab(text: '收藏'), Tab(text: '喜欢')],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _GridPlaceholder(),
                _GridPlaceholder(),
                _GridPlaceholder(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [Text(value, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 4), Text(label)]);
  }
}

class _GridPlaceholder extends StatelessWidget {
  const _GridPlaceholder();
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 6, crossAxisSpacing: 6),
      itemCount: 12,
      itemBuilder: (_, i) {
        return Container(color: Colors.grey.shade200, child: const Icon(Icons.video_collection, color: Colors.black26));
      },
    );
  }
}
