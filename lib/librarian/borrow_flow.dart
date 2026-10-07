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
          _step = 1;
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
      if (!_conditionsPassed) {
        _show('Có điều kiện chưa đạt, không thể tiếp tục.');
        return;
      }
      setState(() => _step = 2);
      return;
    }
    if (_step == 2) {
      if (_dueDays < 1) {
        _show('Hạn trả phải sau ngày mượn.');
        return;
      }
      setState(() => _step = 3);
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
        const _BorrowHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Column(
                        children: [
                          _FlowProgress(
                            currentStep: _step,
                            onStepTapped: (value) {
                              if (value <= _step) {
                                setState(() => _step = value);
                              }
                            },
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
                            color: kLibCardFill,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              layoutBuilder: (currentChild, previousChildren) =>
                                  Stack(
                                    alignment: Alignment.topLeft,
                                    children: [
                                      ...previousChildren,
                                      if (currentChild != null) currentChild,
                                    ],
                                  ),
                              child: KeyedSubtree(
                                key: ValueKey(_step),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      _stepTitle,
                                      style: const TextStyle(
                                        color: kLibBrownTitle,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    _stepContent(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    _actionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  String get _stepTitle => switch (_step) {
    0 => 'Nhập mã độc giả',
    1 => 'Quét / nhập barcode sách',
    2 => 'Ngày mượn / hạn trả',
    _ => 'Xác nhận thông tin',
  };

  Widget _stepContent() => switch (_step) {
    0 => _readerStep(),
    1 => _bookStep(),
    2 => _dateStep(),
    _ => _confirmationStep(),
  };

  Widget _actionButtons() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (_step > 0) ...[
        SizedBox(
          width: 126,
          height: 54,
          child: OutlinedButton(
            onPressed: _submitting ? null : () => setState(() => _step--),
            style: OutlinedButton.styleFrom(
              foregroundColor: kLibBrownTitle,
              side: const BorderSide(color: kLibBeigeButton, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Quay lại',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
      SizedBox(
        width: _step == 3 ? 202 : 146,
        height: 54,
        child: ElevatedButton(
          onPressed: _submitting ? null : _continue,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: kLibGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: kLibGreen.withValues(alpha: .55),
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
                  _step == 3 ? 'Xác nhận lập phiếu' : 'Tiếp theo',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    ],
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
              decoration: InputDecoration(
                hintText: 'Nhập mã độc giả, ví dụ LIB-2026-00001',
                hintStyle: TextStyle(
                  color: kLibBrownTitle.withValues(alpha: .42),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 17,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(
                    color: Color(0xFFD9D9D9),
                    width: 3,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(
                    color: kLibBeigeButton,
                    width: 3,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 58,
            height: 58,
            child: IconButton.filled(
              tooltip: 'Tra cứu độc giả',
              onPressed: _lookingUpReader ? null : _lookupReader,
              style: IconButton.styleFrom(
                backgroundColor: kLibBeigeSoft,
                foregroundColor: kLibBrownTitle,
              ),
              icon: _lookingUpReader
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: kLibBrownTitle,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.search_rounded, size: 32),
            ),
          ),
        ],
      ),
      if (_reader != null) ...[
        const SizedBox(height: 24),
        const _SectionHeading('Thông tin độc giả'),
        const SizedBox(height: 14),
        _InfoCard(
          children: [
            _InfoLine('Họ và tên', _reader?['full_name']),
            _InfoLine('Mã độc giả', _reader?['reader_code']),
            _InfoLine('Ngày sinh', apiDate(_reader?['birth_date'])),
            _InfoLine('Số điện thoại', _reader?['phone']),
            _InfoLine('Địa chỉ', _reader?['address']),
            _InfoLine('Email', _reader?['email']),
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
              decoration: InputDecoration(
                hintText: 'Nhập barcode dán trên bản sao sách',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: Color(0xFFD9D9D9),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: kLibBeigeButton,
                    width: 2,
                  ),
                ),
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
      const SizedBox(height: 20),
      const _SectionHeading('Kiểm tra điều kiện'),
      const SizedBox(height: 12),
      _conditionStep(),
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

class _BorrowHeader extends StatelessWidget {
  const _BorrowHeader();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
    decoration: const BoxDecoration(
      color: kLibBeige,
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
    ),
    child: SafeArea(
      bottom: false,
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
              'Lập phiếu mượn',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kLibBrownTitle,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    ),
  );
}

class _FlowProgress extends StatelessWidget {
  const _FlowProgress({required this.currentStep, required this.onStepTapped});

  final int currentStep;
  final ValueChanged<int> onStepTapped;

  static const _labels = [
    'Nhập mã\nđộc giả',
    'Sách',
    'Ngày mượn\n/ trả',
    'Xác nhận\nthông tin',
  ];

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(12, 16, 12, 15),
    color: kLibBeigeButton,
    child: LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              _labels.length,
              (index) => Expanded(
                child: InkWell(
                  onTap: index <= currentStep
                      ? () => onStepTapped(index)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(
                      _labels[index],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        color: index <= currentStep
                            ? Colors.white
                            : Colors.white.withValues(alpha: .78),
                        fontSize: 13,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 30,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: constraints.maxWidth / (_labels.length * 2),
                  right: constraints.maxWidth / (_labels.length * 2),
                  child: Container(
                    height: 2,
                    color: kLibBrownTitle.withValues(alpha: .28),
                  ),
                ),
                Row(
                  children: List.generate(
                    _labels.length,
                    (index) => Expanded(
                      child: Center(
                        child: InkWell(
                          onTap: index <= currentStep
                              ? () => onStepTapped(index)
                              : null,
                          customBorder: const CircleBorder(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index < currentStep
                                  ? kLibGreen
                                  : index == currentStep
                                  ? Colors.white
                                  : kLibBeigeSoft,
                              border: index == currentStep
                                  ? Border.all(color: kLibBrownTitle, width: 2)
                                  : null,
                            ),
                            child: index < currentStep
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 19,
                                  )
                                : index == currentStep
                                ? const Icon(
                                    Icons.circle,
                                    color: kLibBrownTitle,
                                    size: 11,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: kLibBrownTitle,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      Container(
        width: 150,
        height: 1,
        margin: const EdgeInsets.only(top: 8),
        color: kLibBrownTitle.withValues(alpha: .45),
      ),
    ],
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: kLibBeigeSoft),
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
