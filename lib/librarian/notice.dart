import 'package:flutter/material.dart';

import 'librarian_nav.dart';

class Notice extends StatelessWidget {
  const Notice({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const LibTitleHeader(title: 'Thông báo', showBack: true),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _NoticeCard(
                  date: 'Ngày 27/7/2727',
                  time: '10:21',
                  message: 'Thông báo: Có yêu cầu mượn sách cần được xác nhận.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.date,
    required this.time,
    required this.message,
  });

  final String date;
  final String time;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: kLibBeigeButton,
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  date,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(time, style: const TextStyle(color: kLibBrownTitle)),
              const SizedBox(width: 8),
              const Icon(Icons.notifications_outlined, color: kLibBrownTitle),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: kLibCardFill,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: kLibBookTitle,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
