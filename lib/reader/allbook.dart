import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/reader/detailbook.dart';
import 'package:libary_management/reader/notice.dart';
import 'package:libary_management/reader/reader_nav.dart';

class AllBook extends StatefulWidget {
  const AllBook({super.key});

  @override
  State<AllBook> createState() => _AllBookState();
}

class _AllBookState extends State<AllBook> {
  List<Map<String, dynamic>> _allBooks = const [];
  bool _loading = true;
  String? _error;
  String _keyword = '';
  String _ddcClass = '';
  String _author = '';
  String _subject = '';
  String _language = '';
  String _publishYear = '';
  String? _selectedSubject;
  bool _availableOnly = false;
  int _unreadNotices = 0;

  List<Map<String, dynamic>> get _books {
    return _allBooks.where((book) {
      final subjectMatches =
          _selectedSubject == null ||
          _subjectNames(book).contains(_selectedSubject);
      final available = int.tryParse('${book['available_copies'] ?? 0}') ?? 0;
      return subjectMatches && (!_availableOnly || available > 0);
    }).toList();
  }

  List<String> get _subjects {
    final values = <String>{};
    for (final book in _allBooks) {
      values.addAll(_subjectNames(book));
    }
    return values.toList()..sort();
  }

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
          query: {
            'keyword': _keyword,
            'ddc_class': _ddcClass,
            'author': _author,
            'subject': _subject,
            'language': _language,
            'publish_year': _publishYear,
            'limit': 100,
          },
        ),
      );
      if (mounted) {
        setState(() {
          _allBooks = apiList(result['items']);
          if (_selectedSubject != null &&
              !_allBooks.any(
                (book) => _subjectNames(book).contains(_selectedSubject),
              )) {
            _selectedSubject = null;
          }
        });
      }
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
      // Danh sách sách vẫn dùng được nếu tài khoản chưa liên kết độc giả.
    }
  }

  Future<void> _openNotice() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Notice()),
    );
    await _loadUnreadNotices();
  }

  Future<void> _openFilters() async {
    final ddcController = TextEditingController(text: _ddcClass);
    final authorController = TextEditingController(text: _author);
    final subjectController = TextEditingController(text: _subject);
    final languageController = TextEditingController(text: _language);
    final yearController = TextEditingController(text: _publishYear);
    var availableOnly = _availableOnly;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: kCardFill,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            22,
            4,
            22,
            22 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bộ lọc sách',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kBrownTitle,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              _FilterTextField(
                controller: authorController,
                label: 'Tác giả',
                hint: 'Ví dụ: Nguyễn Nhật Ánh',
                icon: Icons.person_search_outlined,
              ),
              const SizedBox(height: 10),
              _FilterTextField(
                controller: subjectController,
                label: 'Thể loại / Chủ đề',
                hint: 'Ví dụ: Giáo dục, Công nghệ...',
                icon: Icons.category_outlined,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _FilterTextField(
                      controller: languageController,
                      label: 'Ngôn ngữ',
                      hint: 'vi, en...',
                      icon: Icons.language_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FilterTextField(
                      controller: yearController,
                      label: 'Năm xuất bản',
                      hint: '2026',
                      icon: Icons.calendar_month_outlined,
                      keyboard: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ddcController,
                decoration: InputDecoration(
                  labelText: 'Mã phân loại DDC',
                  hintText: 'Ví dụ: 004, 330...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: kBrownTitle,
                title: const Text('Chỉ hiển thị sách còn bản'),
                value: availableOnly,
                onChanged: (value) =>
                    setSheetState(() => availableOnly = value),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ddcController.clear();
                        authorController.clear();
                        subjectController.clear();
                        languageController.clear();
                        yearController.clear();
                        setSheetState(() => availableOnly = false);
                      },
                      child: const Text('Đặt lại'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: kBrownTitle,
                      ),
                      onPressed: () {
                        final yearText = yearController.text.trim();
                        final year = int.tryParse(yearText);
                        if (yearText.isNotEmpty &&
                            (year == null || year < 1000 || year > 9999)) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                              content: Text('Năm xuất bản không hợp lệ.'),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(sheetContext, true);
                      },
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (applied == true && mounted) {
      setState(() {
        _ddcClass = ddcController.text.trim();
        _author = authorController.text.trim();
        _subject = subjectController.text.trim();
        _language = languageController.text.trim();
        _publishYear = yearController.text.trim();
        _availableOnly = availableOnly;
      });
      await _load();
    }
    ddcController.dispose();
    authorController.dispose();
    subjectController.dispose();
    languageController.dispose();
    yearController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final books = _books;
    return Column(
      children: [
        SearchHeaderBar(
          initialText: _keyword,
          onSubmitted: (value) {
            _keyword = value.trim();
            _load();
          },
          trailing: Badge(
            isLabelVisible: _unreadNotices > 0,
            backgroundColor: const Color(0xFFD18282),
            label: Text(_unreadNotices > 99 ? '99+' : '$_unreadNotices'),
            child: IconButton(
              tooltip: 'Thông báo',
              onPressed: _openNotice,
              icon: const Icon(Icons.notifications_rounded, color: kBrownTitle),
            ),
          ),
        ),
        _SubjectFilters(
          subjects: _subjects,
          selected: _selectedSubject,
          filtered:
              _ddcClass.isNotEmpty ||
              _author.isNotEmpty ||
              _subject.isNotEmpty ||
              _language.isNotEmpty ||
              _publishYear.isNotEmpty ||
              _availableOnly,
          onSelected: (subject) => setState(() => _selectedSubject = subject),
          onOpenFilter: _openFilters,
        ),
        Expanded(
          child: ApiStateView(
            loading: _loading,
            error: _error,
            isEmpty: books.isEmpty,
            onRetry: _load,
            emptyMessage: 'Không tìm thấy sách phù hợp',
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(height: 13),
                itemBuilder: (_, index) => _BookResultCard(
                  book: books[index],
                  onTap: () => _openBook(books[index]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterTextField extends StatelessWidget {
  const _FilterTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboard,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: kBrownTitle),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SubjectFilters extends StatelessWidget {
  const _SubjectFilters({
    required this.subjects,
    required this.selected,
    required this.filtered,
    required this.onSelected,
    required this.onOpenFilter,
  });

  final List<String> subjects;
  final String? selected;
  final bool filtered;
  final ValueChanged<String?> onSelected;
  final VoidCallback onOpenFilter;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, right: 10),
            child: Text(
              'Lọc Chủ đề',
              style: TextStyle(
                color: kBrownTitle,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _SubjectChip(
                  label: 'Tất cả',
                  selected: selected == null,
                  onTap: () => onSelected(null),
                ),
                for (final subject in subjects) ...[
                  const SizedBox(width: 8),
                  _SubjectChip(
                    label: subject,
                    selected: selected == subject,
                    onTap: () => onSelected(subject),
                  ),
                ],
              ],
            ),
          ),
          Badge(
            isLabelVisible: filtered,
            smallSize: 9,
            backgroundColor: kBrownTitle,
            child: IconButton(
              tooltip: 'Bộ lọc nâng cao',
              onPressed: onOpenFilter,
              icon: const Icon(
                Icons.tune_rounded,
                color: Color(0xFFFF8B5C),
                size: 29,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: kBrownTitle,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? kBrownTitle : const Color(0xFFD7D7D7),
        width: 1.5,
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFFB9B9B9),
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    );
  }
}

class _BookResultCard extends StatelessWidget {
  const _BookResultCard({required this.book, required this.onTap});

  final Map<String, dynamic> book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final authors = _authorNames(book);
    final subjects = _subjectNames(book).join(', ');
    final available = int.tryParse('${book['available_copies'] ?? 0}') ?? 0;
    final total = int.tryParse('${book['total_copies'] ?? 0}') ?? 0;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kCardFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookCover(
            width: 108,
            height: 162,
            url: book['cover_url']?.toString(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 162,
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
                  const SizedBox(height: 8),
                  _ResultMeta(label: 'Tác giả', value: authors),
                  _ResultMeta(label: 'Thể loại', value: subjects),
                  _ResultMeta(
                    label: 'Năm xuất bản',
                    value: apiText(book['publish_year']),
                  ),
                  _ResultMeta(label: 'Số bản còn', value: '$available/$total'),
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
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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

class _ResultMeta extends StatelessWidget {
  const _ResultMeta({required this.label, required this.value});

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

List<String> _subjectNames(Map<String, dynamic> book) {
  final subjects = book['subject_headings'];
  if (subjects is! List) return const [];
  return subjects
      .map((value) => value.toString().trim())
      .where((value) => value.isNotEmpty)
      .toList();
}

String _authorNames(Map<String, dynamic> book) {
  final authors = book['authors'];
  if (authors is! List) return apiText(authors);
  return authors
      .map((value) {
        if (value is Map) return value['name']?.toString().trim() ?? '';
        return value.toString().trim();
      })
      .where((value) => value.isNotEmpty)
      .join(', ');
}
