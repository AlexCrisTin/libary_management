import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/login/login.dart';
import 'package:libary_management/reader/fine.dart';
import 'package:libary_management/reader/history.dart';
import 'package:libary_management/reader/profile_detail.dart';
import 'package:libary_management/reader/reader_nav.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      BeigeHeader(
        child: Row(
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: kBeigeSoft,
              child: Icon(Icons.person, size: 48, color: kBrownTitle),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppSession.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    apiText(AppSession.user?['email'], fallback: ''),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SectionCard(
              title: 'Tài khoản',
              child: Column(
                children: [
                  MenuRow(
                    label: 'Thông tin cá nhân',
                    icon: Icons.badge_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileDetail()),
                    ),
                  ),
                  MenuRow(
                    label: 'Lịch sử mượn/trả sách',
                    icon: Icons.history,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const History()),
                    ),
                  ),
                  MenuRow(
                    label: 'Tiền phạt',
                    icon: Icons.payments_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Fine()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                AppSession.clear();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const Login()),
                  (_) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF16F6F),
                foregroundColor: Colors.white,
              ),
              child: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    ],
  );
}
