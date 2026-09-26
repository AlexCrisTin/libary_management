import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';

import 'librarian_nav.dart';

class ProfileAdminDetail extends StatelessWidget {
  const ProfileAdminDetail({super.key});
  @override
  Widget build(BuildContext context) {
    final user = AppSession.user ?? const <String, dynamic>{};
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const LibTitleHeader(title: 'Thông tin cá nhân', showBack: true),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const CircleAvatar(
                  radius: 68,
                  backgroundColor: kLibBeigeSoft,
                  child: Icon(Icons.person, size: 68, color: kLibBrownTitle),
                ),
                const SizedBox(height: 24),
                LibSectionCard(
                  title: 'Thông tin',
                  child: Column(
                    children: [
                      LibMenuRow(
                        label: 'Tên đăng nhập: ${apiText(user['username'])}',
                        icon: Icons.person_outline,
                      ),
                      const Divider(height: 1),
                      LibMenuRow(
                        label: 'Vai trò: ${apiText(user['role'])}',
                        icon: Icons.admin_panel_settings_outlined,
                      ),
                      const Divider(height: 1),
                      LibMenuRow(
                        label: 'Mã tài khoản: ${apiText(user['user_id'])}',
                        icon: Icons.tag,
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
