import 'package:flutter/material.dart';

import 'book_management.dart';
import 'librarian_nav.dart';
import 'message_detail.dart';
import 'report.dart';

class ReaderDetail extends StatelessWidget {
  const ReaderDetail({super.key});

  void _showEditMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chế độ chỉnh sửa sẽ được kết nối với backend sau'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          LibBeigeHeader(
            child: SizedBox(
              height: 72,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Quay lại',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Chi tiết',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kLibBrownTitle,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 26, 12, 18),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 76,
                    backgroundColor: kLibBeigeSoft,
                    child: Icon(
                      Icons.person_rounded,
                      size: 82,
                      color: kLibBrownTitle,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: kLibCardFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                          decoration: const BoxDecoration(
                            color: kLibBeigeButton,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 42),
                              const Expanded(
                                child: Text(
                                  'Thông tin độc giả',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF444A58),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Chỉnh sửa',
                                onPressed: () => _showEditMessage(context),
                                icon: const Icon(
                                  Icons.edit_square,
                                  color: kLibBrownTitle,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(38, 20, 38, 20),
                          child: Column(
                            children: [
                              const _ReaderInfoRow(
                                text: 'Họ và tên: Trần Ngọc An',
                              ),
                              const _ReaderInfoRow(text: 'Mã độc giả: M1'),
                              const _ReaderInfoRow(
                                text: 'Ngày sinh: 27/7/2727',
                              ),
                              const _ReaderInfoRow(
                                text: 'Số điện thoại: 02727272727',
                              ),
                              const _ReaderInfoRow(
                                text: 'Địa chỉ: 27 trần văn phú',
                              ),
                              const _ReaderInfoRow(
                                text: 'Email: 2727@gmail.com',
                                showDivider: false,
                              ),
                              const SizedBox(height: 58),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ActionButton(
                                      label: 'Mượn sách',
                                      icon: Icons.menu_book_rounded,
                                      color: kLibGreen,
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const BookManagement(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 70),
                                  Expanded(
                                    child: _ActionButton(
                                      label: 'Báo cáo',
                                      icon: Icons.warning_amber_rounded,
                                      color: kLibRed,
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const Report(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 68,
                    height: 68,
                    child: FloatingActionButton(
                      heroTag: 'readerDetailMessage',
                      elevation: 0,
                      backgroundColor: kLibBeigeSoft,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MessageDetail(),
                        ),
                      ),
                      child: const Icon(
                        Icons.more_horiz_rounded,
                        color: kLibBrownTitle,
                        size: 34,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReaderInfoRow extends StatelessWidget {
  const _ReaderInfoRow({required this.text, this.showDivider = true});

  final String text;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            text,
            style: const TextStyle(
              color: kLibBrownTitle,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: kLibBrownTitle.withValues(alpha: 0.35),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 29),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
