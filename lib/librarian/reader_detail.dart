import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';

import 'librarian_nav.dart';

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

  @override
  Widget build(BuildContext context) => Scaffold(
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
              padding: const EdgeInsets.all(22),
              children: [
                const CircleAvatar(
                  radius: 72,
                  backgroundColor: kLibBeigeSoft,
                  child: Icon(Icons.person, size: 72, color: kLibBrownTitle),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kLibCardFill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Thông tin độc giả',
                        style: TextStyle(
                          color: kLibBrownTitle,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _row('Họ và tên', _reader['full_name']),
                      _row('Mã độc giả', _reader['reader_code']),
                      _row('Ngày sinh', apiDate(_reader['birth_date'])),
                      _row('Số điện thoại', _reader['phone']),
                      _row('Email', _reader['email']),
                      _row('Khoa', _reader['faculty']),
                      _row('Loại độc giả', _reader['reader_type']),
                      _row('Trạng thái', _reader['status']),
                      _row('Hạn thẻ', apiDate(_reader['card_expired'])),
                      _row(
                        'Số sách đang mượn',
                        _reader['currently_borrowed_count'],
                        last: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  Widget _row(String label, dynamic value, {bool last = false}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      border: last
          ? null
          : Border(
              bottom: BorderSide(color: kLibBrownTitle.withValues(alpha: .25)),
            ),
    ),
    child: Text(
      '$label: ${apiText(value)}',
      style: const TextStyle(
        color: kLibBrownTitle,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
