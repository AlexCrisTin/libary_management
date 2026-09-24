import 'package:flutter/material.dart';

class FormAddReader extends StatelessWidget {
  const FormAddReader({super.key});

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
                  Container(width: 37, height: 37, child: const Stack()),
                  const Spacer(),
                  const Text(
                    'Thêm độc giả',
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
                    // Avatar upload
                    Center(
                      child: Container(
                        width: 94,
                        height: 94,
                        decoration: const ShapeDecoration(
                          color: Color(0xFFEFE2D9),
                          shape: OvalBorder(),
                        ),
                        child: Center(
                          child: Container(
                            width: 41,
                            height: 41,
                            child: const Stack(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Thông tin độc giả',
                        style: TextStyle(
                          color: Color(0xFF6F3636),
                          fontSize: 13,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Form fields
                    _formRow('Họ và tên'),
                    const SizedBox(height: 8),
                    _formRow('Ngày sinh'),
                    const SizedBox(height: 8),
                    _formRow('Số điện thoại', narrow: true),
                    const SizedBox(height: 8),
                    // Loại độc giả + Khoa
                    Row(
                      children: [
                        const Text(
                          'Loại độc giả',
                          style: TextStyle(
                            color: Color(0xFF8A6060),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Khoa',
                          style: TextStyle(
                            color: Color(0xFF8A6060),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _fieldBox(width: 67),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Ngày hết hạn thẻ
                    Row(
                      children: [
                        const Text(
                          'Ngày hết hạn thẻ',
                          style: TextStyle(
                            color: Color(0xFF8A6060),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _fieldBox(width: 79),
                        const Spacer(),
                        _fieldBox(width: 74),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Số sách tối đa mượn
                    Row(
                      children: [
                        const Text(
                          'Số sách tối đa mượn',
                          style: TextStyle(
                            color: Color(0xFF8A6060),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _fieldBox(width: 74),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Trạng thái
                    Row(
                      children: [
                        const Text(
                          'Trạng thái',
                          style: TextStyle(
                            color: Color(0xFF8A6060),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _fieldBox(width: 74),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Create button
                    Center(
                      child: Container(
                        width: 113,
                        height: 51,
                        decoration: ShapeDecoration(
                          color: const Color(0xFF82D1A8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Tạo',
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom nav
            Container(
              margin: const EdgeInsets.fromLTRB(26, 0, 26, 8),
              height: 61,
              decoration: ShapeDecoration(
                color: const Color(0xFFEFE2D9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(width: 45, height: 45, child: const Stack()),
                  Container(width: 45, height: 45, child: const Stack()),
                  Container(width: 45, height: 45, child: const Stack()),
                  Container(width: 45, height: 45, child: const Stack()),
                  Container(width: 45, height: 45, child: const Stack()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formRow(String label, {bool narrow = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8A6060),
            fontSize: 13,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 29,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldBox({required double width}) {
    return Container(
      width: width,
      height: 29,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }
}
