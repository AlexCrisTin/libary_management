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
        onOpenNotice: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Notice()),
          );
        },
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
                MaterialPageRoute(
                  builder: (_) => Message(
                    onSelectTab: (index) => setState(() => _index = index),
                  ),
                ),
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
  final Future<void> Function()? onOpenNotice;
  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  List<Map<String, dynamic>> _books = const [];
  int _unreadNotices = 0;
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
        await ApiClient.get('/books', query: {'limit': 30}),
      );
      if (mounted) setState(() => _books = apiList(result['items']));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    await _loadUnreadNotices();
  }

  Future<void> _loadUnreadNotices() async {
    try {
      final result = apiMap(await ApiClient.get('/notifications/unread-count'));
      final count = int.tryParse('${result['unread_count'] ?? 0}') ?? 0;
      if (mounted) setState(() => _unreadNotices = count);
    } catch (_) {
      // Trang sách vẫn hoạt động khi tài khoản chưa liên kết thẻ độc giả.
    }
  }

  Future<void> _openNotice() async {
    await widget.onOpenNotice?.call();
    await _loadUnreadNotices();
  }

  void _openBook(Map<String, dynamic> book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DetailBook(bookId: apiText(book['bib_id'], fallback: '')),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _categoryGroups() {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final book in _books) {
      final subjects = book['subject_headings'];
      final category = subjects is List && subjects.isNotEmpty
          ? apiText(subjects.first, fallback: 'Sách nổi bật')
          : 'Sách nổi bật';
      groups.putIfAbsent(category, () => []).add(book);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SearchHeaderBar(
        readOnly: true,
        onTap: widget.onOpenSearch,
        trailing: _NotificationButton(
          unread: _unreadNotices,
          onPressed: _openNotice,
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
            child: _HomeBookList(
              books: _books,
              categories: _categoryGroups(),
              onOpenBook: _openBook,
            ),
          ),
        ),
      ),
    ],
  );
}

class _HomeBookList extends StatelessWidget {
  const _HomeBookList({
    required this.books,
    required this.categories,
    required this.onOpenBook,
  });

  final List<Map<String, dynamic>> books;
  final Map<String, List<Map<String, dynamic>>> categories;
  final ValueChanged<Map<String, dynamic>> onOpenBook;

  @override
  Widget build(BuildContext context) {
    final hotBooks = books.take(10).toList();
    final categoryEntries = categories.entries.take(4).toList();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
      children: [
        const _SectionTitle('Sách đang hot'),
        const SizedBox(height: 16),
        SizedBox(
          height: 232,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: hotBooks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 20),
            itemBuilder: (_, index) => _HotBookCard(
              book: hotBooks[index],
              onTap: () => onOpenBook(hotBooks[index]),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Khám phá chủ đề'),
        const SizedBox(height: 14),
        for (final entry in categoryEntries) ...[
          Text(
            entry.key,
            style: const TextStyle(
              color: Color(0xFFC05E5E),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final book in entry.value.take(3)) ...[
            _SubjectBookCard(book: book, onTap: () => onOpenBook(book)),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: kBrownTitle,
        fontSize: 27,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _HotBookCard extends StatelessWidget {
  const _HotBookCard({required this.book, required this.onTap});

  final Map<String, dynamic> book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 128,
        child: Column(
          children: [
            BookCover(
              width: 124,
              height: 184,
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
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectBookCard extends StatelessWidget {
  const _SubjectBookCard({required this.book, required this.onTap});

  final Map<String, dynamic> book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final authors = book['authors'] is List
        ? (book['authors'] as List).map((value) => value.toString()).join(', ')
        : apiText(book['authors']);
    final subjects = book['subject_headings'] is List
        ? (book['subject_headings'] as List)
              .map((value) => value.toString())
              .join(', ')
        : apiText(book['subject_headings']);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardFill,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookCover(
            width: 104,
            height: 156,
            url: book['cover_url']?.toString(),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: SizedBox(
              height: 156,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    apiText(book['title']),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kBookTitle,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  _BookMeta(label: 'Tác giả', value: authors),
                  _BookMeta(label: 'Thể loại', value: subjects),
                  _BookMeta(
                    label: 'Năm xuất bản',
                    value: apiText(book['publish_year']),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          apiText(book['description'], fallback: ''),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: kMuted.withValues(alpha: .85),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBeigeButton,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: const Text(
                          'Xem sách',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
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

class _BookMeta extends StatelessWidget {
  const _BookMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty || value == '—') return const SizedBox.shrink();
    return Text(
      '$label: $value',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: kMuted, fontSize: 12),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.unread, required this.onPressed});

  final int unread;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: unread > 0,
      backgroundColor: const Color(0xFFD18282),
      label: Text(unread > 99 ? '99+' : '$unread'),
      child: IconButton(
        tooltip: 'Thông báo',
        onPressed: onPressed,
        icon: const Icon(Icons.notifications_rounded, color: kBrownTitle),
      ),
    );
  }
}
