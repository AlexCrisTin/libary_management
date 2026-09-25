import 'package:flutter/material.dart';

import 'librarian_nav.dart';
import 'message_detail.dart';
import 'report.dart';

class BorrowReturnDetail extends StatelessWidget {
  const BorrowReturnDetail({super.key});

  void _extendLoan(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gia hạn sách mẫu'),
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
              padding: const EdgeInsets.fromLTRB(12, 22, 12, 18),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Image.asset(
                      'assets/img/F4bfd9e1649e82dcfdbe.jpg',
                      width: 147,
                      height: 221,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 17,
                          ),
                          decoration: const BoxDecoration(
                            color: kLibBeigeButton,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Thông tin sách và người mượn',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF444A58),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 24, 14, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _InformationRow(
                                label: 'Sách:',
                                value: 'Toán cao cấp',
                              ),
                              const _InformationRow(label: 'Mã', value: 'M1'),
                              const _InformationRow(
                                label: 'Người mượn',
                                value: 'Trần Ngọc An',
                              ),
                              const _InformationRow(
                                label: 'Ngày mượn',
                                value: '01/01/2727',
                              ),
                              const _InformationRow(
                                label: 'Ngày trả',
                                value: '27/07/2727',
                              ),
                              const _InformationRow(
                                label: 'Ghi chú',
                                value: 'Không có',
                              ),
                              const _InformationRow(
                                label: 'Tình trạng',
                                value: 'Đang mượn',
                              ),
                              const SizedBox(height: 70),
                              Row(
                                children: [
                                  Expanded(
                                    child: _ActionButton(
                                      label: 'Gia hạn',
                                      icon: Icons.library_books_rounded,
                                      color: kLibGreen,
                                      onPressed: () => _extendLoan(context),
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
                      heroTag: 'borrowReturnMessage',
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

class _InformationRow extends StatelessWidget {
  const _InformationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFC16767),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: kLibBookTitle,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
