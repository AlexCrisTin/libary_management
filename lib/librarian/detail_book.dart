import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/core/local_image.dart';

import 'librarian_nav.dart';
import 'librarian_scanner.dart';
import 'librarian_shell.dart';

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
  String? _error;

  List<Map<String, dynamic>> get _copies => apiList(_book['copies']);

  int get _totalCopies => int.tryParse('${_book['total_copies'] ?? 0}') ?? 0;

  int get _availableCopies =>
      int.tryParse('${_book['available_copies'] ?? 0}') ?? 0;

  int get _borrowedCopies =>
      _copies.where((copy) => copy['status']?.toString() == 'borrowed').length;

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

  void _openTab(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LibrarianShell(initialIndex: index)),
      (_) => false,
    );
  }

  Future<void> _borrowBook() async {
    final available = _copies.where(
      (copy) => copy['status']?.toString() == 'available',
    );
    if (available.isEmpty) {
      _showMessage('Sách hiện không còn bản sao có thể cho mượn.');
      return;
    }

    final readerCodeController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cho mượn sách'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              apiText(_book['title']),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: readerCodeController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Mã độc giả',
                hintText: 'Ví dụ: RD-123456',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Bản sao: ${apiText(available.first['barcode'])}',
              style: const TextStyle(color: kLibBrownTitle),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (readerCodeController.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    final readerCode = readerCodeController.text.trim();
    readerCodeController.dispose();
    if (confirmed != true || readerCode.isEmpty || !mounted) return;

    setState(() => _submitting = true);
    try {
      await ApiClient.post(
        '/circulation/borrow',
        body: {
          'reader_code': readerCode,
          'copy_id': available.first['copy_id'],
        },
      );
      if (!mounted) return;
      _showMessage('Cho mượn sách thành công.');
      await _load();
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _editBook() async {
    final title = TextEditingController(
      text: apiText(_book['title'], fallback: ''),
    );
    final subtitle = TextEditingController(
      text: apiText(_book['subtitle'], fallback: ''),
    );
    final isbn = TextEditingController(
      text: apiText(_book['isbn'], fallback: ''),
    );
    final authors = TextEditingController(text: _authorsText);
    final year = TextEditingController(
      text: apiText(_book['publish_year'], fallback: ''),
    );
    final language = TextEditingController(
      text: apiText(_book['language'], fallback: ''),
    );
    final pageCount = TextEditingController(
      text: apiText(_book['page_count'], fallback: ''),
    );
    final description = TextEditingController(
      text: apiText(_book['description'], fallback: ''),
    );

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chỉnh sửa thông tin sách',
                style: TextStyle(
                  color: kLibBrownTitle,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              _editField(title, 'Tên sách'),
              _editField(subtitle, 'Phụ đề'),
              _editField(isbn, 'ISBN'),
              _editField(authors, 'Tác giả', hint: 'Ngăn cách bằng dấu phẩy'),
              _editField(year, 'Năm xuất bản', number: true),
              _editField(language, 'Ngôn ngữ'),
              _editField(pageCount, 'Số trang', number: true),
              _editField(description, 'Mô tả', lines: 3),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: kLibBeigeButton,
                  ),
                  child: const Text('Lưu thay đổi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved == true && mounted) {
      setState(() => _submitting = true);
      try {
        await ApiClient.put(
          '/books/${widget.bookId}',
          body: {
            'title': title.text.trim(),
            'subtitle': _nullable(subtitle.text),
            'isbn': _nullable(isbn.text),
            'authors': authors.text
                .split(',')
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toList(),
            'publish_year': int.tryParse(year.text),
            'language': _nullable(language.text),
            'page_count': int.tryParse(pageCount.text),
            'description': _nullable(description.text),
          },
        );
        if (!mounted) return;
        _showMessage('Cập nhật sách thành công.');
        await _load();
      } catch (error) {
        if (mounted) _showMessage(error.toString());
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    }

    for (final controller in [
      title,
      subtitle,
      isbn,
      authors,
      year,
      language,
      pageCount,
      description,
    ]) {
      controller.dispose();
    }
  }

  String? _nullable(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  String get _authorsText {
    final authors = _book['authors'];
    if (authors is! List) return apiText(authors, fallback: '');
    return authors
        .map((author) {
          if (author is Map) return apiText(author['name'], fallback: '');
          return apiText(author, fallback: '');
        })
        .where((name) => name.isNotEmpty)
        .join(', ');
  }

  String get _subjectsText {
    final subjects = _book['subject_headings'];
    if (subjects is! List) return apiText(subjects, fallback: '');
    return subjects
        .map((value) => apiText(value, fallback: ''))
        .where((value) => value.isNotEmpty)
        .join(', ');
  }

  String get _conditionText {
    final values = _copies
        .map((copy) => apiText(copy['condition'], fallback: ''))
        .where((value) => value.isNotEmpty)
        .toSet();
    return values.join(', ');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          LibTitleHeader(
            title: 'Thông tin sách',
            showBack: true,
            trailing: IconButton(
              tooltip: 'Chỉnh sửa sách',
              onPressed: _loading || _submitting ? null : _editBook,
              icon: const Icon(
                Icons.edit_square,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
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
                  padding: const EdgeInsets.fromLTRB(18, 34, 18, 24),
                  children: [
                    _CoverCard(book: _book),
                    Transform.translate(
                      offset: const Offset(0, -22),
                      child: Center(
                        child: SizedBox(
                          width: 180,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _availableCopies > 0 && !_submitting
                                ? _borrowBook
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kLibBeigeButton,
                              disabledBackgroundColor: kLibBeigeSoft,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    _availableCopies > 0
                                        ? 'Cho mượn'
                                        : 'Đã hết sách',
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _InformationCard(
                      book: _book,
                      authors: _authorsText,
                      subjects: _subjectsText,
                      condition: _conditionText,
                      borrowedCopies: _borrowedCopies,
                      totalCopies: _totalCopies,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: LibrarianBottomBar(
        currentIndex: 1,
        onSelect: _openTab,
        onScan: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LibrarianScanner()),
        ),
      ),
    );
  }

  Widget _editField(
    TextEditingController controller,
    String label, {
    String? hint,
    bool number = false,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: number
            ? TextInputType.number
            : lines > 1
            ? TextInputType.multiline
            : null,
        minLines: lines,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({required this.book});

  final Map<String, dynamic> book;

  @override
  Widget build(BuildContext context) {
    final url = book['cover_url']?.toString().trim() ?? '';
    final localBytes = decodeDataImage(url);
    return Center(
      child: Container(
        width: 252,
        height: 326,
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: kLibCardFill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: localBytes != null
              ? Image.memory(localBytes, fit: BoxFit.cover)
              : url.isEmpty
              ? Container(
                  color: kLibBeigeSoft,
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 74,
                        color: kLibBrownTitle,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Chưa có ảnh bìa',
                        style: TextStyle(
                          color: kLibBrownTitle,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              : Image.network(
                  apiAssetUrl(url),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: kLibBeigeSoft,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 62,
                      color: kLibBrownTitle,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.book,
    required this.authors,
    required this.subjects,
    required this.condition,
    required this.borrowedCopies,
    required this.totalCopies,
  });

  final Map<String, dynamic> book;
  final String authors;
  final String subjects;
  final String condition;
  final int borrowedCopies;
  final int totalCopies;

  @override
  Widget build(BuildContext context) {
    final metadata = apiMap(book['metadata']);
    final rows = <Widget?>[
      _info('Tên sách', book['title']),
      _info('Phụ đề', book['subtitle']),
      _info('ISBN', book['isbn']),
      _info('Tác giả', authors),
      _info('Năm xuất bản', book['publish_year']),
      _info(
        'Nhà xuất bản',
        book['publisher_name'] ?? metadata['publisher_name'],
      ),
      _info('Ấn bản', book['edition']),
      _info('Thể loại', subjects),
      _info('Phân loại DDC', book['ddc_class']),
      _info('Ngôn ngữ', book['language']),
      _info('Số trang', book['page_count']),
      _info('Mã xếp giá', book['call_number']),
      _info('Tình trạng', condition),
      _info(
        'Số bản còn',
        '${book['available_copies'] ?? 0}/${book['total_copies'] ?? 0}',
      ),
      _info('Mô tả', book['description'], multiline: true),
    ].whereType<Widget>().toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: kLibCardFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Thông tin sách',
            style: TextStyle(
              color: kLibBookTitle,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          Container(
            width: 124,
            height: 1,
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            color: kLibBrownTitle.withValues(alpha: .4),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rows,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 112,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                decoration: BoxDecoration(
                  color: kLibRed,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Số người\nđang mượn',
                      style: TextStyle(
                        color: kLibBookTitle,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Icon(
                      Icons.library_books_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$borrowedCopies/$totalCopies',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _info(String label, dynamic value, {bool multiline = false}) {
    final text = apiText(value, fallback: '');
    if (text.isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Text(
        '$label: $text',
        maxLines: multiline ? null : 3,
        overflow: multiline ? null : TextOverflow.ellipsis,
        style: const TextStyle(
          color: kLibBookTitle,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }
}
