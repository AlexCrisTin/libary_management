import 'package:flutter/material.dart';

import 'librarian_nav.dart';
import 'message_detail.dart';

class MessageAll extends StatelessWidget {
  const MessageAll({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const LibTitleHeader(title: 'Tin nhắn', color: Colors.white),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm cuộc trò chuyện',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: kLibCardFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: const [
                _ConversationTile(
                  name: 'Trần Ngọc An',
                  preview: 'Em cần hỗ trợ gia hạn sách Toán cao cấp.',
                  time: '10:10',
                ),
                _ConversationTile(
                  name: 'Nguyễn Văn Bình',
                  preview: 'Sách em mượn đã sẵn sàng để nhận.',
                  time: 'Hôm qua',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.name,
    required this.preview,
    required this.time,
  });

  final String name;
  final String preview;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kLibCardFill,
      elevation: 0,
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MessageDetail()),
        ),
        contentPadding: const EdgeInsets.all(12),
        leading: const CircleAvatar(
          backgroundColor: kLibBeigeSoft,
          child: Icon(Icons.person, color: kLibBrownTitle),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: kLibBrownTitle,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text(time, style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}
