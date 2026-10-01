import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';

import 'librarian_nav.dart';
import 'librarian_scanner.dart';

class BorrowFlow extends StatefulWidget {
  const BorrowFlow({super.key, this.initialReaderCode, this.initialBarcode});

  final String? initialReaderCode;
  final String? initialBarcode;

  @override
  State<BorrowFlow> createState() => _BorrowFlowState();
}

class _BorrowFlowState extends State<BorrowFlow> {
  late final TextEditingController _readerCode = TextEditingController(
    text: widget.initialReaderCode ?? '',
  );
  late final TextEditingController _barcode = TextEditingController(
    text: widget.initialBarcode ?? '',
  );
  final _note = TextEditingController();

  Map<String, dynamic>? _reader;
  List<Map<String, dynamic>> _copies = [];
  int _activeLoans = 0;
  int _step = 0;
  bool _lookingUpReader = false;
  bool _lookingUpBook = false;
  bool _submitting = false;
  final DateTime _borrowDate = _today();
  DateTime _dueDate = _today().add(const Duration(days: 14));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_readerCode.text.trim().isNotEmpty) await _lookupReader();
    });
  }

  @override
  void dispose() {
    _readerCode.dispose();
    _barcode.dispose();
    _note.dispose();
    super.dispose();
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  int get _maxBooks => int.tryParse('${_reader?['max_books'] ?? 5}') ?? 5;

  DateTime? get _cardExpired =>
      DateTime.tryParse(_reader?['card_expired']?.toString() ?? '');

  bool get _cardActive {
    if (_reader == null || _reader?['status']?.toString() != 'active') {
      return false;
    }
    final expired = _cardExpired;
    return expired == null ||
        !DateTime(
          expired.year,
          expired.month,
          expired.day,
        ).isBefore(_borrowDate);
  }

  bool get _withinLimit => _activeLoans + _copies.length <= _maxBooks;

  bool get _allCopiesAvailable =>
      _copies.every((copy) => copy['status']?.toString() == 'available');

  bool get _conditionsPassed =>
      _reader != null &&
      _copies.isNotEmpty &&
      _cardActive &&
      _withinLimit &&
      _allCopiesAvailable;

  int get _dueDays => _dueDate.difference(_borrowDate).inDays;

  Future<void> _lookupReader() async {
    final code = _readerCode.text.trim();
    if (code.isEmpty) {
      _show('Vui lòng nhập mã độc giả.');
      return;
    }
    setState(() => _lookingUpReader = true);
    try {
      final result = apiMap(
        await ApiClient.get('/readers', query: {'keyword': code, 'limit': 100}),
      );
      final readers = apiList(result['items']);
      Map<String, dynamic>? matched;
      for (final item in readers) {
        if (item['reader_code']?.toString().toLowerCase() ==
            code.toLowerCase()) {
          matched = item;
          break;
        }
      }
      if (matched == null) {
        throw const ApiException('Không tìm thấy mã độc giả này.');
      }
      final detail = apiMap(
        await ApiClient.get('/readers/${matched['reader_id']}'),
      );
      final loans = apiMap(
        await ApiClient.get(
          '/circulation/active',
          query: {'reader_id': matched['reader_id'], 'limit': 100},
        ),
      );
      if (!mounted) return;
      final readerChanged =
          _reader?['reader_id']?.toString() != detail['reader_id']?.toString();
      setState(() {
        _reader = detail;
        _activeLoans = apiList(loans['data']).length;
        if (readerChanged) _copies.clear();
        _step = 0;
      });
      if (_barcode.text.trim().isNotEmpty && _copies.isEmpty) {
        await _addBarcode();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _reader = null;
          _activeLoans = 0;
        });
        _show(error.toString());
      }
    } finally {
      if (mounted) setState(() => _lookingUpReader = false);
    }
  }

  Future<void> _scanBarcode() async {
    final value = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const LibrarianScanner(
          returnRawCode: true,
          title: 'Quét barcode bản sao',
          instruction: 'Đưa mã vạch dán trên bản sao sách vào khung',
        ),
      ),
    );
    if (value == null || !mounted) return;
    _barcode.text = value;
    await _addBarcode();
  }

  Future<void> _addBarcode() async {
    final code = _barcode.text.trim();
    if (_reader == null) {
      _show('Hãy xác nhận độc giả trước khi thêm sách.');
      return;
    }
    if (code.isEmpty) {
      _show('Vui lòng nhập hoặc quét barcode bản sao.');
      return;
    }
    if (_copies.any(
      (copy) => copy['barcode']?.toString().toLowerCase() == code.toLowerCase(),
    )) {
      _show('Bản sao này đã có trong phiếu.');
      return;
    }
    if (_activeLoans + _copies.length >= _maxBooks) {
      _show('Độc giả đã đạt giới hạn $_maxBooks cuốn.');
      return;
    }

    setState(() => _lookingUpBook = true);
    try {
      final result = apiMap(
        await ApiClient.get('/books/scan/${Uri.encodeComponent(code)}'),
      );
      if (result['scan_type']?.toString() != 'copy') {
        throw const ApiException(
          'Mã này là ISBN đầu sách. Vui lòng quét barcode của bản sao.',
        );
      }
      final copy = apiMap(result['copy']);
      final book = apiMap(result['book']);
      if (copy['status']?.toString() != 'available') {
        throw ApiException(
          'Bản sao ${apiText(copy['barcode'])} không thể cho mượn '
          '(trạng thái: ${_statusText(copy['status'])}).',
        );
      }
      if (!mounted) return;
      setState(() {
        _copies.add({...copy, 'book_title': book['title']});
        _barcode.clear();
      });
    } catch (error) {
      if (mounted) _show(error.toString());
    } finally {
      if (mounted) setState(() => _lookingUpBook = false);
    }
  }

  Future<void> _selectDueDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: _borrowDate.add(const Duration(days: 1)),
      lastDate: _borrowDate.add(const Duration(days: 365)),
      helpText: 'Chọn hạn trả',
    );
    if (selected != null && mounted) setState(() => _dueDate = selected);
  }

  Future<void> _submit() async {
    if (!_conditionsPassed || _submitting) {
      _show('Phiếu mượn chưa đáp ứng đủ điều kiện.');
      return;
    }
    setState(() => _submitting = true);
    var completed = 0;
    try {
      for (final copy in List<Map<String, dynamic>>.from(_copies)) {
        await ApiClient.post(
          '/circulation/borrow',
          body: {
            'reader_code': _reader?['reader_code'],
            'copy_id': copy['copy_id'],
            'due_days': _dueDays,
          },
        );
        completed++;
      }
      if (!mounted) return;
      _show('Đã lập phiếu mượn cho $completed cuốn sách.');
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      if (completed > 0) {
        setState(() {
          _copies = _copies.skip(completed).toList();
          _activeLoans += completed;
          _step = 2;
        });
        _show(
          'Đã cho mượn $completed cuốn; các cuốn còn lại chưa được xử lý: $error',
        );
      } else {
        _show(error.toString());
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _continue() {
    if (_step == 0) {
      if (_reader == null) {
        _lookupReader();
        return;
      }
      if (!_cardActive) {
        _show('Thẻ độc giả không hoạt động hoặc đã hết hạn.');
        return;
      }
      if (_activeLoans >= _maxBooks) {
        _show('Độc giả đã đạt giới hạn $_maxBooks cuốn.');
        return;
      }
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      if (_copies.isEmpty) {
        _show('Hãy thêm ít nhất một bản sao sách.');
        return;
      }
      setState(() => _step = 2);
      return;
    }
    if (_step == 2) {
      if (!_conditionsPassed) {
        _show('Có điều kiện chưa đạt, không thể tiếp tục.');
        return;
      }
      setState(() => _step = 3);
      return;
    }
    if (_step == 3) {
      if (_dueDays < 1) {
        _show('Hạn trả phải sau ngày mượn.');
        return;
      }
      setState(() => _step = 4);
      return;
    }
    _submit();
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        const LibTitleHeader(title: 'Lập phiếu mượn', showBack: true),
        Expanded(
          child: Stepper(
            currentStep: _step,
            onStepTapped: (value) {
              if (value <= _step) setState(() => _step = value);
            },
            controlsBuilder: (context, details) => Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _continue,
                      style: FilledButton.styleFrom(
                        backgroundColor: _step == 4
                            ? kLibGreen
                            : kLibBrownTitle,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: _submitting
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _step == 4
                                  ? Icons.check_circle_outline
                                  : Icons.arrow_forward,
                            ),
                      label: Text(
                        _step == 4 ? 'Xác nhận lập phiếu' : 'Tiếp tục',
                      ),
                    ),
                  ),
                  if (_step > 0 && _step < 4) ...[
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('Quay lại'),
                    ),
                  ],
                ],
              ),
            ),
            steps: [
              Step(
                title: const Text('Nhập mã độc giả'),
                subtitle: const Text('Xác nhận thông tin và trạng thái thẻ'),
                isActive: _step >= 0,
                state: _reader == null
                    ? StepState.indexed
                    : _cardActive && _activeLoans < _maxBooks
                    ? StepState.complete
                    : StepState.error,
                content: _readerStep(),
              ),
              Step(
                title: const Text('Quét / nhập barcode sách'),
                subtitle: Text('${_copies.length} bản sao trong phiếu'),
                isActive: _step >= 1,
                state: _copies.isEmpty ? StepState.indexed : StepState.complete,
                content: _bookStep(),
              ),
              Step(
                title: const Text('Kiểm tra điều kiện'),
                subtitle: Text(
                  _conditionsPassed ? 'Đủ điều kiện cho mượn' : 'Cần xử lý',
                ),
                isActive: _step >= 2,
                state: _conditionsPassed ? StepState.complete : StepState.error,
                content: _conditionStep(),
              ),
              Step(
                title: const Text('Ngày mượn / hạn trả'),
                subtitle: Text('Thời hạn $_dueDays ngày'),
                isActive: _step >= 3,
                state: _step > 3 ? StepState.complete : StepState.indexed,
                content: _dateStep(),
              ),
              Step(
                title: const Text('Xác nhận lập phiếu'),
                subtitle: const Text('Kiểm tra lần cuối trước khi ghi nhận'),
                isActive: _step >= 4,
                content: _confirmationStep(),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _readerStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _readerCode,
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {
                if (_reader == null ||
                    value.trim().toLowerCase() ==
                        _reader?['reader_code']?.toString().toLowerCase()) {
                  return;
                }
                setState(() {
                  _reader = null;
                  _activeLoans = 0;
                  _copies.clear();
                  _step = 0;
                });
              },
              onSubmitted: (_) => _lookupReader(),
              decoration: const InputDecoration(
                labelText: 'Mã độc giả',
                hintText: 'Ví dụ: RD-123456',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            tooltip: 'Tra cứu độc giả',
            onPressed: _lookingUpReader ? null : _lookupReader,
            icon: _lookingUpReader
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.search),
          ),
        ],
      ),
      if (_reader != null) ...[
        const SizedBox(height: 14),
        _InfoCard(
          children: [
            _InfoLine('Họ và tên', _reader?['full_name']),
            _InfoLine('Mã độc giả', _reader?['reader_code']),
            _InfoLine('Đang mượn', '$_activeLoans / $_maxBooks'),
            _InfoLine(
              'Trạng thái thẻ',
              _cardActive ? 'Còn hiệu lực' : 'Không hợp lệ / đã hết hạn',
              good: _cardActive,
            ),
            _InfoLine('Hạn thẻ', apiDate(_reader?['card_expired'])),
          ],
        ),
      ],
    ],
  );

  Widget _bookStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _barcode,
              onSubmitted: (_) => _addBarcode(),
              decoration: const InputDecoration(
                labelText: 'Barcode bản sao',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Thêm barcode',
            onPressed: _lookingUpBook ? null : _addBarcode,
            icon: _lookingUpBook
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.add),
          ),
          const SizedBox(width: 6),
          IconButton.filled(
            tooltip: 'Quét barcode',
            onPressed: _lookingUpBook ? null : _scanBarcode,
            style: IconButton.styleFrom(backgroundColor: kLibBeigeButton),
            icon: const Icon(Icons.qr_code_scanner),
          ),
        ],
      ),
      const SizedBox(height: 12),
      ..._copies.map(
        (copy) => Card(
          color: kLibCardFill,
          elevation: 0,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: kLibGreen,
              child: Icon(Icons.menu_book, color: Colors.white),
            ),
            title: Text(
              apiText(copy['book_title']),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${apiText(copy['barcode'])} • '
              '${_conditionText(copy['condition'])} • Có sẵn',
            ),
            trailing: IconButton(
              tooltip: 'Bỏ khỏi phiếu',
              onPressed: () => setState(() => _copies.remove(copy)),
              icon: const Icon(Icons.close, color: kLibRed),
            ),
          ),
        ),
      ),
      if (_copies.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Có thể thêm ${_maxBooks - _activeLoans - _copies.length} cuốn nữa.',
            style: const TextStyle(color: kLibBrownTitle),
          ),
        ),
    ],
  );

  Widget _conditionStep() => _InfoCard(
    children: [
      _CheckLine(
        label: 'Thẻ độc giả đang hoạt động và còn hạn',
        passed: _cardActive,
      ),
      _CheckLine(
        label: 'Số sách sau khi mượn không vượt quá $_maxBooks',
        passed: _withinLimit,
      ),
      _CheckLine(
        label: 'Đã chọn ít nhất một bản sao',
        passed: _copies.isNotEmpty,
      ),
      _CheckLine(
        label: 'Tất cả bản sao có trạng thái available',
        passed: _allCopiesAvailable && _copies.isNotEmpty,
      ),
    ],
  );

  Widget _dateStep() => Column(
    children: [
      _DateTile(
        label: 'Ngày mượn',
        value: _formatDate(_borrowDate),
        icon: Icons.lock_outline,
      ),
      const SizedBox(height: 10),
      _DateTile(
        label: 'Hạn trả',
        value: _formatDate(_dueDate),
        icon: Icons.calendar_month,
        onTap: _selectDueDate,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _note,
        minLines: 2,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Ghi chú (không bắt buộc)',
          helperText: 'Ghi chú chỉ dùng trong bước xác nhận hiện tại.',
          border: OutlineInputBorder(),
        ),
      ),
    ],
  );

  Widget _confirmationStep() => _InfoCard(
    children: [
      _InfoLine('Độc giả', _reader?['full_name']),
      _InfoLine('Mã độc giả', _reader?['reader_code']),
      _InfoLine('Số sách', _copies.length),
      ..._copies.map(
        (copy) => _InfoLine(apiText(copy['barcode']), copy['book_title']),
      ),
      _InfoLine('Ngày mượn', _formatDate(_borrowDate)),
      _InfoLine('Hạn trả', _formatDate(_dueDate)),
      if (_note.text.trim().isNotEmpty) _InfoLine('Ghi chú', _note.text.trim()),
    ],
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: kLibCardFill,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(children: children),
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value, {this.good});
  final String label;
  final dynamic value;
  final bool? good;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 115,
          child: Text(
            label,
            style: const TextStyle(
              color: kLibBrownTitle,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            apiText(value),
            style: TextStyle(
              color: good == null
                  ? kLibBookTitle
                  : good!
                  ? const Color(0xFF3D8A63)
                  : kLibRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CheckLine extends StatelessWidget {
  const _CheckLine({required this.label, required this.passed});
  final String label;
  final bool passed;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    leading: Icon(
      passed ? Icons.check_circle : Icons.cancel,
      color: passed ? kLibGreen : kLibRed,
    ),
    title: Text(label),
  );
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    tileColor: kLibCardFill,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    leading: Icon(icon, color: kLibBrownTitle),
    title: Text(label),
    subtitle: Text(value),
    trailing: onTap == null
        ? null
        : const Icon(Icons.chevron_right, color: kLibBrownTitle),
  );
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

String _statusText(dynamic value) => switch (value?.toString()) {
  'available' => 'Có sẵn',
  'borrowed' => 'Đang được mượn',
  'reserved' => 'Đang được giữ trước',
  'lost' => 'Đã báo mất',
  'processing' => 'Đang xử lý',
  _ => apiText(value),
};

String _conditionText(dynamic value) => switch (value?.toString()) {
  'new' => 'Mới',
  'good' => 'Tốt',
  'fair' => 'Khá',
  'poor' => 'Kém',
  'damaged' => 'Hư hỏng',
  _ => apiText(value),
};
