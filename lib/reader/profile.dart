import 'package:flutter/material.dart';
import 'package:libary_management/reader/fine.dart';
import 'package:libary_management/reader/history.dart';
import 'package:libary_management/reader/notice.dart';
import 'package:libary_management/reader/profile-detail.dart';
import 'package:libary_management/reader/reader_nav.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trần Ngọc An',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '23010283@st.phenikaa-uni.edu.vn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            children: [
              SectionCard(
                title: 'Tài khoản',
                child: Column(
                  children: [
                    MenuRow(
                      label: 'Thông tin cá nhân',
                      icon: Icons.badge_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileDetail(),
                          ),
                        );
                      },
                    ),
                    MenuRow(
                      label: 'Lịch sử mượn/trả sách',
                      icon: Icons.history,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const History()),
                        );
                      },
                    ),
                    MenuRow(
                      label: 'Tiền phạt',
                      icon: Icons.payments_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Fine()),
                        );
                      },
                    ),
                    MenuRow(
                      label: 'Thông báo',
                      icon: Icons.notifications_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Notice()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SectionCard(
                title: 'Cài đặt khác',
                child: Column(
                  children: [
                    MenuRow(
                      label: 'Cài đặt',
                      icon: Icons.settings_outlined,
                      onTap: () {},
                    ),
                    MenuRow(
                      label: 'Thông tin khác',
                      icon: Icons.info_outline,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 151,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF16F6F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Đăng xuất',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
