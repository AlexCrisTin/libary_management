import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/reader/reader_nav.dart';

class SeeBorrowBook extends StatefulWidget {
  const SeeBorrowBook({super.key, this.onOpenSearch});
  final VoidCallback? onOpenSearch;
  @override
  State<SeeBorrowBook> createState() => _SeeBorrowBookState();
}

class _SeeBorrowBookState extends State<SeeBorrowBook> {
  List<Map<String, dynamic>> _loans = const [];
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
      final result = apiMap(
        await ApiClient.get('/circulation/active', query: {'limit': 100}),
      );
      if (mounted) setState(() => _loans = apiList(result['data']));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _renew(String id) async {
    try {
      await ApiClient.post('/circulation/renew/$id');
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SearchHeaderBar(readOnly: true, onTap: widget.onOpenSearch),
      Expanded(
        child: ApiStateView(
          loading: _loading,
          error: _error,
          isEmpty: _loans.isEmpty,
          onRetry: _load,
          emptyMessage: 'Bạn chưa mượn sách nào',
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _loans.length,
              separatorBuilder: (_, __) => const Divider(height: 28),
              itemBuilder: (_, i) {
                final loan = _loans[i];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BookCover(url: loan['cover_url']?.toString()),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            apiText(loan['book_title']),
                            style: const TextStyle(
                              color: kBookTitle,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text('Ngày mượn: ${apiDate(loan['borrow_date'])}'),
                          Text('Hạn trả: ${apiDate(loan['due_date'])}'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () =>
                                _renew(apiText(loan['tx_id'], fallback: '')),
                            child: const Text('Gia hạn'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ],
  );
}
