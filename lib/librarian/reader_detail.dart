import 'package:flutter/material.dart';

class ReaderDetail extends StatelessWidget {
  const ReaderDetail({super.key});

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
                  // Back button
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
                  // Edit button
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Avatar
                    Center(
                      child: Container(
                        width: 151,
                        height: 151,
                        decoration: const ShapeDecoration(
                          color: Color(0xFFEFE2D9),
                          shape: OvalBorder(),
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
                          'Thông tin độc giả',
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
                    const SizedBox(height: 16),
                    // Reader info rows
                    _infoRow('Họ và tên: Trần Ngọc An'),
                    const SizedBox(height: 16),
                    _infoRow('Mã độc giả: M1'),
                    const SizedBox(height: 16),
                    _infoRow('Ngày sinh: 27/7/2727'),
                    const SizedBox(height: 16),
                    _infoRow('Số điện thoại: 02727272727'),
                    const SizedBox(height: 16),
                    _infoRow('Địa chỉ: 27 trần văn phú'),
                    const SizedBox(height: 16),
                    _infoRow('Email:2727@gmail.com'),
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
                            child: const Center(
                              child: Text(
                                'Mượn sách',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8A6060),
          fontSize: 15,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
