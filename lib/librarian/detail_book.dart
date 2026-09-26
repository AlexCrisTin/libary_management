import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';

import 'librarian_nav.dart';

class DetailBook extends StatefulWidget {
  const DetailBook({super.key, required this.bookId});
  final String bookId;
  @override
  State<DetailBook> createState() => _DetailBookState();
}

class _DetailBookState extends State<DetailBook> {
  Map<String, dynamic> _book = const {};
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
      final data = apiMap(await ApiClient.get('/books/${widget.bookId}'));
      if (mounted) setState(() => _book = data);
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
        const LibTitleHeader(title: 'Thông tin sách', showBack: true),
        Expanded(
          child: ApiStateView(
            loading: _loading,
            error: _error,
            isEmpty: _book.isEmpty,
            onRetry: _load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(child: _cover()),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: kLibCardFill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row('Tên sách', _book['title']),
                      _row('Phụ đề', _book['subtitle']),
                      _row('ISBN', _book['isbn']),
                      _row(
                        'Tác giả',
                        (_book['authors'] is List)
                            ? (_book['authors'] as List).join(', ')
                            : _book['authors'],
                      ),
                      _row('Nhà xuất bản', _book['publisher_name']),
                      _row('Năm xuất bản', _book['publish_year']),
                      _row('Ngôn ngữ', _book['language']),
                      _row('Số trang', _book['page_count']),
                      _row('Mã xếp giá', _book['call_number']),
                      _row('Mô tả', _book['description']),
                      _row(
                        'Số bản còn',
                        '${_book['available_copies'] ?? 0}/${_book['total_copies'] ?? 0}',
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
  Widget _cover() {
    final url = _book['cover_url']?.toString() ?? '';
    return Container(
      width: 168,
      height: 253,
      color: kLibBeigeSoft,
      child: url.isEmpty
          ? const Icon(Icons.menu_book, size: 72, color: kLibBrownTitle)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
            ),
    );
  }

  Widget _row(String label, dynamic value, {bool last = false}) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : 12),
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
