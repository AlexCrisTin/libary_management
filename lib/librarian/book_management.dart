import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';

import 'detail_book.dart';
import 'form_addbook.dart';
import 'librarian_nav.dart';
import 'librarian_pagination.dart';

class BookManagement extends StatefulWidget {
  const BookManagement({super.key});

  @override
  State<BookManagement> createState() => _BookManagementState();
}

class _BookManagementState extends State<BookManagement> {
  static const _pageSize = 20;

  final _search = TextEditingController();
  List<Map<String, dynamic>> _books = const [];
  final Set<String> _deletingIds = <String>{};
  bool _loading = true;
  int _page = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _requestVersion = 0;
  String _subject = '';
  String _copyStatus = '';
  String? _error;

  bool get _hasFilters => _subject.isNotEmpty || _copyStatus.isNotEmpty;

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

  Future<void> _load({int? page}) async {
    final targetPage = page ?? _page;
    final requestVersion = ++_requestVersion;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = apiMap(
        await ApiClient.get(
          '/books',
          query: {
            'keyword': _search.text.trim(),
            'subject': _subject,
            'copy_status': _copyStatus,
            'page': targetPage,
            'limit': _pageSize,
          },
        ),
      );
      if (!mounted || requestVersion != _requestVersion) return;
      final totalPages = int.tryParse('${result['totalPages']}') ?? 1;
      setState(() {
        _books = apiList(result['items']);
        _page = int.tryParse('${result['page']}') ?? targetPage;
        _totalPages = totalPages < 1 ? 1 : totalPages;
        _totalItems = int.tryParse('${result['total']}') ?? _books.length;
      });
    } catch (error) {
      if (mounted && requestVersion == _requestVersion) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted && requestVersion == _requestVersion) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _reloadAfterDelete() async {
    final targetPage = _books.length == 1 && _page > 1 ? _page - 1 : _page;
    await _load(page: targetPage);
  }

  Future<void> _deleteBook(Map<String, dynamic> book) async {
    final id = apiText(book['bib_id'], fallback: '');
    if (id.isEmpty || _deletingIds.contains(id)) return;
    final title = apiText(book['title']);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa sách?'),
        content: Text(
          'Bạn có chắc muốn xóa “$title”?\n\n'
          'Các bản sao của đầu sách này cũng sẽ bị xóa. Sách đang được mượn sẽ không thể xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: kLibRed),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingIds.add(id));
    try {
      await ApiClient.delete('/books/$id');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã xóa sách “$title”.')));
      await _reloadAfterDelete();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _deletingIds.remove(id));
    }
  }

  Future<void> _chooseBookToDelete() async {
    if (_books.isEmpty || _deletingIds.isNotEmpty) return;
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      showDragHandle: true,
      backgroundColor: kLibCardFill,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: 430,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Text(
                  'Chọn sách cần xóa',
                  style: TextStyle(
                    color: kLibBrownTitle,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: _books.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final book = _books[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.menu_book_rounded,
                        color: kLibBrownTitle,
                      ),
                      title: Text(
                        apiText(book['title']),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text('ISBN: ${apiText(book['isbn'])}'),
                      trailing: const Icon(
                        Icons.delete_outline,
                        color: kLibRed,
                      ),
                      onTap: () => Navigator.pop(sheetContext, book),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) await _deleteBook(selected);
  }

  Future<void> _openFilters() async {
    final subjectController = TextEditingController(text: _subject);
    var copyStatus = _copyStatus;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: kLibCardFill,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            22,
            4,
            22,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Lọc danh sách sách',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kLibBrownTitle,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: subjectController,
                textInputAction: TextInputAction.next,
                decoration: _filterDecoration(
                  label: 'Thể loại / chủ đề',
                  hint: 'Ví dụ: Công nghệ, Giáo dục...',
                  icon: Icons.category_outlined,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: copyStatus,
                decoration: _filterDecoration(
                  label: 'Tình trạng sách',
                  icon: Icons.inventory_2_outlined,
                ),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Tất cả')),
                  DropdownMenuItem(value: 'available', child: Text('Còn sách')),
                  DropdownMenuItem(value: 'borrowed', child: Text('Đang mượn')),
                  DropdownMenuItem(
                    value: 'unavailable',
                    child: Text('Hết sách'),
                  ),
                ],
                onChanged: (value) =>
                    setSheetState(() => copyStatus = value ?? ''),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        subjectController.clear();
                        setSheetState(() => copyStatus = '');
                      },
                      child: const Text('Đặt lại'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: kLibBrownTitle,
                      ),
                      onPressed: () => Navigator.pop(sheetContext, true),
                      icon: const Icon(Icons.filter_alt_rounded),
                      label: const Text('Áp dụng'),
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
        _subject = subjectController.text.trim();
        _copyStatus = copyStatus;
      });
      await _load(page: 1);
    }
    subjectController.dispose();
  }

  Future<void> _removeSubjectFilter() async {
    setState(() => _subject = '');
    await _load(page: 1);
  }

  Future<void> _removeStatusFilter() async {
    setState(() => _copyStatus = '');
    await _load(page: 1);
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
                      onSubmitted: (_) => _load(page: 1),
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
                    onPressed: _loading ? null : () => _load(),
                    icon: const Icon(Icons.refresh, color: kLibBrownTitle),
                  ),
                  Badge(
                    isLabelVisible: _hasFilters,
                    backgroundColor: kLibRed,
                    child: IconButton.filledTonal(
                      tooltip: 'Lọc sách',
                      onPressed: _loading ? null : _openFilters,
                      icon: const Icon(
                        Icons.tune_rounded,
                        color: kLibBrownTitle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_hasFilters)
              SizedBox(
                height: 43,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(11, 0, 11, 7),
                  children: [
                    if (_subject.isNotEmpty)
                      InputChip(
                        avatar: const Icon(Icons.category_outlined, size: 18),
                        label: Text('Thể loại: $_subject'),
                        onDeleted: _loading ? null : _removeSubjectFilter,
                      ),
                    if (_subject.isNotEmpty && _copyStatus.isNotEmpty)
                      const SizedBox(width: 8),
                    if (_copyStatus.isNotEmpty)
                      InputChip(
                        avatar: const Icon(
                          Icons.inventory_2_outlined,
                          size: 18,
                        ),
                        label: Text(_copyStatusLabel(_copyStatus)),
                        onDeleted: _loading ? null : _removeStatusFilter,
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 0, 11, 8),
              child: Row(
                children: [
                  if (_error == null)
                    Expanded(
                      child: LibrarianPaginationBar(
                        margin: EdgeInsets.zero,
                        page: _page,
                        totalPages: _totalPages,
                        totalItems: _totalItems,
                        pageSize: _pageSize,
                        onPrevious: !_loading && _page > 1
                            ? () => _load(page: _page - 1)
                            : null,
                        onNext: !_loading && _page < _totalPages
                            ? () => _load(page: _page + 1)
                            : null,
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Xóa sách',
                    style: IconButton.styleFrom(backgroundColor: kLibRed),
                    onPressed: _books.isEmpty || _deletingIds.isNotEmpty
                        ? null
                        : _chooseBookToDelete,
                    icon: _deletingIds.isNotEmpty
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.delete_outline),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Thêm sách',
                    style: IconButton.styleFrom(
                      backgroundColor: kLibBeigeButton,
                    ),
                    onPressed: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => const FormAddBook()),
                      );
                      if (changed == true) _load(page: 1);
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const _BookHeader(),
            Expanded(
              child: ApiStateView(
                loading: _loading,
                error: _error,
                isEmpty: _books.isEmpty,
                onRetry: _load,
                emptyMessage: _hasFilters
                    ? 'Không có sách phù hợp bộ lọc'
                    : 'Chưa có sách trong hệ thống',
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(11, 6, 11, 8),
                    itemCount: _books.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _BookRow(
                      book: _books[i],
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailBook(
                              bookId: apiText(
                                _books[i]['bib_id'],
                                fallback: '',
                              ),
                            ),
                          ),
                        );
                        _load();
                      },
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
    final borrowed = int.tryParse('${book['borrowed_copies'] ?? 0}') ?? 0;
    final total = int.tryParse('${book['total_copies'] ?? 0}') ?? 0;
    final statusLabel = available > 0
        ? 'Còn'
        : borrowed > 0
        ? 'Đang mượn'
        : 'Hết';
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
                      : borrowed > 0
                      ? const Color(0xFFFFE0B2)
                      : const Color(0xFFFFCDD2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusLabel,
                  textAlign: TextAlign.center,
                  style: style,
                ),
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

InputDecoration _filterDecoration({
  required String label,
  required IconData icon,
  String? hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: kLibBrownTitle),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
}

String _copyStatusLabel(String status) => switch (status) {
  'available' => 'Tình trạng: Còn sách',
  'borrowed' => 'Tình trạng: Đang mượn',
  'unavailable' => 'Tình trạng: Hết sách',
  _ => 'Tình trạng: Tất cả',
};
