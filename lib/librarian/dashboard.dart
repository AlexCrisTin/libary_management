import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const ShapeDecoration(
                color: Color(0xFFDBB9A0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 29,
                    height: 29,
                    decoration: const ShapeDecoration(
                      color: Color(0xFFEFE2D9),
                      shape: OvalBorder(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Name
                  const Text(
                    'Lê Văn Lê',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  // Notification icon placeholder
                  Container(width: 49, height: 49, child: const Stack()),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Welcome text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Chào mừng',
                  style: TextStyle(
                    color: Color(0xFF8A6060),
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // Content area
            const Spacer(),
            // FAB area (add button)
            Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 67,
                  height: 67,
                  decoration: const ShapeDecoration(
                    color: Color(0xFFEFE2D9),
                    shape: OvalBorder(),
                  ),
                  child: const Stack(),
                ),
              ),
            ),
            // Bottom navigation bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
              height: 61,
              decoration: ShapeDecoration(
                color: const Color(0xFFEFE2D9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(width: 45, height: 45, child: const Stack()),
                  Container(width: 45, height: 45, child: const Stack()),
                  Container(width: 45, height: 45, child: const Stack()),
                  Container(width: 45, height: 45, child: const Stack()),
                  Container(width: 45, height: 45, child: const Stack()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}