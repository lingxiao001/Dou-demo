import 'package:douyin_demo/common/services/ai_chat_service.dart';
import 'package:douyin_demo/common/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../viewmodels/ai_settings_view_model.dart';

class AiChatSheet extends ConsumerStatefulWidget {
  const AiChatSheet({super.key});
  @override
  ConsumerState<AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends ConsumerState<AiChatSheet> {
  final List<AiChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _messages.add(AiChatMessage('user', text));
      _loading = true;
      _controller.clear();
    });
    final svc = ref.read(aiChatServiceProvider);
    final reply = await svc.send(_messages);
    if (!mounted) return;
    setState(() {
      _messages.add(AiChatMessage('assistant', reply));
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Expanded(child: Text('AI聊天', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                  IconButton(
                    icon: const Icon(Icons.link),
                    onPressed: () async {
                      final ctrl = TextEditingController();
                      final v = await showDialog<String>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('设置 Base URL'),
                          content: TextField(controller: ctrl),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                            TextButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('保存')),
                          ],
                        ),
                      );
                      if (v != null && v.isNotEmpty) {
                        await ref.read(aiSettingsProvider.notifier).saveBaseUrl(v);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.vpn_key),
                    onPressed: () async {
                      final ctrl = TextEditingController();
                      final v = await showDialog<String>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('设置 API Key'),
                          content: TextField(controller: ctrl, obscureText: true),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                            TextButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('保存')),
                          ],
                        ),
                      );
                      if (v != null && v.isNotEmpty) {
                        await ref.read(aiSettingsProvider.notifier).saveApiKey(v);
                      }
                    },
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  final isMe = m.role == 'user';
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blueAccent : const Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(m.content, style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(hintText: '输入内容...', border: OutlineInputBorder()),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _send,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
                        child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('发送', style: TextStyle(color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
