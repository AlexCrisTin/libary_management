import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';

import 'librarian_nav.dart';

class FormAddReader extends StatefulWidget {
  const FormAddReader({super.key});
  @override
  State<FormAddReader> createState() => _FormAddReaderState();
}

class _FormAddReaderState extends State<FormAddReader> {
  final _name = TextEditingController();
  final _birthDate = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _type = TextEditingController(text: 'student');
  final _faculty = TextEditingController();
  final _maxBooks = TextEditingController(text: '5');
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _birthDate,
      _phone,
      _email,
      _type,
      _faculty,
      _maxBooks,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      _show('Họ và tên không được để trống.');
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiClient.post(
        '/readers',
        body: {
          'full_name': _name.text.trim(),
          'birth_date': _nullable(_birthDate),
          'phone': _nullable(_phone),
          'email': _nullable(_email),
          'reader_type': _type.text.trim().isEmpty
              ? 'student'
              : _type.text.trim(),
          'faculty': _nullable(_faculty),
          'max_books': int.tryParse(_maxBooks.text) ?? 5,
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      _show(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _nullable(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();
  void _show(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        const LibTitleHeader(title: 'Thêm độc giả', showBack: true),
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
                    'Thông tin độc giả',
                    style: TextStyle(
                      color: kLibBookTitle,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _field(_name, 'Họ và tên *'),
                  _field(_birthDate, 'Ngày sinh', hint: 'YYYY-MM-DD'),
                  _field(
                    _phone,
                    'Số điện thoại',
                    keyboard: TextInputType.phone,
                  ),
                  _field(_email, 'Email', keyboard: TextInputType.emailAddress),
                  _field(_type, 'Loại độc giả'),
                  _field(_faculty, 'Khoa'),
                  _field(
                    _maxBooks,
                    'Số sách tối đa mượn',
                    keyboard: TextInputType.number,
                  ),
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
    String? hint,
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      keyboardType: keyboard,
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
