import 'package:flutter/material.dart';

class ProfileAdminDetail extends StatelessWidget {
  const ProfileAdminDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
              decoration: const ShapeDecoration(
                color: Color(0xFFDBB9A0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  // Avatar
                  Center(
                    child: Container(
                      width: 135,
                      height: 135,
                      decoration: const ShapeDecoration(
                        color: Color(0xFFEFE2D9),
                        shape: OvalBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.photo_camera_outlined,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Đổi ảnh',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
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
                    // Thông tin section
                    _sectionHeader('Thông tin'),
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
                          _infoRow('Họ và tên: Lê Văn Lê'),
                          _divider(),
                          _infoRow('Mã: GV1'),
                          _divider(),
                          _infoRow('Ngày sinh: 27/7/2727'),
                          _divider(),
                          _infoRow('Số điện thoại: 02727272727'),
                          _divider(),
                          _infoRow('Địa chỉ: 27 trần văn phú'),
                          _divider(),
                          _infoRow('Email:2727@gmail.com'),
                          _divider(),
                          _infoRow('Đổi mật khẩu'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
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

  Widget _infoRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
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

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16);
}
