import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/reader/reader_nav.dart';

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
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _hold() async {
    try {
      await ApiClient.post('/holds', body: {'bib_id': widget.bookId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt trước sách thành công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        const TitleHeader(title: 'Thông tin sách', showBack: true),
        Expanded(
          child: ApiStateView(
            loading: _loading,
            error: _error,
            isEmpty: _book.isEmpty,
            onRetry: _load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: BookCover(
                    width: 168,
                    height: 253,
                    url: _book['cover_url']?.toString(),
                  ),
                ),
                const SizedBox(height: 16),
                if ((_book['available_copies'] as num?)?.toInt() == 0)
                  Center(
                    child: ElevatedButton(
                      onPressed: _hold,
                      child: const Text('Đặt trước'),
                    ),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: kCardFill,
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
                        _book['authors'] is List
                            ? (_book['authors'] as List).join(', ')
                            : _book['authors'],
                      ),
                      _row('Nhà xuất bản', _book['publisher_name']),
                      _row('Năm xuất bản', _book['publish_year']),
                      _row('Ngôn ngữ', _book['language']),
                      _row('Số trang', _book['page_count']),
                      _row('Mô tả', _book['description']),
                      _row(
                        'Số bản còn',
                        '${_book['available_copies'] ?? 0}/${_book['total_copies'] ?? 0}',
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
  Widget _row(String label, dynamic value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      '$label: ${apiText(value)}',
      style: const TextStyle(
        color: kBookTitle,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
