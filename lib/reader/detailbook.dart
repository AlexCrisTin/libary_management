import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/reader/home.dart';
import 'package:libary_management/reader/message.dart';
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
  bool _submitting = false;
  bool _bookmarked = false;
  bool _suggestionsLoading = false;
  List<Map<String, dynamic>> _suggestionPool = const [];
  List<Map<String, dynamic>> _suggestedBooks = const [];
  String? _suggestionsError;
  String? _error;

  int get _availableCopies =>
      int.tryParse('${_book['available_copies'] ?? 0}') ?? 0;

  int get _totalCopies => int.tryParse('${_book['total_copies'] ?? 0}') ?? 0;

  int get _borrowedCopies {
    final copies = _book['copies'];
    if (copies is! List) return 0;
    return copies.where((copy) {
      return copy is Map && copy['status']?.toString() == 'borrowed';
    }).length;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var bookLoaded = false;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = apiMap(await ApiClient.get('/books/${widget.bookId}'));
      if (mounted) {
        setState(() => _book = data);
        bookLoaded = true;
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (bookLoaded) await _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    if (!mounted) return;
    setState(() {
      _suggestionsLoading = true;
      _suggestionsError = null;
    });
    try {
      final result = apiMap(
        await ApiClient.get('/books', query: {'limit': 100}),
      );
      final books = apiList(result['items']).where((book) {
        return apiText(book['bib_id'], fallback: '') != widget.bookId;
      }).toList();
      books.shuffle();
      if (mounted) {
        setState(() {
          _suggestionPool = books;
          _suggestedBooks = books.take(3).toList();
        });
      }
    } catch (error) {
      if (mounted) setState(() => _suggestionsError = error.toString());
    } finally {
      if (mounted) setState(() => _suggestionsLoading = false);
    }
  }

  void _shuffleSuggestions() {
    if (_suggestionPool.isEmpty) return;
    final shuffled = [..._suggestionPool]..shuffle();
    setState(() => _suggestedBooks = shuffled.take(3).toList());
  }

  Future<void> _borrowOrHold() async {
    if (_availableCopies > 0) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: kCardFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Sách đang có sẵn',
            style: TextStyle(color: kBrownTitle, fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Hiện còn $_availableCopies bản trên kệ. '
            'Bạn hãy đến quầy thủ thư để làm thủ tục mượn sách.',
            style: const TextStyle(color: kBookTitle, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiClient.post('/holds', body: {'bib_id': widget.bookId});
      _showMessage('Đặt trước sách thành công.');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toggleBookmark() {
    setState(() => _bookmarked = !_bookmarked);
    _showMessage(_bookmarked ? 'Đã lưu sách.' : 'Đã bỏ lưu sách.');
  }

  void _openTab(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => Home(initialIndex: index)),
      (_) => false,
    );
  }

  void _openMessage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Message(onSelectTab: _openTab)),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _authors() {
    final authors = _book['authors'];
    if (authors is List) return authors.map(apiText).join(', ');
    return apiText(authors);
  }

  String _subjects() {
    final subjects = _book['subject_headings'];
    if (subjects is List) return subjects.map(apiText).join(', ');
    return apiText(subjects);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _BookHeader(bookmarked: _bookmarked, onBookmark: _toggleBookmark),
          Expanded(
            child: ApiStateView(
              loading: _loading,
              error: _error,
              isEmpty: _book.isEmpty,
              onRetry: _load,
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 32, 18, 92),
                  children: [
                    _BookPresentation(
                      coverUrl: _book['cover_url']?.toString(),
                      available: _availableCopies > 0,
                      submitting: _submitting,
                      onPressed: _borrowOrHold,
                    ),
                    const SizedBox(height: 30),
                    _BookInformationCard(
                      title: apiText(_book['title']),
                      author: _authors(),
                      publishYear: apiText(_book['publish_year']),
                      publisher: apiText(
                        _book['publisher_name'] ??
                            apiMap(_book['metadata'])['publisher_name'],
                      ),
                      subjects: _subjects(),
                      language: apiText(_book['language']),
                      isbn: apiText(_book['isbn']),
                      pageCount: apiText(_book['page_count']),
                      description: apiText(_book['description']),
                      borrowedCopies: _borrowedCopies,
                      totalCopies: _totalCopies,
                    ),
                    const SizedBox(height: 24),
                    _SuggestedBooksSection(
                      books: _suggestedBooks,
                      loading: _suggestionsLoading,
                      error: _suggestionsError,
                      onRetry: _loadSuggestions,
                      onShuffle: _shuffleSuggestions,
                      onOpen: (book) {
                        final id = apiText(book['bib_id'], fallback: '');
                        if (id.isEmpty) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailBook(bookId: id),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: ChatFab(onPressed: _openMessage),
      bottomNavigationBar: ReaderBottomBar(currentIndex: 1, onSelect: _openTab),
    );
  }
}

class _BookHeader extends StatelessWidget {
  const _BookHeader({required this.bookmarked, required this.onBookmark});

  final bool bookmarked;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    return BeigeHeader(
      height: 112,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quay lại',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const Expanded(
            child: Text(
              'Thông tin sách',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kBrownTitle,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: bookmarked ? 'Bỏ lưu sách' : 'Lưu sách',
            onPressed: onBookmark,
            icon: Icon(
              bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookPresentation extends StatelessWidget {
  const _BookPresentation({
    required this.coverUrl,
    required this.available,
    required this.submitting,
    required this.onPressed,
  });

  final String? coverUrl;
  final bool available;
  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 272,
        height: 354,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(
              bottom: 28,
              child: Container(
                padding: const EdgeInsets.fromLTRB(44, 36, 44, 40),
                decoration: BoxDecoration(
                  color: kCardFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: BookCover(width: 184, height: 278, url: coverUrl),
              ),
            ),
            SizedBox(
              width: 152,
              height: 52,
              child: ElevatedButton(
                onPressed: submitting ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBeigeButton,
                  disabledBackgroundColor: kBeigeButton,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        available ? 'Mượn' : 'Đặt trước',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
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

class _BookInformationCard extends StatelessWidget {
  const _BookInformationCard({
    required this.title,
    required this.author,
    required this.publishYear,
    required this.publisher,
    required this.subjects,
    required this.language,
    required this.isbn,
    required this.pageCount,
    required this.description,
    required this.borrowedCopies,
    required this.totalCopies,
  });

  final String title;
  final String author;
  final String publishYear;
  final String publisher;
  final String subjects;
  final String language;
  final String isbn;
  final String pageCount;
  final String description;
  final int borrowedCopies;
  final int totalCopies;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      decoration: BoxDecoration(
        color: kCardFill,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        children: [
          const Text(
            'Thông tin sách',
            style: TextStyle(
              color: kBookTitle,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Container(
            width: 124,
            height: 1,
            margin: const EdgeInsets.only(top: 8, bottom: 14),
            color: kBrownTitle.withValues(alpha: .4),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoLine(label: 'Tên sách', value: title),
                    _InfoLine(label: 'Tác giả', value: author),
                    _InfoLine(label: 'Năm xuất bản', value: publishYear),
                    _InfoLine(label: 'Nhà xuất bản', value: publisher),
                    _InfoLine(label: 'Thể loại', value: subjects),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 114,
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFD08083),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Số người\nđang mượn',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: kBookTitle,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Icon(
                      Icons.auto_stories_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$borrowedCopies/$totalCopies',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                Text('Ngôn ngữ: $language', style: _infoStyle),
                Text('ISBN: $isbn', style: _infoStyle),
                Text('Số trang: $pageCount', style: _infoStyle),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Mô tả: $description',
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: _infoStyle.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

const _infoStyle = TextStyle(
  color: kBookTitle,
  fontSize: 14,
  fontWeight: FontWeight.w700,
);

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label: $value', style: _infoStyle),
    );
  }
}

class _SuggestedBooksSection extends StatelessWidget {
  const _SuggestedBooksSection({
    required this.books,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onShuffle,
    required this.onOpen,
  });

  final List<Map<String, dynamic>> books;
  final bool loading;
  final String? error;
  final Future<void> Function() onRetry;
  final VoidCallback onShuffle;
  final ValueChanged<Map<String, dynamic>> onOpen;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
    decoration: BoxDecoration(
      color: kCardFill,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Có thể bạn muốn xem qua',
                style: TextStyle(
                  color: kBookTitle,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Đổi gợi ý',
              onPressed: books.isEmpty ? null : onShuffle,
              icon: const Icon(Icons.shuffle_rounded, color: kBrownTitle),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (loading)
          const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator(color: kBrownTitle)),
          )
        else if (error != null)
          SizedBox(
            height: 110,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Không tải được sách gợi ý.',
                    style: TextStyle(color: kBrownTitle),
                  ),
                  TextButton(onPressed: onRetry, child: const Text('Thử lại')),
                ],
              ),
            ),
          )
        else if (books.isEmpty)
          const SizedBox(
            height: 90,
            child: Center(
              child: Text(
                'Chưa có đủ sách khác để gợi ý.',
                style: TextStyle(color: kBrownTitle),
              ),
            ),
          )
        else
          SizedBox(
            height: 226,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: books.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) => _SuggestedBookCard(
                book: books[index],
                onTap: () => onOpen(books[index]),
              ),
            ),
          ),
      ],
    ),
  );
}

class _SuggestedBookCard extends StatelessWidget {
  const _SuggestedBookCard({required this.book, required this.onTap});

  final Map<String, dynamic> book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final authors = book['authors'];
    final authorText = authors is List
        ? authors.map(apiText).join(', ')
        : apiText(authors);
    final available = int.tryParse('${book['available_copies'] ?? 0}') ?? 0;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 136,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: BookCover(
                    width: 98,
                    height: 132,
                    url: book['cover_url']?.toString(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  apiText(book['title']),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kBookTitle,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  authorText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: kMuted.withValues(alpha: .9),
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                Text(
                  available > 0 ? 'Còn $available bản' : 'Đang hết sách',
                  style: TextStyle(
                    color: available > 0
                        ? const Color(0xFF4F9B73)
                        : const Color(0xFFD18282),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
