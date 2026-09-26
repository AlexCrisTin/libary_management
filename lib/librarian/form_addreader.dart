import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/local_image.dart';

import 'librarian_nav.dart';
import 'librarian_scanner.dart';
import 'librarian_shell.dart';

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
  final _faculty = TextEditingController();
  final _cardExpired = TextEditingController();
  final _maxBooks = TextEditingController(text: '5');

  String _readerType = 'student';
  String _status = 'active';
  String _avatarData = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _cardExpired.text = _dateText(DateTime(now.year + 1, now.month, now.day));
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _birthDate,
      _phone,
      _email,
      _faculty,
      _cardExpired,
      _maxBooks,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectAvatar() async {
    try {
      final data = await pickLocalImageAsDataUri();
      if (data != null && mounted) setState(() => _avatarData = data);
    } catch (error) {
      if (mounted) _show(error.toString());
    }
  }

  Future<void> _pickDate({required bool birthDate}) async {
    final controller = birthDate ? _birthDate : _cardExpired;
    final now = DateTime.now();
    final parsed = DateTime.tryParse(controller.text);
    final date = await showDatePicker(
      context: context,
      initialDate: parsed ?? (birthDate ? DateTime(now.year - 18) : now),
      firstDate: birthDate ? DateTime(1900) : DateTime(now.year - 1),
      lastDate: birthDate ? now : DateTime(now.year + 20),
      helpText: birthDate ? 'Chọn ngày sinh' : 'Chọn ngày hết hạn thẻ',
    );
    if (date != null) setState(() => controller.text = _dateText(date));
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _show('Họ và tên không được để trống.');
      return;
    }
    if (name.length > 200) {
      _show('Họ và tên không được vượt quá 200 ký tự.');
      return;
    }
    if (_phone.text.trim().length > 20) {
      _show('Số điện thoại không được vượt quá 20 ký tự.');
      return;
    }
    final email = _email.text.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _show('Email không đúng định dạng.');
      return;
    }
    final maxBooks = int.tryParse(_maxBooks.text.trim());
    if (maxBooks == null || maxBooks < 1 || maxBooks > 32767) {
      _show('Số sách tối đa phải từ 1 đến 32767.');
      return;
    }
    if (_birthDate.text.isNotEmpty &&
        DateTime.tryParse(_birthDate.text) == null) {
      _show('Ngày sinh không hợp lệ.');
      return;
    }
    if (DateTime.tryParse(_cardExpired.text) == null) {
      _show('Ngày hết hạn thẻ không hợp lệ.');
      return;
    }

    setState(() => _loading = true);
    try {
      String? avatarUrl;
      if (_avatarData.isNotEmpty) {
        final bytes = decodeDataImage(_avatarData);
        if (bytes == null) {
          throw const FormatException('Không đọc được ảnh đại diện đã chọn.');
        }
        final uploaded = apiMap(
          await ApiClient.uploadImage('/uploads/reader-avatar', bytes: bytes),
        );
        avatarUrl = apiText(uploaded['url'], fallback: '');
      }

      await ApiClient.post(
        '/readers',
        body: {
          'full_name': name,
          'birth_date': _nullable(_birthDate),
          'phone': _nullable(_phone),
          'email': _nullable(_email),
          'reader_type': _readerType,
          'faculty': _nullable(_faculty),
          'card_expired': _cardExpired.text,
          'max_books': maxBooks,
          'status': _status,
          'avatar_url': avatarUrl,
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _show(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _nullable(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  String _dateText(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  void _openTab(int index) {
    if (index == 4) {
      Navigator.pop(context);
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LibrarianShell(initialIndex: index)),
      (_) => false,
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const LibTitleHeader(title: 'Thêm độc giả', showBack: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 34),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 34),
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
                        Container(
                          width: 124,
                          height: 1,
                          margin: const EdgeInsets.only(top: 8, bottom: 14),
                          color: kLibBrownTitle.withValues(alpha: .4),
                        ),
                        _AvatarPicker(
                          data: _avatarData,
                          onTap: _selectAvatar,
                          onRemove: _avatarData.isEmpty
                              ? null
                              : () => setState(() => _avatarData = ''),
                        ),
                        const SizedBox(height: 18),
                        _ReaderField(
                          label: 'Họ và tên',
                          controller: _name,
                          required: true,
                        ),
                        _ReaderField(
                          label: 'Ngày sinh',
                          controller: _birthDate,
                          hint: 'YYYY-MM-DD',
                          readOnly: true,
                          onTap: () => _pickDate(birthDate: true),
                          suffixIcon: Icons.calendar_month_outlined,
                        ),
                        _ReaderField(
                          label: 'Số điện thoại',
                          controller: _phone,
                          keyboard: TextInputType.phone,
                        ),
                        _ReaderField(
                          label: 'Email',
                          controller: _email,
                          keyboard: TextInputType.emailAddress,
                        ),
                        _DoubleField(
                          left: _ReaderDropdown(
                            label: 'Loại độc giả',
                            value: _readerType,
                            items: const {
                              'student': 'Sinh viên',
                              'lecturer': 'Giảng viên',
                              'staff': 'Nhân viên',
                              'public': 'Khác',
                            },
                            onChanged: (value) =>
                                setState(() => _readerType = value),
                          ),
                          right: _ReaderField(
                            label: 'Khoa',
                            controller: _faculty,
                            compact: true,
                          ),
                        ),
                        _ReaderField(
                          label: 'Ngày hết hạn thẻ',
                          controller: _cardExpired,
                          readOnly: true,
                          onTap: () => _pickDate(birthDate: false),
                          suffixIcon: Icons.calendar_month_outlined,
                        ),
                        _ReaderField(
                          label: 'Số sách tối đa mượn',
                          controller: _maxBooks,
                          keyboard: TextInputType.number,
                          short: true,
                        ),
                        _ReaderDropdown(
                          label: 'Trạng thái',
                          value: _status,
                          short: true,
                          items: const {
                            'active': 'Hoạt động',
                            'suspended': 'Tạm khóa',
                            'expired': 'Hết hạn',
                          },
                          onChanged: (value) => setState(() => _status = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: 136,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kLibGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Tạo',
                              style: TextStyle(
                                fontSize: 17,
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
        onSelect: _openTab,
        onScan: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LibrarianScanner()),
        ),
      ),
    );
  }
}

const _readerLabelStyle = TextStyle(
  color: kLibBrownTitle,
  fontSize: 15,
  fontWeight: FontWeight.w700,
);

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.data,
    required this.onTap,
    required this.onRemove,
  });

  final String data;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final bytes = decodeDataImage(data);
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: CircleAvatar(
            radius: 48,
            backgroundColor: kLibBeigeSoft,
            backgroundImage: bytes == null ? null : MemoryImage(bytes),
            child: bytes == null
                ? const Icon(
                    Icons.image_rounded,
                    color: Color(0xFF405170),
                    size: 36,
                  )
                : null,
          ),
        ),
        TextButton.icon(
          onPressed: onRemove ?? onTap,
          icon: Icon(
            onRemove == null ? Icons.folder_open_rounded : Icons.delete_outline,
            size: 18,
          ),
          label: Text(onRemove == null ? 'Chọn ảnh từ máy' : 'Xóa ảnh'),
        ),
      ],
    );
  }
}

class _ReaderField extends StatelessWidget {
  const _ReaderField({
    required this.label,
    required this.controller,
    this.required = false,
    this.hint,
    this.keyboard,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.short = false,
    this.compact = false,
  });

  final String label;
  final TextEditingController controller;
  final bool required;
  final String? hint;
  final TextInputType? keyboard;
  final bool readOnly;
  final VoidCallback? onTap;
  final IconData? suffixIcon;
  final bool short;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final field = SizedBox(
      height: 48,
      width: short ? 150 : null,
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(fontSize: 14, color: kLibBookTitle),
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: suffixIcon == null
              ? null
              : Icon(suffixIcon, size: 19, color: kLibBrownTitle),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
    if (compact) return field;
    return _LabeledRow(label: '$label${required ? ' *' : ''}', child: field);
  }
}

class _ReaderDropdown extends StatelessWidget {
  const _ReaderDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.short = false,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;
  final bool short;

  @override
  Widget build(BuildContext context) {
    return _LabeledRow(
      label: label,
      child: SizedBox(
        height: 48,
        width: short ? 150 : null,
        child: DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(fontSize: 13, color: kLibBookTitle),
          items: items.entries
              .map(
                (entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (newValue) {
            if (newValue != null) onChanged(newValue);
          },
        ),
      ),
    );
  }
}

class _LabeledRow extends StatelessWidget {
  const _LabeledRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 132, child: Text(label, style: _readerLabelStyle)),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DoubleField extends StatelessWidget {
  const _DoubleField({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              left,
              _LabeledRow(label: 'Khoa', child: right),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledRow(label: 'Khoa', child: right),
            ),
          ],
        );
      },
    );
  }
}
