import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/core/local_image.dart';

import 'borrow_return_book_management.dart';
import 'librarian_nav.dart';
import 'message_detail.dart';
import 'report.dart';

class ReaderDetail extends StatefulWidget {
  const ReaderDetail({super.key, required this.readerId});

  final String readerId;

  @override
  State<ReaderDetail> createState() => _ReaderDetailState();
}

class _ReaderDetailState extends State<ReaderDetail> {
  Map<String, dynamic> _reader = const {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = apiMap(await ApiClient.get('/readers/${widget.readerId}'));
      if (mounted) setState(() => _reader = data);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editReader() async {
    final name = TextEditingController(
      text: apiText(_reader['full_name'], fallback: ''),
    );
    final phone = TextEditingController(
      text: apiText(_reader['phone'], fallback: ''),
    );
    final email = TextEditingController(
      text: apiText(_reader['email'], fallback: ''),
    );
    final faculty = TextEditingController(
      text: apiText(_reader['faculty'], fallback: ''),
    );
    final maxBooks = TextEditingController(
      text: apiText(_reader['max_books'], fallback: '5'),
    );
    var readerType = _reader['reader_type']?.toString() ?? 'student';
    var status = _reader['status']?.toString() ?? 'active';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: kLibCardFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Chỉnh sửa độc giả',
            style: TextStyle(
              color: kLibBrownTitle,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _EditField(controller: name, label: 'Họ và tên'),
                  _EditField(controller: phone, label: 'Số điện thoại'),
                  _EditField(controller: email, label: 'Email'),
                  _EditField(controller: faculty, label: 'Khoa'),
                  _EditField(
                    controller: maxBooks,
                    label: 'Số sách tối đa',
                    keyboard: TextInputType.number,
                  ),
                  _EditDropdown(
                    label: 'Loại độc giả',
                    value: readerType,
                    values: const {
                      'student': 'Sinh viên',
                      'lecturer': 'Giảng viên',
                      'staff': 'Nhân viên',
                      'public': 'Khác',
                    },
                    onChanged: (value) =>
                        setDialogState(() => readerType = value),
                  ),
                  _EditDropdown(
                    label: 'Trạng thái',
                    value: status,
                    values: const {
                      'active': 'Hoạt động',
                      'suspended': 'Tạm khóa',
                      'expired': 'Hết hạn',
                    },
                    onChanged: (value) => setDialogState(() => status = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kLibGreen),
              onPressed: () async {
                final limit = int.tryParse(maxBooks.text.trim());
                if (name.text.trim().isEmpty || limit == null || limit < 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tên và số sách tối đa không hợp lệ.'),
                    ),
                  );
                  return;
                }
                try {
                  await ApiClient.put(
                    '/readers/${widget.readerId}',
                    body: {
                      'full_name': name.text.trim(),
                      'phone': _emptyToNull(phone.text),
                      'email': _emptyToNull(email.text),
                      'faculty': _emptyToNull(faculty.text),
                      'reader_type': readerType,
                      'max_books': limit,
                    },
                  );
                  if (status != _reader['status']?.toString()) {
                    await ApiClient.put(
                      '/readers/${widget.readerId}/card',
                      body: {'status': status},
                    );
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error.toString())));
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    name.dispose();
    phone.dispose();
    email.dispose();
    faculty.dispose();
    maxBooks.dispose();
    if (saved == true) await _load();
  }

  String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const LibTitleHeader(title: 'Chi tiết', showBack: true),
          Expanded(
            child: ApiStateView(
              loading: _loading,
              error: _error,
              isEmpty: _reader.isEmpty,
              onRetry: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 28),
                children: [
                  _ReaderAvatar(url: _reader['avatar_url']?.toString()),
                  const SizedBox(height: 26),
                  _InformationCard(
                    reader: _reader,
                    onEdit: _editReader,
                    onBorrow: () => _open(const BorrowReturnBookManagement()),
                    onReport: () => _open(const Report()),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Material(
                      color: kLibBeigeSoft,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Nhắn tin',
                        onPressed: () => _open(
                          MessageDetail(
                            readerId: widget.readerId,
                            readerName: apiText(
                              _reader['full_name'],
                              fallback: 'Độc giả',
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        icon: const Icon(
                          Icons.chat_bubble_rounded,
                          color: kLibBrownTitle,
                          size: 30,
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
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.reader,
    required this.onEdit,
    required this.onBorrow,
    required this.onReport,
  });

  final Map<String, dynamic> reader;
  final VoidCallback onEdit;
  final VoidCallback onBorrow;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget?>[
      _InfoRow(label: 'Họ và tên', value: reader['full_name']),
      _InfoRow(label: 'Mã độc giả', value: reader['reader_code']),
      _InfoRow(label: 'Ngày sinh', value: apiDate(reader['birth_date'])),
      _InfoRow(label: 'Số điện thoại', value: reader['phone']),
      _InfoRow(label: 'Email', value: reader['email']),
      _InfoRow(label: 'Khoa', value: reader['faculty']),
      _InfoRow(
        label: 'Loại độc giả',
        value: _readerTypeText(reader['reader_type']),
      ),
      _InfoRow(label: 'Hạn thẻ', value: apiDate(reader['card_expired'])),
      _InfoRow(label: 'Trạng thái', value: _statusText(reader['status'])),
      _InfoRow(label: 'Số sách tối đa', value: reader['max_books']),
      _InfoRow(
        label: 'Đang mượn',
        value: reader['currently_borrowed_count'],
        last: true,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: kLibCardFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.only(left: 54, right: 10),
            decoration: const BoxDecoration(
              color: kLibBeigeButton,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Thông tin độc giả',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF454B5A),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Chỉnh sửa',
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_square,
                    color: kLibBrownTitle,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(38, 18, 38, 22),
            child: Column(
              children: [
                ...rows.whereType<Widget>(),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Mượn sách',
                        icon: Icons.menu_book_rounded,
                        color: kLibGreen,
                        onTap: onBorrow,
                      ),
                    ),
                    const SizedBox(width: 34),
                    Expanded(
                      child: _ActionButton(
                        label: 'Báo cáo',
                        icon: Icons.warning_rounded,
                        color: kLibRed,
                        onTap: onReport,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _readerTypeText(dynamic value) {
    switch (value?.toString()) {
      case 'student':
        return 'Sinh viên';
      case 'lecturer':
        return 'Giảng viên';
      case 'staff':
        return 'Nhân viên';
      case 'public':
        return 'Khác';
      default:
        return apiText(value);
    }
  }

  static String _statusText(dynamic value) {
    switch (value?.toString()) {
      case 'active':
        return 'Hoạt động';
      case 'suspended':
        return 'Tạm khóa';
      case 'expired':
        return 'Hết hạn';
      default:
        return apiText(value);
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.last = false});

  final String label;
  final dynamic value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(
                  color: kLibBrownTitle.withValues(alpha: .34),
                ),
              ),
      ),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            color: kLibBrownTitle,
            fontSize: 15,
            height: 1.25,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: apiText(value),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 27),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderAvatar extends StatelessWidget {
  const _ReaderAvatar({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final value = url?.trim() ?? '';
    final bytes = decodeDataImage(value);
    final fallback = Container(
      color: kLibBeigeSoft,
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 74, color: kLibBrownTitle),
    );
    return Center(
      child: ClipOval(
        child: SizedBox(
          width: 152,
          height: 152,
          child: bytes != null
              ? Image.memory(bytes, fit: BoxFit.cover)
              : value.isEmpty
              ? fallback
              : Image.network(
                  apiAssetUrl(value),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => fallback,
                ),
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    required this.label,
    this.keyboard,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class _EditDropdown extends StatelessWidget {
  const _EditDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: values.entries
            .map(
              (entry) =>
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            )
            .toList(),
        onChanged: (newValue) {
          if (newValue != null) onChanged(newValue);
        },
      ),
    );
  }
}
