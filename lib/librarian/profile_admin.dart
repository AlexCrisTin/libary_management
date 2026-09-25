import 'package:flutter/material.dart';
import 'package:libary_management/login/login.dart';

import 'librarian_nav.dart';
import 'profile_admin_detail.dart';

class ProfileAdmin extends StatelessWidget {
  const ProfileAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          LibBeigeHeader(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Quay lại',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundColor: kLibBeigeSoft,
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: kLibBrownTitle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lê Văn Lê',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'le.vanle@phenikaa-uni.edu.vn',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                LibSectionCard(
                  title: 'Tài khoản',
                  child: LibMenuRow(
                    label: 'Thông tin cá nhân',
                    icon: Icons.badge_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileAdminDetail(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const LibSectionCard(
                  title: 'Cài đặt khác',
                  child: Column(
                    children: [
                      LibMenuRow(
                        label: 'Cài đặt',
                        icon: Icons.settings_outlined,
                      ),
                      Divider(height: 1),
                      LibMenuRow(
                        label: 'Thông tin khác',
                        icon: Icons.info_outline,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: SizedBox(
                    width: 151,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const Login()),
                        (route) => false,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF16F6F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Đăng xuất'),
                    ),
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
