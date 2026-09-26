import 'package:flutter/material.dart';
import 'librarian_nav.dart';

class MessageAll extends StatelessWidget {
  const MessageAll({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        LibTitleHeader(title: 'Tin nhắn', color: Colors.white, showBack: true),
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Backend hiện chưa cung cấp API tin nhắn.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
