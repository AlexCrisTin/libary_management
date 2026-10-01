import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/reader/notice.dart';
import 'package:libary_management/reader/reader_nav.dart';

class SeeBorrowBook extends StatefulWidget {
  const SeeBorrowBook({super.key, this.onOpenSearch});

  final VoidCallback? onOpenSearch;

  @override
  State<SeeBorrowBook> createState() => _SeeBorrowBookState();
}

class _SeeBorrowBookState extends State<SeeBorrowBook> {
  List<Map<String, dynamic>> _loans = const [];
  late DateTime _focusedMonth;
  DateTime? _selectedDueDate;
  bool _loading = true;
  String? _renewingId;
  String? _error;
  int _unreadNotices = 0;

  List<Map<String, dynamic>> get _visibleLoans {
    final selected = _selectedDueDate;
    if (selected == null) return _loans;
    return _loans.where((loan) {
      final dueDate = _parseDate(loan['due_date']);
      return dueDate != null && _sameDay(dueDate, selected);
    }).toList();
  }

  Set<String> get _dueDateKeys => _loans
      .map((loan) => _parseDate(loan['due_date']))
      .whereType<DateTime>()
      .map(_dateKey)
      .toSet();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = apiMap(
        await ApiClient.get('/circulation/active', query: {'limit': 100}),
      );
      if (mounted) setState(() => _loans = apiList(result['data']));
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
      // Lịch mượn sách vẫn hoạt động nếu thông báo tạm thời không tải được.
    }
  }

  Future<void> _openNotices() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Notice()),
    );
    await _loadUnreadNotices();
  }

  Future<void> _renew(Map<String, dynamic> loan) async {
    final id = apiText(loan['tx_id'], fallback: '');
    if (id.isEmpty || _renewingId != null) return;
    setState(() => _renewingId = id);
    try {
      await ApiClient.post('/circulation/renew/$id');
      if (mounted) setState(() => _selectedDueDate = null);
      await _load();
      _showMessage('Đã gửi yêu cầu gia hạn đến thủ thư.');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _renewingId = null);
    }
  }

  Future<void> _showReturnInstructions(Map<String, dynamic> loan) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kCardFill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Trả sách',
          style: TextStyle(color: kBrownTitle, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Bạn hãy mang “${apiText(loan['book_title'])}” đến quầy thủ thư '
          'để được quét mã và xác nhận trả sách.',
          style: const TextStyle(color: kBookTitle, height: 1.45),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kBrownTitle),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  void _selectDate(DateTime date) {
    if (!_dueDateKeys.contains(_dateKey(date))) return;
    setState(() {
      _selectedDueDate =
          _selectedDueDate != null && _sameDay(_selectedDueDate!, date)
          ? null
          : date;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SearchHeaderBar(
          readOnly: true,
          onTap: widget.onOpenSearch,
          trailing: Badge(
            isLabelVisible: _unreadNotices > 0,
            label: Text(
              _unreadNotices > 99 ? '99+' : '$_unreadNotices',
              style: const TextStyle(fontSize: 9),
            ),
            child: IconButton(
              tooltip: 'Thông báo',
              onPressed: _openNotices,
              icon: const Icon(
                Icons.notifications_rounded,
                color: kBrownTitle,
                size: 30,
              ),
            ),
          ),
        ),
        Expanded(
          child: ApiStateView(
            loading: _loading,
            error: _error,
            isEmpty: false,
            onRetry: _load,
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 100),
                children: [
                  _LoanCalendar(
                    focusedMonth: _focusedMonth,
                    today: DateTime.now(),
                    selectedDate: _selectedDueDate,
                    dueDateKeys: _dueDateKeys,
                    onPrevious: _previousMonth,
                    onNext: _nextMonth,
                    onSelectDate: _selectDate,
                  ),
                  const SizedBox(height: 8),
                  _LoanSectionHeader(
                    selectedDate: _selectedDueDate,
                    onShowAll: () => setState(() => _selectedDueDate = null),
                  ),
                  if (_visibleLoans.isEmpty)
                    _EmptyLoans(selectedDate: _selectedDueDate)
                  else
                    ..._visibleLoans.map(
                      (loan) => Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                        child: _LoanCard(
                          loan: loan,
                          renewing: _renewingId == loan['tx_id']?.toString(),
                          renewalPending:
                              loan['renewal_request_status']?.toString() ==
                              'pending',
                          onReturn: () => _showReturnInstructions(loan),
                          onRenew: () => _renew(loan),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoanCalendar extends StatelessWidget {
  const _LoanCalendar({
    required this.focusedMonth,
    required this.today,
    required this.selectedDate,
    required this.dueDateKeys,
    required this.onPrevious,
    required this.onNext,
    required this.onSelectDate,
  });

  final DateTime focusedMonth;
  final DateTime today;
  final DateTime? selectedDate;
  final Set<String> dueDateKeys;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelectDate;

  List<DateTime> get _days {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month);
    final firstMonday = firstDay.subtract(
      Duration(days: firstDay.weekday - DateTime.monday),
    );
    return List.generate(42, (index) => firstMonday.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF1F1F1)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tháng ${focusedMonth.month}, ${focusedMonth.year}',
                  style: const TextStyle(
                    color: Color(0xFF637397),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _MonthButton(
                tooltip: 'Tháng trước',
                icon: Icons.chevron_left_rounded,
                onPressed: onPrevious,
              ),
              const SizedBox(width: 10),
              _MonthButton(
                tooltip: 'Tháng sau',
                icon: Icons.chevron_right_rounded,
                onPressed: onNext,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              _WeekDay('T2'),
              _WeekDay('T3'),
              _WeekDay('T4'),
              _WeekDay('T5'),
              _WeekDay('T6'),
              _WeekDay('T7'),
              _WeekDay('CN'),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.08,
            ),
            itemCount: _days.length,
            itemBuilder: (_, index) {
              final date = _days[index];
              final inMonth = date.month == focusedMonth.month;
              final isToday = _sameDay(date, today);
              final isDue = dueDateKeys.contains(_dateKey(date));
              final isSelected =
                  selectedDate != null && _sameDay(date, selectedDate!);
              final background = isDue
                  ? const Color(0xFFC62520)
                  : isToday
                  ? const Color(0xFF72CDF1)
                  : Colors.transparent;
              final foreground = isDue || isToday
                  ? Colors.white
                  : inMonth
                  ? const Color(0xFF7583A3)
                  : const Color(0xFFD7DCE5);
              return Semantics(
                label: isDue
                    ? 'Ngày ${date.day}, có sách đến hạn'
                    : 'Ngày ${date.day}',
                button: isDue,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: isDue ? () => onSelectDate(date) : null,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: background,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: kBookTitle, width: 3)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: foreground,
                          fontSize: 15,
                          fontWeight: isDue || isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: Color(0xFF72CDF1)),
              SizedBox(width: 5),
              Text('Hôm nay', style: TextStyle(color: kMuted, fontSize: 12)),
              SizedBox(width: 16),
              _LegendDot(color: Color(0xFFC62520)),
              SizedBox(width: 5),
              Text(
                'Ngày hết hạn',
                style: TextStyle(color: kMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6F7FA),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFFDDE1EB)),
      ),
    );
  }
}

class _WeekDay extends StatelessWidget {
  const _WeekDay(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xFFBBC1CB),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _LoanSectionHeader extends StatelessWidget {
  const _LoanSectionHeader({
    required this.selectedDate,
    required this.onShowAll,
  });

  final DateTime? selectedDate;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedDate == null
                  ? 'Sách đang mượn'
                  : 'Hết hạn ${_displayDate(selectedDate!)}',
              style: const TextStyle(
                color: kBrownTitle,
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (selectedDate != null)
            TextButton(onPressed: onShowAll, child: const Text('Xem tất cả')),
        ],
      ),
    );
  }
}

class _EmptyLoans extends StatelessWidget {
  const _EmptyLoans({required this.selectedDate});

  final DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: kCardFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        selectedDate == null
            ? 'Bạn chưa mượn sách nào.'
            : 'Không có sách hết hạn trong ngày này.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({
    required this.loan,
    required this.renewing,
    required this.renewalPending,
    required this.onReturn,
    required this.onRenew,
  });

  final Map<String, dynamic> loan;
  final bool renewing;
  final bool renewalPending;
  final VoidCallback onReturn;
  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    final overdue =
        loan['is_overdue'] == true ||
        loan['is_overdue'] == 1 ||
        loan['is_overdue']?.toString() == '1';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kCardFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: BookCover(
            width: 105,
            height: 158,
            url: loan['cover_url']?.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                apiText(loan['book_title']),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kBookTitle,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Ngày mượn: ${apiDate(loan['borrow_date'])}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Hạn trả: ${apiDate(loan['due_date'])}',
                style: TextStyle(
                  color: overdue ? const Color(0xFFC62520) : Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (overdue)
                Text(
                  'Quá hạn ${apiText(loan['overdue_days'], fallback: '0')} ngày',
                  style: const TextStyle(
                    color: Color(0xFFC62520),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: 9),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: onReturn,
                  style: _loanButtonStyle,
                  child: const Text('Trả sách'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: renewing || renewalPending || overdue
                      ? null
                      : onRenew,
                  style: _loanButtonStyle,
                  child: renewing
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          overdue
                              ? 'Đã quá hạn'
                              : renewalPending
                              ? 'Đang chờ duyệt'
                              : 'Yêu cầu gia hạn',
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final _loanButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: kBeigeButton,
  disabledBackgroundColor: kBeigeButton.withValues(alpha: .7),
  foregroundColor: Colors.white,
  elevation: 0,
  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
);

DateTime? _parseDate(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  final datePart = text.length >= 10 ? text.substring(0, 10) : text;
  final parts = datePart.split('-');
  if (parts.length == 3) {
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year != null && month != null && day != null) {
      return DateTime(year, month, day);
    }
  }
  final parsed = DateTime.tryParse(text)?.toLocal();
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _displayDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';
