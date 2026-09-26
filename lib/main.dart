import 'package:flutter/material.dart';
import 'package:libary_management/login/begin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Library Management',
      debugShowCheckedModeBanner: false,
      home: Begin(),
    );
  }
}
