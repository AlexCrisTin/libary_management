import 'package:flutter/material.dart';
import 'package:libary_management/reader/reader_nav.dart';

class Notice extends StatelessWidget {
  const Notice({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        TitleHeader(title: 'Thông báo', showBack: true),
        Expanded(child: Center(child: Text('Chưa có thông báo'))),
      ],
    ),
  );
}
