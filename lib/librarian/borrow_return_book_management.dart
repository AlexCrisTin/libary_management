import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';

import 'borrow_return_detail.dart';
import 'borrow_flow.dart';
import 'librarian_nav.dart';
import 'librarian_pagination.dart';
import 'renewal_requests.dart';

enum _ManagementView { loans, fines, pickupSlots }

class BorrowReturnBookManagement extends StatefulWidget {
  const BorrowReturnBookManagement({super.key});
  @override
  State<BorrowReturnBookManagement> createState() =>
      _BorrowReturnBookManagementState();
}

class _BorrowReturnBookManagementState
    extends State<BorrowReturnBookManagement> {
  static const _pageSize = 20;

  final _search = TextEditingController();
  List<Map<String, dynamic>> _loans = const [];
  List<Map<String, dynamic>> _pickupSlots = const [];
  _ManagementView _view = _ManagementView.loans;
  bool _loading = true;
  String? _processingSlotId;
  int _page = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _requestVersion = 0;
  String? _error;
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
      if (_view == _ManagementView.pickupSlots) {
        final result = apiMap(
          await ApiClient.get(
            '/pickup-reservations',
            query: {
              'status': 'active',
              'keyword': _search.text.trim(),
              'page': targetPage,
              'limit': _pageSize,
            },
          ),
        );
        if (!mounted || requestVersion != _requestVersion) return;
        final totalPages = int.tryParse('${result['total_pages']}') ?? 1;
        setState(() {
          _pickupSlots = apiList(result['data']);
          _page = int.tryParse('${result['page']}') ?? targetPage;
          _totalPages = totalPages < 1 ? 1 : totalPages;
          _totalItems =
              int.tryParse('${result['total']}') ?? _pickupSlots.length;
        });
        return;
      }
      final result = apiMap(
        await ApiClient.get(
          _view == _ManagementView.fines
              ? '/circulation/history'
              : '/circulation/active',
          query: {
            'keyword': _search.text.trim(),
            if (_view == _ManagementView.fines) 'has_fine': true,
            'page': targetPage,
            'limit': _pageSize,
          },
        ),
      );
      if (!mounted || requestVersion != _requestVersion) return;
      final totalPages = int.tryParse('${result['total_pages']}') ?? 1;
      setState(() {
        _loans = apiList(result['data']);
        _page = int.tryParse('${result['page']}') ?? targetPage;
        _totalPages = totalPages < 1 ? 1 : totalPages;
        _totalItems = int.tryParse('${result['total']}') ?? _loans.length;
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

  void _searchFromFirstPage() => _load(page: 1);

  Future<void> _approveSlot(Map<String, dynamic> slot) async {
    final id = apiText(slot['reservation_id'], fallback: '');
    if (id.isEmpty || _processingSlotId != null) return;
    final duration = await _choosePickupDuration();
    if (duration == null || !mounted) return;
    setState(() => _processingSlotId = id);
    try {
      final expiry = DateTime.now().add(duration).toUtc().toIso8601String();
      await ApiClient.put(
        '/pickup-reservations/$id/approve',
        body: {'pickup_expires_at': expiry},
      );
      _showMessage('Đã duyệt và giữ một bản sách cho độc giả.');
      await _load();
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _processingSlotId = null);
    }
  }

  Future<void> _rejectSlot(Map<String, dynamic> slot) async {
    final id = apiText(slot['reservation_id'], fallback: '');
    if (id.isEmpty || _processingSlotId != null) return;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Từ chối yêu cầu'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Lý do',
            hintText: 'Ví dụ: Bản sách đang được xử lý...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD18282),
            ),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !mounted) return;
    setState(() => _processingSlotId = id);
    try {
      await ApiClient.put(
        '/pickup-reservations/$id/reject',
        body: {'reason': reason.trim()},
      );
      _showMessage('Đã từ chối yêu cầu đặt slot.');
      await _load();
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _processingSlotId = null);
    }
  }

  Future<Duration?> _choosePickupDuration() {
    const choices = <(String, Duration)>[
      ('2 giờ', Duration(hours: 2)),
      ('4 giờ', Duration(hours: 4)),
      ('8 giờ', Duration(hours: 8)),
      ('24 giờ', Duration(hours: 24)),
      ('3 ngày', Duration(days: 3)),
      ('7 ngày', Duration(days: 7)),
    ];
    return showModalBottomSheet<Duration>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF7F0EA),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Giới hạn thời gian đến lấy',
                style: TextStyle(
                  color: kLibBrownTitle,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Hết thời hạn, bản sách sẽ tự động được trả về trạng thái có sẵn.',
                style: TextStyle(color: kLibBrownTitle, height: 1.35),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: choices.map((choice) {
                  return ActionChip(
                    avatar: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text(choice.$1),
                    onPressed: () => Navigator.pop(sheetContext, choice.$2),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Column(
        children: [
          LibTitleHeader(
            title: 'Quản lý mượn / trả',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Duyệt yêu cầu gia hạn',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RenewalRequests(),
                      ),
                    );
                    _load();
                  },
                  icon: const Icon(Icons.pending_actions, color: Colors.white),
                ),
                IconButton(
                  tooltip: 'Lập phiếu mượn',
                  onPressed: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const BorrowFlow()),
                    );
                    if (changed == true) _load();
                  },
                  icon: const Icon(Icons.add, color: Colors.white, size: 30),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onSubmitted: (_) => _searchFromFirstPage(),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : () => _load(),
                  icon: const Icon(Icons.refresh, color: kLibBrownTitle),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 0, 11, 10),
            child: SegmentedButton<_ManagementView>(
              segments: const [
                ButtonSegment(
                  value: _ManagementView.loans,
                  icon: Icon(Icons.menu_book_rounded),
                  label: Text('Đang mượn'),
                ),
                ButtonSegment(
                  value: _ManagementView.fines,
                  icon: Icon(Icons.payments_outlined),
                  label: Text('Tiền phạt'),
                ),
                ButtonSegment(
                  value: _ManagementView.pickupSlots,
                  icon: Icon(Icons.event_available_rounded),
                  label: Text('Đặt slot'),
                ),
              ],
              selected: {_view},
              showSelectedIcon: false,
              onSelectionChanged: (value) {
                setState(() => _view = value.first);
                _load(page: 1);
              },
            ),
          ),
          if (_error == null)
            LibrarianPaginationBar(
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
          _ManagementTableHeader(
            pickupSlots: _view == _ManagementView.pickupSlots,
          ),
          Expanded(
            child: ApiStateView(
              loading: _loading,
              error: _error,
              isEmpty: _view == _ManagementView.pickupSlots
                  ? _pickupSlots.isEmpty
                  : _loans.isEmpty,
              onRetry: _load,
              emptyMessage: switch (_view) {
                _ManagementView.fines =>
                  'Không có giao dịch phát sinh tiền phạt',
                _ManagementView.pickupSlots =>
                  'Không có yêu cầu đặt slot đang hoạt động',
                _ => 'Không có lượt mượn đang hoạt động',
              },
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(11, 6, 11, 8),
                  itemCount: _view == _ManagementView.pickupSlots
                      ? _pickupSlots.length
                      : _loans.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    if (_view == _ManagementView.pickupSlots) {
                      final slot = _pickupSlots[i];
                      return _PickupSlotRow(
                        slot: slot,
                        processing:
                            _processingSlotId ==
                            slot['reservation_id']?.toString(),
                        onApprove: () => _approveSlot(slot),
                        onReject: () => _rejectSlot(slot),
                      );
                    }
                    return _LoanRow(
                      loan: _loans[i],
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BorrowReturnDetail(loan: _loans[i]),
                          ),
                        );
                        _load();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

const _header = TextStyle(
  color: Colors.white,
  fontSize: 11,
  fontWeight: FontWeight.w700,
);

class _ManagementTableHeader extends StatelessWidget {
  const _ManagementTableHeader({required this.pickupSlots});

  final bool pickupSlots;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 11),
      height: 44,
      decoration: BoxDecoration(
        color: kLibBeigeButton,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 2,
            child: Center(child: Text('Độc giả', style: _header)),
          ),
          const Expanded(
            flex: 2,
            child: Center(child: Text('Sách', style: _header)),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                pickupSlots ? 'Ngày yêu cầu' : 'Ngày mượn',
                style: _header,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                pickupSlots ? 'Trạng thái' : 'Ngày trả',
                style: _header,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(pickupSlots ? 'Xử lý' : 'Chi tiết', style: _header),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupSlotRow extends StatelessWidget {
  const _PickupSlotRow({
    required this.slot,
    required this.processing,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> slot;
  final bool processing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: kLibBrownTitle,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    final status = apiText(slot['status'], fallback: 'pending');
    Widget cell(String text) => Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          cell(apiText(slot['reader_name'])),
          cell(apiText(slot['book_title'])),
          cell(apiDate(slot['requested_at'])),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PickupStatusChip(status: status),
                if (status == 'approved')
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'Đến ${_apiDateTime(slot['pickup_expires_at'])}',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: style.copyWith(fontSize: 9),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: processing
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : status == 'pending'
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Duyệt yêu cầu',
                        visualDensity: VisualDensity.compact,
                        onPressed: onApprove,
                        icon: const Icon(
                          Icons.check_circle_rounded,
                          color: kLibGreen,
                          size: 25,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Từ chối yêu cầu',
                        visualDensity: VisualDensity.compact,
                        onPressed: onReject,
                        icon: const Icon(
                          Icons.cancel_rounded,
                          color: kLibRed,
                          size: 25,
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: Icon(
                      Icons.lock_clock_rounded,
                      color: kLibBrownTitle,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PickupStatusChip extends StatelessWidget {
  const _PickupStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'approved' => ('Đã giữ', kLibGreen),
      'pending' => ('Chờ duyệt', kLibBeigeButton),
      _ => (status, kLibRed),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _apiDateTime(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '—';
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(date.hour)}:${two(date.minute)} ${two(date.day)}/${two(date.month)}';
}

class _LoanRow extends StatelessWidget {
  const _LoanRow({required this.loan, required this.onTap});
  final Map<String, dynamic> loan;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: kLibBrownTitle,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    Widget cell(String text, int flex) => Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          cell(apiText(loan['reader_name']), 2),
          cell(apiText(loan['book_title']), 2),
          cell(apiDate(loan['borrow_date']), 2),
          cell(apiDate(loan['due_date']), 2),
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
