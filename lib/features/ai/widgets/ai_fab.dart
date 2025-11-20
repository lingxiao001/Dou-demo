import 'package:douyin_demo/features/ai/views/ai_chat_sheet.dart';
import 'package:flutter/material.dart';

class AiFloatingBall extends StatefulWidget {
  const AiFloatingBall({super.key});
  @override
  State<AiFloatingBall> createState() => _AiFloatingBallState();
}

class _AiFloatingBallState extends State<AiFloatingBall> {
  Offset _offset = const Offset(0, 0);
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pos = Offset(size.width - 72 + _offset.dx, size.height - 180 + _offset.dy);
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Draggable(
        feedback: _ball(),
        childWhenDragging: const SizedBox.shrink(),
        onDragEnd: (d) {
          setState(() {
            _offset = Offset(d.offset.dx - (size.width - 72), d.offset.dy - (size.height - 180));
          });
        },
        child: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const SizedBox(height: 600, child: AiChatSheet()),
            );
          },
          child: _ball(),
        ),
      ),
    );
  }

  Widget _ball() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: Colors.black87, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)]),
      child: const Center(child: Icon(Icons.smart_toy, color: Colors.white)),
    );
  }
}

