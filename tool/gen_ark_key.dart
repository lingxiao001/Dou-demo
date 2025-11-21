import 'dart:io';

void main() {
  final f = File('.ark.key');
  if (!f.existsSync()) {
    stderr.writeln('缺少 .ark.key 文件');
    exit(1);
  }
  final v = f.readAsStringSync().trim();
  if (v.isEmpty) {
    stderr.writeln('.ark.key 为空');
    exit(2);
  }
  final out = File('lib/common/LLMapi/key_injected.dart');
  out.writeAsStringSync("const String kInjectedArkApiKey = '$v';\n");
  stdout.writeln('已生成 lib/common/LLMapi/key_injected.dart');
}

