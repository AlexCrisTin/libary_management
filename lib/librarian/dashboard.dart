import 'package:flutter/material.dart';
import 'librarian_nav.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({
    super.key,
    this.onOpenTab,
    this.onOpenReaderManagement,
    this.onOpenReport,
    this.onOpenMessages,
    this.onOpenProfile,
    this.onOpenNotice,
  });

  final ValueChanged<int>? onOpenTab;
  final VoidCallback? onOpenReaderManagement;
  final VoidCallback? onOpenReport;
  final VoidCallback? onOpenMessages;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenNotice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar header
            LibBeigeHeader(
              child: Row(
                children: [
                  InkWell(
                    onTap: onOpenProfile,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: kLibBeigeSoft,
                            child: Icon(
                              Icons.person,
                              size: 20,
                              color: kLibBrownTitle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Lê Văn Lê',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                    ),
                    onPressed: onOpenNotice,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Chào mừng',
                  style: TextStyle(
                    color: kLibBrownTitle,
                    fontSize: 20,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Quick-access cards
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _QuickCard(
                      icon: Icons.menu_book_rounded,
                      label: 'Quản lý sách',
                      onTap: () => onOpenTab?.call(1),
                    ),
                    _QuickCard(
                      icon: Icons.people_rounded,
                      label: 'Quản lý độc giả',
                      onTap: onOpenReaderManagement,
                    ),
                    _QuickCard(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Mượn / Trả',
                      onTap: () => onOpenTab?.call(3),
                    ),
                    _QuickCard(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Tin nhắn',
                      onTap: onOpenMessages,
                    ),
                    _QuickCard(
                      icon: Icons.bar_chart_rounded,
                      label: 'Báo cáo',
                      onTap: onOpenReport,
                    ),
                    _QuickCard(
                      icon: Icons.person_rounded,
                      label: 'Hồ sơ',
                      onTap: onOpenProfile,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F0EA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: kLibBrownTitle),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kLibBrownTitle,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
