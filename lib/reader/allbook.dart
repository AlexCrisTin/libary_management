import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/reader/detailbook.dart';
import 'package:libary_management/reader/reader_nav.dart';

class AllBook extends StatefulWidget {
  const AllBook({super.key});
  @override
  State<AllBook> createState() => _AllBookState();
}

class _AllBookState extends State<AllBook> {
  List<Map<String, dynamic>> _books = const [];
  bool _loading = true;
  String? _error;
  String _keyword = '';
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
      final result = apiMap(
        await ApiClient.get(
          '/books',
          query: {'keyword': _keyword, 'limit': 100},
        ),
      );
      if (mounted) setState(() => _books = apiList(result['items']));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SearchHeaderBar(
        onSubmitted: (value) {
          _keyword = value.trim();
          _load();
        },
      ),
      Expanded(
        child: ApiStateView(
          loading: _loading,
          error: _error,
          isEmpty: _books.isEmpty,
          onRetry: _load,
          emptyMessage: 'Không tìm thấy sách',
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _books.length,
              separatorBuilder: (_, __) => const Divider(height: 28),
              itemBuilder: (_, i) {
                final b = _books[i];
                final authors = b['authors'] is List
                    ? (b['authors'] as List).join(', ')
                    : apiText(b['authors']);
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailBook(
                        bookId: apiText(b['bib_id'], fallback: ''),
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BookCover(
                        width: 72,
                        height: 108,
                        url: b['cover_url']?.toString(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              apiText(b['title']),
                              style: const TextStyle(
                                color: kBookTitle,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tác giả: $authors',
                              style: const TextStyle(color: kMuted),
                            ),
                            Text(
                              'Còn: ${b['available_copies'] ?? 0}/${b['total_copies'] ?? 0}',
                              style: const TextStyle(color: kMuted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ],
  );
}
