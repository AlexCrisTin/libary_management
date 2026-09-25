import 'package:flutter/material.dart';

import 'librarian_nav.dart';
import 'librarian_scanner.dart';
import 'librarian_shell.dart';

class FormAddReader extends StatelessWidget {
  const FormAddReader({super.key});

  static const _labelStyle = TextStyle(
    color: kLibBrownTitle,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  void _openTab(BuildContext context, int index) {
    if (index == 4) {
      Navigator.pop(context);
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LibrarianShell(initialIndex: index)),
      (route) => false,
    );
  }

  void _createReader(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu thông tin độc giả mẫu'),
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
                      'Thêm độc giả',
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
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 570),
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
                    decoration: BoxDecoration(
                      color: kLibCardFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Thông tin độc giả',
                          style: TextStyle(
                            color: kLibBookTitle,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          width: 124,
                          height: 1,
                          margin: const EdgeInsets.only(top: 8),
                          color: kLibBrownTitle.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 14),
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Chọn ảnh độc giả'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(60),
                          child: const CircleAvatar(
                            radius: 48,
                            backgroundColor: kLibBeigeSoft,
                            child: Icon(
                              Icons.image_rounded,
                              color: Color(0xFF405170),
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const _FullField(label: 'Họ và tên'),
                        const SizedBox(height: 8),
                        const _FullField(label: 'Ngày sinh'),
                        const SizedBox(height: 8),
                        const _FullField(
                          label: 'Số điện thoại',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 10),
                        const _ReaderTypeAndFaculty(),
                        const SizedBox(height: 10),
                        const _ShortField(
                          label: 'Ngày hết hạn thẻ',
                          fieldWidth: 80,
                        ),
                        const SizedBox(height: 10),
                        const _ShortField(
                          label: 'Số sách tối đa mượn',
                          fieldWidth: 76,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 10),
                        const _ShortField(label: 'Trạng thái', fieldWidth: 76),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: 114,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _createReader(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kLibGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Tạo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: LibrarianBottomBar(
        currentIndex: 4,
        onSelect: (index) => _openTab(context, index),
        onScan: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LibrarianScanner()),
        ),
      ),
    );
  }
}

class _FullField extends StatelessWidget {
  const _FullField({required this.label, this.keyboardType});

  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(label, style: FormAddReader._labelStyle),
        ),
        const SizedBox(width: 8),
        Expanded(child: _InputBox(keyboardType: keyboardType)),
      ],
    );
  }
}

class _ReaderTypeAndFaculty extends StatelessWidget {
  const _ReaderTypeAndFaculty();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Loại độc giả', style: FormAddReader._labelStyle),
        const SizedBox(width: 8),
        const SizedBox(width: 64, child: _InputBox()),
        const Spacer(),
        const Text('Khoa', style: FormAddReader._labelStyle),
        const SizedBox(width: 8),
        const SizedBox(width: 68, child: _InputBox()),
      ],
    );
  }
}

class _ShortField extends StatelessWidget {
  const _ShortField({
    required this.label,
    required this.fieldWidth,
    this.keyboardType,
  });

  final String label;
  final double fieldWidth;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: FormAddReader._labelStyle),
        const SizedBox(width: 8),
        SizedBox(
          width: fieldWidth,
          child: _InputBox(keyboardType: keyboardType),
        ),
      ],
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({this.keyboardType});

  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextField(
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
