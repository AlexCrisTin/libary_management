import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';

import 'librarian_nav.dart';

class FormAddBook extends StatefulWidget {
  const FormAddBook({super.key});
  @override
  State<FormAddBook> createState() => _FormAddBookState();
}

class _FormAddBookState extends State<FormAddBook> {
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _isbn = TextEditingController();
  final _authors = TextEditingController();
  final _publisher = TextEditingController();
  final _year = TextEditingController();
  final _subjects = TextEditingController();
  final _language = TextEditingController(text: 'vi');
  final _pages = TextEditingController();
  final _callNumber = TextEditingController();
  final _copies = TextEditingController(text: '1');
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [
      _title,
      _subtitle,
      _isbn,
      _authors,
      _publisher,
      _year,
      _subjects,
      _language,
      _pages,
      _callNumber,
      _copies,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) {
      _show('Tên sách không được để trống.');
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiClient.post(
        '/books',
        body: {
          'title': _title.text.trim(),
          'subtitle': _nullable(_subtitle),
          'isbn': _nullable(_isbn),
          'authors': _split(_authors.text),
          'publisher_id': _nullable(_publisher),
          'publish_year': int.tryParse(_year.text),
          'subject_headings': _split(_subjects.text),
          'language': _language.text.trim().isEmpty
              ? 'vi'
              : _language.text.trim(),
          'page_count': int.tryParse(_pages.text),
          'call_number': _nullable(_callNumber),
          'initial_copies': int.tryParse(_copies.text) ?? 0,
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      _show(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _nullable(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();
  List<String> _split(String text) =>
      text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  void _show(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        const LibTitleHeader(title: 'Thêm sách', showBack: true),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Container(
              padding: const EdgeInsets.all(18),
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
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _field(_title, 'Tên sách *'),
                  _field(_subtitle, 'Phụ đề'),
                  _field(_isbn, 'ISBN'),
                  _field(_authors, 'Tác giả', hint: 'Ngăn cách bằng dấu phẩy'),
                  _field(_publisher, 'Mã nhà xuất bản'),
                  _field(_year, 'Năm xuất bản', number: true),
                  _field(
                    _subjects,
                    'Thể loại',
                    hint: 'Ngăn cách bằng dấu phẩy',
                  ),
                  _field(_language, 'Ngôn ngữ'),
                  _field(_pages, 'Số trang', number: true),
                  _field(_callNumber, 'Mã xếp giá'),
                  _field(_copies, 'Số bản sao', number: true),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 140,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kLibGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Tạo',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _field(
    TextEditingController c,
    String label, {
    bool number = false,
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      keyboardType: number ? TextInputType.number : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}
