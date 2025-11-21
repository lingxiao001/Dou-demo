import 'dart:io';
import 'package:douyin_demo/common/LLMapi/llm_api.dart';

Future<void> main() async {
  final apiKeyFile = File('.ark.key');
  if (!apiKeyFile.existsSync()) {
    stderr.writeln('缺少 .ark.key');
    exit(1);
  }
  final api = LLMapi();
  try {
    final r = await api.chatVision(
      imageUrl: 'https://ark-project.tos-cn-beijing.volces.com/images/view.jpeg',
      prompt: '图片主要讲了什么?'
    );
    stdout.writeln(r);
  } catch (e) {
    stderr.writeln(e);
    exit(2);
  }
}

