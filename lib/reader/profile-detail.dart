import 'package:flutter/material.dart';
import 'package:libary_management/reader/reader_nav.dart';

class ProfileDetail extends StatelessWidget {
  const ProfileDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          BeigeHeader(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                const CircleAvatar(
                  radius: 64,
                  backgroundColor: kBeigeSoft,
                  child: Icon(Icons.person, size: 64, color: kBrownTitle),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_camera_outlined, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Đổi ảnh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              children: const [
                SectionCard(
                  title: 'Thông tin',
                  child: Column(
                    children: [
                      MenuRow(label: 'Họ và tên: Trần Ngọc An'),
                      MenuRow(label: 'Mã độc giả: M1', icon: Icons.tag),
                      MenuRow(
                        label: 'Ngày sinh: 27/7/2727',
                        icon: Icons.cake_outlined,
                      ),
                      MenuRow(
                        label: 'Số điện thoại: 02727272727',
                        icon: Icons.phone_outlined,
                      ),
                      MenuRow(
                        label: 'Địa chỉ: 27 trần văn phú',
                        icon: Icons.home_outlined,
                      ),
                      MenuRow(
                        label: 'Email: 2727@gmail.com',
                        icon: Icons.email_outlined,
                      ),
                      MenuRow(
                        label: 'Đổi mật khẩu',
                        icon: Icons.lock_outline,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
