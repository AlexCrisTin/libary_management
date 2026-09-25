import 'package:flutter/material.dart';

import 'librarian_nav.dart';
import 'librarian_scanner.dart';
import 'librarian_shell.dart';

class FormAddBook extends StatelessWidget {
  const FormAddBook({super.key});

  static const _labelStyle = TextStyle(
    color: kLibBrownTitle,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  void _openTab(BuildContext context, int index) {
    if (index == 1) {
      Navigator.pop(context);
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LibrarianShell(initialIndex: index)),
      (route) => false,
    );
  }

  void _createBook(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu thông tin sách mẫu'),
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
                      'Thêm sách',
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
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
                    decoration: BoxDecoration(
                      color: kLibCardFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Thông tin sách',
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
                        const SizedBox(height: 26),
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Chọn ảnh bìa sách'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 142,
                            height: 94,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.image_rounded,
                              color: Color(0xFF405170),
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        const _FullField(label: 'Tên sách'),
                        const SizedBox(height: 8),
                        const _FullField(label: 'Phụ đề'),
                        const SizedBox(height: 8),
                        const _FullField(label: 'ISBN'),
                        const SizedBox(height: 10),
                        const _AuthorField(),
                        const SizedBox(height: 10),
                        const _TwoFields(
                          leftLabel: 'Nhà xuất bản',
                          rightLabel: 'Năm xuất bản',
                          leftFlex: 6,
                          rightFlex: 5,
                          rightKeyboard: TextInputType.number,
                        ),
                        const SizedBox(height: 10),
                        const _CategoryField(),
                        const SizedBox(height: 10),
                        const _TwoFields(
                          leftLabel: 'Ngôn ngữ',
                          rightLabel: 'Số trang',
                          leftFlex: 5,
                          rightFlex: 4,
                          rightKeyboard: TextInputType.number,
                        ),
                        const SizedBox(height: 10),
                        const _TwoFields(
                          leftLabel: 'Vị trí kệ',
                          rightLabel: 'Bản sao',
                          leftFlex: 5,
                          rightFlex: 5,
                          rightKeyboard: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: 114,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _createBook(context),
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
        currentIndex: 1,
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
  const _FullField({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 72, child: Text(label, style: FormAddBook._labelStyle)),
        const SizedBox(width: 8),
        const Expanded(child: _InputBox()),
      ],
    );
  }
}

class _AuthorField extends StatelessWidget {
  const _AuthorField();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 72,
          child: Text('Tác giả', style: FormAddBook._labelStyle),
        ),
        const SizedBox(width: 8),
        const SizedBox(width: 75, child: _InputBox()),
        const SizedBox(width: 6),
        _AddButton(onPressed: () {}),
      ],
    );
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 72,
          child: Text('Thể loại', style: FormAddBook._labelStyle),
        ),
        const SizedBox(width: 8),
        const SizedBox(width: 75, child: _InputBox()),
        const SizedBox(width: 6),
        _AddButton(onPressed: () {}),
      ],
    );
  }
}

class _TwoFields extends StatelessWidget {
  const _TwoFields({
    required this.leftLabel,
    required this.rightLabel,
    this.leftFlex = 1,
    this.rightFlex = 1,
    this.rightKeyboard,
  });

  final String leftLabel;
  final String rightLabel;
  final int leftFlex;
  final int rightFlex;
  final TextInputType? rightKeyboard;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: leftFlex,
          child: Row(
            children: [
              Flexible(
                child: Text(
                  leftLabel,
                  maxLines: 1,
                  style: FormAddBook._labelStyle,
                ),
              ),
              const SizedBox(width: 8),
              const SizedBox(width: 67, child: _InputBox()),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: rightFlex,
          child: Row(
            children: [
              Flexible(
                child: Text(
                  rightLabel,
                  maxLines: 1,
                  style: FormAddBook._labelStyle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _InputBox(keyboardType: rightKeyboard)),
            ],
          ),
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

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(backgroundColor: kLibBeigeButton),
        icon: const Icon(Icons.add, color: Colors.white, size: 25),
      ),
    );
  }
}
