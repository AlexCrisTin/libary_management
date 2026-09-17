import 'package:flutter/material.dart';
import 'package:libary_management/reader/home.dart';

void openReaderTab(BuildContext context, int index) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => Home(initialIndex: index)),
    (route) => route.isFirst,
  );
}
