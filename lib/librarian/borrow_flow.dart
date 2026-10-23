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
  List<Map<String, dynamic>> _pickupReservations = [];
  int _activeLoans = 0;
  int _step = 0;
  bool _lookingUpReader = false;
  bool _lookingUpBook = false;
  bool _loadingPickupReservations = false;
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

  bool _isBorrowableCopy(Map<String, dynamic> copy) {
    final status = copy['status']?.toString();
    return status == 'available' ||
        (status == 'reserved' && copy['_pickup_slot'] == true);
  }

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
        if (readerChanged) {
          _copies.clear();
          _pickupReservations.clear();
        }
        _step = 0;
      });
      await _loadPickupReservations(
        apiText(detail['reader_id'], fallback: ''),
        apiText(detail['reader_code'], fallback: ''),
      );
      if (_barcode.text.trim().isNotEmpty && _copies.isEmpty) {
        await _addBarcode();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _reader = null;
          _activeLoans = 0;
          _pickupReservations.clear();
        });
        _show(error.toString());
      }
    } finally {
      if (mounted) setState(() => _lookingUpReader = false);
    }
  }

  Future<void> _loadPickupReservations(
    String readerId,
    String readerCode,
  ) async {
    if (readerId.isEmpty) return;
    setState(() => _loadingPickupReservations = true);
    try {
      final result = apiMap(
        await ApiClient.get(
          '/pickup-reservations',
          query: {
            'status': 'active',
            'reader_id': readerId,
            if (readerCode.isNotEmpty) 'keyword': readerCode,
            'limit': 100,
          },
        ),
      );
      if (mounted) {
        final reservations = apiList(
          result['data'],
        ).where((slot) => slot['reader_id']?.toString() == readerId).toList();
        setState(() {
          _pickupReservations = reservations;

          // Slot đã được duyệt luôn đi kèm đúng một bản sao đang được giữ.
          // Đưa sẵn bản sao vào phiếu để thủ thư không phải quét lại barcode.
          var remaining = _maxBooks - _activeLoans - _copies.length;
          if (remaining <= 0) return;
          final selectedCopyIds = _copies
              .map((copy) => apiText(copy['copy_id'], fallback: ''))
              .where((id) => id.isNotEmpty)
              .toSet();
          for (final slot in reservations) {
            if (remaining <= 0 || slot['status']?.toString() != 'approved') {
              continue;
            }
            final copyId = apiText(slot['copy_id'], fallback: '');
            if (copyId.isEmpty || selectedCopyIds.contains(copyId)) continue;
            _copies.add(_pickupCopy(slot));
            selectedCopyIds.add(copyId);
            remaining--;
          }
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _pickupReservations = const []);
        _show('Không tải được sách đã đặt slot: $error');
      }
    } finally {
      if (mounted) setState(() => _loadingPickupReservations = false);
    }
  }

  Map<String, dynamic>? _approvedSlotForCopy(Map<String, dynamic> copy) {
    final copyId = apiText(copy['copy_id'], fallback: '');
    final barcode = apiText(copy['barcode'], fallback: '').toLowerCase();
    for (final slot in _pickupReservations) {
      if (slot['status']?.toString() != 'approved') continue;
      final sameId =
          copyId.isNotEmpty && apiText(slot['copy_id'], fallback: '') == copyId;
      final sameBarcode =
          barcode.isNotEmpty &&
          apiText(slot['barcode'], fallback: '').toLowerCase() == barcode;
      if (sameId || sameBarcode) return slot;
    }
    return null;
  }

  void _addPickupReservation(Map<String, dynamic> slot) {
    if (slot['status']?.toString() != 'approved') {
      _show('Yêu cầu đặt slot này chưa được thủ thư duyệt.');
      return;
    }
    final copyId = apiText(slot['copy_id'], fallback: '');
    if (copyId.isEmpty) {
      _show('Slot chưa được gán bản sao sách. Hãy tải lại và kiểm tra.');
      return;
    }
    if (_copies.any((copy) => copy['copy_id']?.toString() == copyId)) {
      _show('Sách đặt slot này đã có trong phiếu.');
      return;
    }
    if (_activeLoans + _copies.length >= _maxBooks) {
      _show('Độc giả đã đạt giới hạn $_maxBooks cuốn.');
      return;
    }
    setState(() {
      _copies.add(_pickupCopy(slot));
    });
  }

  Map<String, dynamic> _pickupCopy(Map<String, dynamic> slot) => {
    'copy_id': slot['copy_id'],
    'barcode': slot['barcode'],
    'status': 'reserved',
    'book_title': slot['book_title'],
    'reservation_id': slot['reservation_id'],
    '_pickup_slot': true,
  };

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
      final pickupSlot = _approvedSlotForCopy(copy);
      final status = copy['status']?.toString();
      if (status != 'available' &&
          !(status == 'reserved' && pickupSlot != null)) {
        throw ApiException(
          'Bản sao ${apiText(copy['barcode'])} không thể cho mượn '
          '(trạng thái: ${_statusText(copy['status'])}).',
        );
      }
      if (!mounted) return;
      setState(() {
        _copies.add({
          ...copy,
          'book_title': book['title'],
          if (pickupSlot != null) ...{
            'reservation_id': pickupSlot['reservation_id'],
            '_pickup_slot': true,
          },
        });
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
    final validationError = _validationError(requireCopies: true);
    if (validationError != null || _submitting) {
      if (validationError != null) _show(validationError);
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

  String? _validationError({required bool requireCopies}) {
    if (_reader == null) return 'Hãy tra cứu và xác nhận độc giả trước.';
    if (!_cardActive) return 'Thẻ độc giả không hoạt động hoặc đã hết hạn.';
    if (_activeLoans >= _maxBooks) {
      return 'Độc giả đã đạt giới hạn $_maxBooks cuốn.';
    }
    if (!requireCopies) return null;
    if (_copies.isEmpty) return 'Hãy thêm ít nhất một bản sao sách.';
    if (!_withinLimit) {
      return 'Số sách trong phiếu vượt quá giới hạn $_maxBooks cuốn.';
    }
    for (final copy in _copies) {
      if (!_isBorrowableCopy(copy)) {
        return 'Bản sao ${apiText(copy['barcode'])} không thể cho mượn '
            '(trạng thái: ${_statusText(copy['status'])}).';
      }
    }
    return null;
  }

  void _continue() {
    if (_step == 0) {
      if (_reader == null) {
        _lookupReader();
        return;
      }
      final error = _validationError(requireCopies: false);
      if (error != null) {
        _show(error);
        return;
      }
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      final error = _validationError(requireCopies: true);
      if (error != null) {
        _show(error);
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
                  _pickupReservations.clear();
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
      if (_loadingPickupReservations)
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: LinearProgressIndicator(),
        )
      else if (_pickupReservations.isNotEmpty) ...[
        const _SectionHeading('Sách độc giả đã đặt slot'),
        const SizedBox(height: 12),
        ..._pickupReservations.map((slot) {
          final approved = slot['status']?.toString() == 'approved';
          final copyId = apiText(slot['copy_id'], fallback: '');
          final selected =
              copyId.isNotEmpty &&
              _copies.any((copy) => copy['copy_id']?.toString() == copyId);
          return Card(
            color: Colors.white.withValues(alpha: .78),
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: approved ? kLibGreen : kLibBeigeButton,
                child: Icon(
                  approved
                      ? Icons.bookmark_added_rounded
                      : Icons.hourglass_top_rounded,
                  color: Colors.white,
                ),
              ),
              title: Text(
                apiText(slot['book_title']),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                approved
                    ? '${apiText(slot['barcode'])} • Giữ đến '
                          '${_formatDateTime(slot['pickup_expires_at'])}'
                    : apiText(slot['barcode'], fallback: '').isEmpty
                    ? 'Yêu cầu đang chờ thủ thư duyệt'
                    : '${apiText(slot['barcode'])} • Đang chờ duyệt',
              ),
              trailing: approved
                  ? FilledButton(
                      onPressed: selected
                          ? null
                          : () => _addPickupReservation(slot),
                      style: FilledButton.styleFrom(
                        backgroundColor: kLibBrownTitle,
                      ),
                      child: Text(selected ? 'Đã chọn' : 'Chọn'),
                    )
                  : const Chip(label: Text('Chờ duyệt')),
            ),
          );
        }),
        const SizedBox(height: 14),
      ],
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
              copy['_pickup_slot'] == true
                  ? '${apiText(copy['barcode'])} • Giữ theo slot'
                  : '${apiText(copy['barcode'])} • '
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

String _formatDateTime(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '—';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

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
