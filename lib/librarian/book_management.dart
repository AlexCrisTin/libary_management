import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';

import 'detail_book.dart';
import 'form_addbook.dart';
import 'librarian_nav.dart';

class BookManagement extends StatefulWidget {
  const BookManagement({super.key});

  @override
  State<BookManagement> createState() => _BookManagementState();
}

class _BookManagementState extends State<BookManagement> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _books = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
          query: {'keyword': _search.text.trim(), 'limit': 100},
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const LibTitleHeader(title: 'Quản lý sách'),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onSubmitted: (_) => _load(),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            width: 3,
                            color: Color(0xFFDDDDDD),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            width: 3,
                            color: Color(0xFFDDDDDD),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh, color: kLibBrownTitle),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 11, bottom: 8),
                child: IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: kLibBeigeButton),
                  onPressed: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const FormAddBook()),
                    );
                    if (changed == true) _load();
                  },
                  icon: const Icon(Icons.add),
                ),
              ),
            ),
            const _BookHeader(),
            Expanded(
              child: ApiStateView(
                loading: _loading,
                error: _error,
                isEmpty: _books.isEmpty,
                onRetry: _load,
                emptyMessage: 'Chưa có sách trong hệ thống',
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(11, 6, 11, 8),
                    itemCount: _books.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _BookRow(
                      book: _books[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailBook(
                            bookId: apiText(_books[i]['bib_id'], fallback: ''),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookHeader extends StatelessWidget {
  const _BookHeader();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 11),
    height: 44,
    decoration: BoxDecoration(
      color: kLibBeigeButton,
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Row(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: EdgeInsets.only(left: 8),
            child: Text('Sách', style: _header),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(child: Text('Trạng thái', style: _header)),
        ),
        Expanded(
          flex: 2,
          child: Center(child: Text('Số lượng', style: _header)),
        ),
        Expanded(
          flex: 2,
          child: Center(child: Text('Chi tiết', style: _header)),
        ),
      ],
    ),
  );
}

const _header = TextStyle(
  color: Colors.white,
  fontSize: 13,
  fontWeight: FontWeight.w700,
);

class _BookRow extends StatelessWidget {
  const _BookRow({required this.book, required this.onTap});
  final Map<String, dynamic> book;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final available = int.tryParse('${book['available_copies'] ?? 0}') ?? 0;
    final total = int.tryParse('${book['total_copies'] ?? 0}') ?? 0;
    const style = TextStyle(
      color: kLibBookTitle,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(apiText(book['title']), style: style)),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: available > 0
                      ? const Color(0xFFC2E2B5)
                      : const Color(0xFFFFCDD2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(available > 0 ? 'Còn' : 'Hết', style: style),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(child: Text('$available/$total', style: style)),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: kLibBeigeButton),
                onPressed: onTap,
                icon: const Icon(Icons.chevron_right, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
