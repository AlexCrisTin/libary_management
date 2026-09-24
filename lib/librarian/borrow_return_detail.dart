import 'package:flutter/material.dart';

class BorrowReturnDetail extends StatelessWidget {
  const BorrowReturnDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar header
            Container(
              width: double.infinity,
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const ShapeDecoration(
                color: Color(0xFFDBB9A0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Spacer(),
                  const Text(
                    'Chi tiết',
                    style: TextStyle(
                      color: Color(0xFF8A6060),
                      fontSize: 25,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 37),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Book cover
                    Center(
                      child: Container(
                        width: 147,
                        height: 221,
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: NetworkImage("https://placehold.co/147x221"),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Section header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFE2C5B5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Thông tin sách và người mượn',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF444A58),
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Info rows
                    _infoRow('Sách:'),
                    const SizedBox(height: 12),
                    _infoRow('Mã'),
                    const SizedBox(height: 12),
                    _infoRow('Người mượn'),
                    const SizedBox(height: 12),
                    _infoRow('Ngày mượn'),
                    const SizedBox(height: 12),
                    _infoRow('Ngày trả'),
                    const SizedBox(height: 12),
                    _infoRow('Ghi chú'),
                    const SizedBox(height: 12),
                    _infoRow('Tình trạng'),
                    const SizedBox(height: 24),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 67,
                            decoration: ShapeDecoration(
                              color: const Color(0xFF82D1A8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 41,
                                  height: 41,
                                  child: const Stack(),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Gia hạn',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 67,
                            decoration: ShapeDecoration(
                              color: const Color(0xFFD18282),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  child: const Stack(),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Báo cáo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom back/home button
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Center(
                child: Container(
                  width: 67,
                  height: 67,
                  decoration: const ShapeDecoration(
                    color: Color(0xFFEFE2D9),
                    shape: OvalBorder(),
                  ),
                  child: const Stack(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFC16767),
        fontSize: 13,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
