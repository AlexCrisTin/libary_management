import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/core/local_image.dart';

import 'librarian_nav.dart';
import 'librarian_scanner.dart';
import 'librarian_shell.dart';
import 'borrow_flow.dart';

class DetailBook extends StatefulWidget {
  const DetailBook({super.key, required this.bookId});

  final String bookId;

  @override
  State<DetailBook> createState() => _DetailBookState();
}

class _DetailBookState extends State<DetailBook> {
  Map<String, dynamic> _book = const {};
  List<Map<String, dynamic>> _shelves = const [];
  bool _loading = true;
  bool _loadingShelves = true;
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
    _loadShelves();
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

  Future<void> _loadShelves() async {
    if (mounted) setState(() => _loadingShelves = true);
    try {
      final data = await ApiClient.get('/shelves');
      if (mounted) setState(() => _shelves = apiList(data));
    } catch (error) {
      if (mounted) _showMessage('Không tải được danh sách kệ: $error');
    } finally {
      if (mounted) setState(() => _loadingShelves = false);
    }
  }

  Future<void> _refresh() async {
    await Future.wait([_load(), _loadShelves()]);
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

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BorrowFlow(
          initialBarcode: apiText(available.first['barcode'], fallback: ''),
        ),
      ),
    );
    if (changed == true && mounted) await _load();
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

  Future<void> _addCopy() async {
    final barcode = TextEditingController();
    final price = TextEditingController();
    var condition = 'good';
    var locationId = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm bản sao sách'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: barcode,
                  decoration: const InputDecoration(
                    labelText: 'Mã barcode (để trống sẽ tự tạo)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: condition,
                  decoration: const InputDecoration(
                    labelText: 'Tình trạng',
                    border: OutlineInputBorder(),
                  ),
                  items: _copyConditions
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_copyConditionLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => condition = value ?? condition),
                ),
                const SizedBox(height: 12),
                _shelfDropdown(
                  value: locationId,
                  onChanged: (value) =>
                      setDialogState(() => locationId = value ?? locationId),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Giá nhập',
                    suffixText: 'đ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _submitting = true);
      try {
        await ApiClient.post(
          '/books/${widget.bookId}/copies',
          body: {
            'barcode': _nullable(barcode.text),
            'condition': condition,
            'location_id': locationId.isEmpty ? null : locationId,
            'acquired_price': num.tryParse(price.text) ?? 0,
          },
        );
        _showMessage('Đã thêm bản sao sách.');
        await _load();
      } catch (error) {
        _showMessage(error.toString());
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
    }
    barcode.dispose();
    price.dispose();
  }

  Future<void> _editCopy(Map<String, dynamic> copy) async {
    var condition = apiText(copy['condition'], fallback: 'good');
    var status = apiText(copy['status'], fallback: 'available');
    final currentLocationId = apiText(copy['location_id'], fallback: '');
    var locationId =
        _shelves.any(
          (shelf) =>
              apiText(shelf['location_id'], fallback: '') == currentLocationId,
        )
        ? currentLocationId
        : '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(apiText(copy['barcode'])),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: condition,
                  decoration: const InputDecoration(
                    labelText: 'Tình trạng vật lý',
                    border: OutlineInputBorder(),
                  ),
                  items: _copyConditions
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_copyConditionLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => condition = value ?? condition),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái lưu thông',
                    border: OutlineInputBorder(),
                  ),
                  items: _copyStatuses
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_copyStatusLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => status = value ?? status),
                ),
                const SizedBox(height: 12),
                _shelfDropdown(
                  value: locationId,
                  onChanged: (value) =>
                      setDialogState(() => locationId = value ?? locationId),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _submitting = true);
    try {
      await ApiClient.put(
        '/books/copies/${copy['copy_id']}',
        body: {'condition': condition, 'status': status},
      );
      if (locationId != currentLocationId) {
        await ApiClient.put(
          '/shelves/assign-book',
          body: {
            'copy_id': copy['copy_id'],
            'location_id': locationId.isEmpty ? null : locationId,
          },
        );
      }
      _showMessage('Đã cập nhật bản sao sách.');
      await _load();
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
                onRefresh: _refresh,
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
                    const SizedBox(height: 18),
                    _CopiesCard(
                      copies: _copies,
                      onAdd: _addCopy,
                      onEdit: _editCopy,
                      busy: _submitting,
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

  Widget _shelfDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Vị trí kệ',
        border: const OutlineInputBorder(),
        helperText: _loadingShelves
            ? 'Đang tải danh sách kệ...'
            : 'Có thể chọn “Chưa xếp kệ” để gỡ khỏi kệ hiện tại',
      ),
      items: [
        const DropdownMenuItem(value: '', child: Text('Chưa xếp kệ')),
        ..._shelves.map(
          (shelf) => DropdownMenuItem(
            value: apiText(shelf['location_id'], fallback: ''),
            enabled: shelf['is_full'] != true,
            child: Text(
              _shelfLabel(shelf, showCapacity: true),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: _loadingShelves ? null : onChanged,
    );
  }
}

const _copyConditions = ['new', 'good', 'fair', 'poor', 'damaged'];
const _copyStatuses = [
  'available',
  'borrowed',
  'reserved',
  'lost',
  'processing',
];

String _copyConditionLabel(String value) => switch (value) {
  'new' => 'Mới',
  'good' => 'Tốt',
  'fair' => 'Khá',
  'poor' => 'Kém',
  'damaged' => 'Hư hỏng',
  _ => value,
};

String _copyStatusLabel(String value) => switch (value) {
  'available' => 'Có sẵn',
  'borrowed' => 'Đang mượn',
  'reserved' => 'Đã giữ chỗ',
  'lost' => 'Thất lạc',
  'processing' => 'Đang xử lý',
  _ => value,
};

Color _copyStatusColor(String value) => switch (value) {
  'available' => kLibGreen,
  'borrowed' => kLibBeige,
  'reserved' => const Color(0xFFE1B76B),
  'lost' => kLibRed,
  'processing' => kLibBrownTitle,
  _ => kLibBrownTitle,
};

String _locationPart(String label, dynamic value) {
  final text = apiText(value, fallback: '').trim();
  if (text.isEmpty) return '';
  if (text.toLowerCase().startsWith(label.toLowerCase())) return text;
  return '$label $text';
}

String _shelfLabel(Map<String, dynamic> shelf, {bool showCapacity = false}) {
  final location = <String>[
    _locationPart('Tầng', shelf['floor']),
    _locationPart('Khu', shelf['section']),
    _locationPart('Kệ', shelf['shelf']),
    _locationPart('Ngăn', shelf['position']),
  ].where((part) => part.isNotEmpty).join(' • ');
  if (!showCapacity) return location.isEmpty ? 'Chưa xếp kệ' : location;

  final remaining = int.tryParse('${shelf['remaining_capacity'] ?? ''}');
  final capacity = int.tryParse('${shelf['capacity'] ?? ''}');
  final capacityText = remaining == null || capacity == null
      ? ''
      : ' — còn $remaining/$capacity chỗ';
  return '${location.isEmpty ? 'Kệ chưa đặt tên' : location}$capacityText';
}

String _copyPrice(dynamic value) {
  final price = num.tryParse('$value');
  if (price == null || price <= 0) return 'Chưa cập nhật';
  final digits = price.round().toString();
  final result = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) result.write('.');
    result.write(digits[index]);
  }
  return '$resultđ';
}

class _CopiesCard extends StatelessWidget {
  const _CopiesCard({
    required this.copies,
    required this.onAdd,
    required this.onEdit,
    required this.busy,
  });

  final List<Map<String, dynamic>> copies;
  final VoidCallback onAdd;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final available = copies
        .where((copy) => copy['status']?.toString() == 'available')
        .length;
    final borrowed = copies
        .where((copy) => copy['status']?.toString() == 'borrowed')
        .length;
    final unavailable = copies.length - available - borrowed;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: kLibCardFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Quản lý từng bản sao',
                  style: TextStyle(
                    color: kLibBookTitle,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton.filled(
                tooltip: 'Thêm bản sao',
                onPressed: busy ? null : onAdd,
                style: IconButton.styleFrom(
                  backgroundColor: kLibBeigeButton,
                  disabledBackgroundColor: kLibBeigeSoft,
                ),
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CopySummaryChip(
                label: 'Tổng ${copies.length}',
                color: kLibBeige,
              ),
              _CopySummaryChip(label: 'Có sẵn $available', color: kLibGreen),
              _CopySummaryChip(
                label: 'Đang mượn $borrowed',
                color: kLibBeigeButton,
              ),
              if (unavailable > 0)
                _CopySummaryChip(label: 'Khác $unavailable', color: kLibRed),
            ],
          ),
          if (copies.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text('Đầu sách này chưa có bản sao vật lý.'),
              ),
            )
          else
            ...copies.map(
              (copy) => _CopyTile(
                copy: copy,
                enabled: !busy,
                onEdit: () => onEdit(copy),
              ),
            ),
        ],
      ),
    );
  }
}

class _CopySummaryChip extends StatelessWidget {
  const _CopySummaryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .35),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: kLibBookTitle,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _CopyTile extends StatelessWidget {
  const _CopyTile({
    required this.copy,
    required this.enabled,
    required this.onEdit,
  });

  final Map<String, dynamic> copy;
  final bool enabled;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final status = apiText(copy['status'], fallback: '');
    final condition = apiText(copy['condition'], fallback: '');
    final location = _shelfLabel(copy);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: kLibBeigeSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_rounded, color: kLibBrownTitle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      apiText(copy['barcode']),
                      style: const TextStyle(
                        color: kLibBookTitle,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Mã bản sao: ${apiText(copy['copy_id'])}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Cập nhật bản sao',
                onPressed: enabled ? onEdit : null,
                icon: const Icon(Icons.edit_outlined, color: kLibBrownTitle),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _CopySummaryChip(
                label: _copyStatusLabel(status),
                color: _copyStatusColor(status),
              ),
              _CopySummaryChip(
                label: 'Tình trạng: ${_copyConditionLabel(condition)}',
                color: kLibBeige,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: kLibBrownTitle,
                size: 19,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(
                    color: kLibBookTitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ngày nhập: ${apiDate(copy['acquired_date'])}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              Text(
                'Giá: ${_copyPrice(copy['acquired_price'])}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
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
