import 'package:flutter/material.dart';
import 'package:libary_management/login/login.dart';
import 'package:libary_management/core/api_client.dart';

import 'librarian_nav.dart';
import 'profile_admin_detail.dart';
import 'user_management.dart';

class ProfileAdmin extends StatelessWidget {
  const ProfileAdmin({super.key});

  Future<void> _openSettings(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: kLibCardFill,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cài đặt ứng dụng',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kLibBrownTitle,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              _AdminSettingRow(
                icon: Icons.dns_rounded,
                label: 'Máy chủ đang kết nối',
                value: ApiClient.baseUrl,
              ),
              const Divider(height: 1),
              _AdminSettingRow(
                icon: Icons.admin_panel_settings_rounded,
                label: 'Vai trò tài khoản',
                value: _roleLabel(AppSession.user?['role']?.toString()),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 178,
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: kLibBrownTitle,
                    ),
                    onPressed: () async {
                      try {
                        await ApiClient.testServer(ApiClient.baseUrl);
                        if (!sheetContext.mounted) return;
                        ScaffoldMessenger.of(sheetContext)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('Kết nối máy chủ bình thường.'),
                            ),
                          );
                      } catch (error) {
                        if (!sheetContext.mounted) return;
                        ScaffoldMessenger.of(sheetContext)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                      }
                    },
                    icon: const Icon(Icons.wifi_tethering_rounded),
                    label: const Text('Kiểm tra kết nối'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Readily',
      applicationVersion: '1.0.0',
      applicationIcon: const CircleAvatar(
        backgroundColor: kLibBeigeSoft,
        child: Icon(Icons.local_library_rounded, color: kLibBrownTitle),
      ),
      children: const [
        Text(
          'Ứng dụng quản lý thư viện hỗ trợ thủ thư quản lý sách, độc giả, '
          'giao dịch mượn trả, thông báo và báo cáo thống kê.',
        ),
      ],
    );
  }

  String _roleLabel(String? role) => switch (role) {
    'admin' => 'Quản trị viên',
    'librarian' => 'Thủ thư',
    _ => apiText(role),
  };

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
                          const SizedBox(height: 4),
                          Text(
                            apiText(AppSession.user?['role'], fallback: ''),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
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
                  child: Column(
                    children: [
                      LibMenuRow(
                        label: 'Thông tin cá nhân',
                        icon: Icons.badge_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileAdminDetail(),
                          ),
                        ),
                      ),
                      if (AppSession.user?['role'] == 'admin') ...[
                        const Divider(height: 1),
                        LibMenuRow(
                          label: 'Quản lý tài khoản',
                          icon: Icons.manage_accounts_outlined,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserManagement(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LibSectionCard(
                  title: 'Cài đặt khác',
                  child: Column(
                    children: [
                      LibMenuRow(
                        label: 'Cài đặt',
                        icon: Icons.settings_rounded,
                        onTap: () => _openSettings(context),
                      ),
                      const Divider(height: 1),
                      LibMenuRow(
                        label: 'Thông tin khác',
                        icon: Icons.info_rounded,
                        onTap: () => _showAbout(context),
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
                      onPressed: () {
                        AppSession.clear();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const Login()),
                          (route) => false,
                        );
                      },
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

class _AdminSettingRow extends StatelessWidget {
  const _AdminSettingRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kLibBrownTitle, size: 27),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: kLibBrownTitle,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: kLibBookTitle)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
