import 'package:flutter/material.dart';

class ProfileAdmin extends StatelessWidget {
  const ProfileAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with avatar and name
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                    width: 118,
                    height: 118,
                    decoration: const ShapeDecoration(
                      color: Color(0xFFEFE2D9),
                      shape: OvalBorder(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Lê Văn Lê',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '@st.phenikaa-uni.edu.vn',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // Tài khoản section
                    _sectionHeader('Tài khoản'),
                    Container(
                      decoration: const ShapeDecoration(
                        color: Color(0xFFF7F0EA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(5),
                            bottomRight: Radius.circular(5),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          _settingRow(
                            icon: Container(
                                width: 45,
                                height: 45,
                                child: const Stack()),
                            title: 'Thông tin cá nhân',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Cài đặt khác section
                    _sectionHeader('Cài đặt khác'),
                    Container(
                      decoration: const ShapeDecoration(
                        color: Color(0xFFF7F0EA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(5),
                            bottomRight: Radius.circular(5),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          _settingRow(
                            icon: Container(
                                width: 45,
                                height: 45,
                                child: const Stack()),
                            title: 'Cài đặt',
                          ),
                          const Divider(height: 1),
                          _settingRow(
                            icon: Container(
                                width: 45,
                                height: 45,
                                child: const Stack()),
                            title: 'Thông tin khác',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Logout button
                    Container(
                      width: 151,
                      height: 46,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFF16F6F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Đăng xuất',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom nav
            Container(
              margin: const EdgeInsets.fromLTRB(26, 0, 26, 8),
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

  Widget _sectionHeader(String title) {
    return Container(
      width: double.infinity,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: ShapeDecoration(
        color: const Color(0xFFE2C5B5),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _settingRow({required Widget icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF8A6060),
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(width: 24, height: 24, child: const Stack()),
        ],
      ),
    );
  }
}