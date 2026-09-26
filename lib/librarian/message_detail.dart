import 'package:flutter/material.dart';
import 'librarian_nav.dart';

class MessageDetail extends StatelessWidget {
  const MessageDetail({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        LibTitleHeader(title: 'Tin nhắn', showBack: true, color: Colors.white),
        Expanded(child: Center(child: Text('Chưa có dữ liệu hội thoại'))),
      ],
    ),
  );
}
