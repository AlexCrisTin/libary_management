import 'package:flutter/material.dart';

class FormAddBook extends StatelessWidget {
  const FormAddBook({super.key});

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
                    'Thêm sách',
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
                    // Book cover upload area
                    Center(
                      child: Container(
                        width: 141,
                        height: 77,
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                        ),
                        child: Center(
                          child: Container(
                              width: 41,
                              height: 41,
                              child: const Stack()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Thông tin sách',
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
                    _formRow('Tên sách', wide: true),
                    const SizedBox(height: 8),
                    _formRow('Phụ đề', wide: true),
                    const SizedBox(height: 8),
                    _formRow('ISBN', wide: true),
                    const SizedBox(height: 8),
                    // Tác giả + dropdown
                    Row(
                      children: [
                        const SizedBox(
                          width: 80,
                          child: Text(
                            'Tác giả',
                            style: TextStyle(
                              color: Color(0xFF8A6060),
                              fontSize: 13,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 25,
                          height: 22,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE2C5B5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Stack(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Nhà xuất bản + Năm xuất bản
                    Row(
                      children: [
                        const Text(
                          'Nhà xuất bản',
                          style: TextStyle(
                            color: Color(0xFF8A6060),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _fieldBox(width: 67),
                        const Spacer(),
                        const Text(
                          'Năm xuất bản',
                          style: TextStyle(
                            color: Color(0xFF8A6060),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _fieldBox(width: 55),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Thể loại + dropdown
                    Row(
                      children: [
                        const Text(
                          'Thể loại',
                          style: TextStyle(
                            color: Color(0xFF8A6060),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _fieldBox(width: 74),
                        const SizedBox(width: 8),
                        Container(
                          width: 25,
                          height: 22,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE2C5B5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Stack(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Ngôn ngữ + Số trang
                    Row(
                      children: [
                        const Text(
                          'Ngôn ngữ',
                          style: TextStyle(
                            color: Color(0xFF8A6060),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _fieldBox(width: 74),
                        const Spacer(),
                        const Text(
                          'Số trang',
                          style: TextStyle(
                            color: Color(0xFF8A6060),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _fieldBox(width: 38),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Vị trí kệ + Bản sao
                    Row(
                      children: [
                        const Text(
                          'Vị trí kệ',
                          style: TextStyle(
                            color: Color(0xFF8A6060),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _fieldBox(width: 74),
                        const Spacer(),
                        const Text(
                          'Bản sao',
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

  Widget _formRow(String label, {bool wide = false}) {
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
                  borderRadius: BorderRadius.circular(5)),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }
}