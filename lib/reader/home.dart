import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/reader/allbook.dart';
import 'package:libary_management/reader/detailbook.dart';
import 'package:libary_management/reader/message.dart';
import 'package:libary_management/reader/notice.dart';
import 'package:libary_management/reader/profile.dart';
import 'package:libary_management/reader/qr_scanner.dart';
import 'package:libary_management/reader/reader_nav.dart';
import 'package:libary_management/reader/seeborrowbook.dart';

class Home extends StatefulWidget {
  const Home({super.key, this.initialIndex = 0});
  final int initialIndex;
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late int _index;
  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeContent(
        onOpenSearch: () => setState(() => _index = 1),
        onOpenNotice: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Notice()),
        ),
      ),
      const AllBook(),
      const SizedBox.shrink(),
      SeeBorrowBook(onOpenSearch: () => setState(() => _index = 1)),
      const Profile(),
    ];
    return Scaffold(
      backgroundColor: Colors.white,
      body: pages[_index],
      floatingActionButton: _index < 4
          ? ChatFab(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Message()),
              ),
            )
          : null,
      bottomNavigationBar: ReaderBottomBar(
        currentIndex: _index,
        onSelect: (i) => setState(() => _index = i),
        onScan: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QrScanner()),
        ),
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key, this.onOpenSearch, this.onOpenNotice});
  final VoidCallback? onOpenSearch;
  final VoidCallback? onOpenNotice;
  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<Map<String, dynamic>> _books = const [];
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
        await ApiClient.get('/books', query: {'limit': 10}),
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
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SearchHeaderBar(
        readOnly: true,
        onTap: widget.onOpenSearch,
        trailing: IconButton(
          onPressed: widget.onOpenNotice,
          icon: const Icon(Icons.notifications_none, color: Colors.white),
        ),
      ),
      Expanded(
        child: ApiStateView(
          loading: _loading,
          error: _error,
          isEmpty: _books.isEmpty,
          onRetry: _load,
          emptyMessage: 'Thư viện chưa có sách',
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Sách mới',
                  style: TextStyle(
                    color: kBrownTitle,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _books.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (_, i) {
                      final book = _books[i];
                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailBook(
                              bookId: apiText(book['bib_id'], fallback: ''),
                            ),
                          ),
                        ),
                        child: SizedBox(
                          width: 118,
                          child: Column(
                            children: [
                              BookCover(
                                width: 113,
                                height: 169,
                                url: book['cover_url']?.toString(),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                apiText(book['title']),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: kBookTitle,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
