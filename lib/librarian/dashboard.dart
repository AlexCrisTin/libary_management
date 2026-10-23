import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';

import 'librarian_nav.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({
    super.key,
    this.refreshRequest = 0,
    this.onOpenTab,
    this.onOpenReaderManagement,
    this.onOpenBorrowReturn,
    this.onOpenReport,
    this.onOpenMessages,
    this.onOpenProfile,
    this.onOpenNotice,
  });

  final int refreshRequest;
  final ValueChanged<int>? onOpenTab;
  final VoidCallback? onOpenReaderManagement;
  final ValueChanged<String>? onOpenBorrowReturn;
  final VoidCallback? onOpenReport;
  final VoidCallback? onOpenMessages;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenNotice;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Map<String, dynamic> _statistics = const {};
  int _periodDays = 7;
  bool _loading = true;
  String? _error;

  Map<String, dynamic> get _summary => apiMap(_statistics['summary']);
  List<Map<String, dynamic>> get _trend => apiList(_statistics['loan_trend']);
  List<Map<String, dynamic>> get _categories =>
      apiList(_statistics['categories']);
  List<Map<String, dynamic>> get _topBooks => apiList(_statistics['top_books']);
  List<Map<String, dynamic>> get _topReaders =>
      apiList(_statistics['top_readers']);
  List<Map<String, dynamic>> get _dueSoonLoans =>
      apiList(_statistics['due_soon_loans']);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant Dashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshRequest == widget.refreshRequest) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = apiMap(
        await ApiClient.get(
          '/dashboard/statistics',
          query: {'days': _periodDays},
        ),
      );
      if (mounted) setState(() => _statistics = data);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changePeriod(int? days) async {
    if (days == null || days == _periodDays) return;
    setState(() => _periodDays = days);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LibBeigeHeader(
          child: Row(
            children: [
              InkWell(
                onTap: widget.onOpenProfile,
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 17,
                        backgroundColor: kLibBeigeSoft,
                        child: Icon(
                          Icons.person,
                          size: 21,
                          color: kLibBrownTitle,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        AppSession.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Thông báo',
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 27,
                ),
                onPressed: widget.onOpenNotice,
              ),
            ],
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
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 120),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Tổng quan thư viện',
                          style: TextStyle(
                            color: kLibBrownTitle,
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _PeriodDropdown(
                        value: _periodDays,
                        onChanged: _changePeriod,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SummaryGrid(
                    summary: _summary,
                    onOpenActiveLoans: () =>
                        widget.onOpenBorrowReturn?.call(''),
                    onOpenOverdueLoans: () =>
                        widget.onOpenBorrowReturn?.call('overdue'),
                    onOpenReaders: widget.onOpenReaderManagement,
                    onOpenBooks: () => widget.onOpenTab?.call(1),
                  ),
                  const SizedBox(height: 14),
                  _DueSoonLoans(
                    items: _dueSoonLoans,
                    onOpen: (status) => widget.onOpenBorrowReturn?.call(status),
                  ),
                  const SizedBox(height: 14),
                  _DashboardSection(
                    title: 'Xu hướng mượn / trả',
                    subtitle: '$_periodDays ngày gần nhất',
                    child: _LoanTrendChart(items: _trend),
                  ),
                  const SizedBox(height: 14),
                  _DashboardSection(
                    title: 'Phân bố thể loại',
                    subtitle: 'Theo số đầu sách',
                    child: _CategoryDistribution(items: _categories),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 700;
                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _TopBooks(items: _topBooks)),
                            const SizedBox(width: 14),
                            Expanded(child: _TopReaders(items: _topReaders)),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          _TopBooks(items: _topBooks),
                          const SizedBox(height: 14),
                          _TopReaders(items: _topReaders),
                        ],
                      );
                    },
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

class _PeriodDropdown extends StatelessWidget {
  const _PeriodDropdown({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 11, right: 5),
      decoration: BoxDecoration(
        color: kLibCardFill,
        borderRadius: BorderRadius.circular(9),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(
            color: kLibBrownTitle,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          items: const [
            DropdownMenuItem(value: 7, child: Text('7 ngày')),
            DropdownMenuItem(value: 30, child: Text('30 ngày')),
            DropdownMenuItem(value: 90, child: Text('90 ngày')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.summary,
    required this.onOpenActiveLoans,
    required this.onOpenOverdueLoans,
    required this.onOpenReaders,
    required this.onOpenBooks,
  });

  final Map<String, dynamic> summary;
  final VoidCallback onOpenActiveLoans;
  final VoidCallback onOpenOverdueLoans;
  final VoidCallback? onOpenReaders;
  final VoidCallback onOpenBooks;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryData(
        label: 'Sách đang mượn',
        value: _number(summary['active_loans']),
        note: 'lượt đang hoạt động',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF475673),
        onTap: onOpenActiveLoans,
      ),
      _SummaryData(
        label: 'Lượt quá hạn',
        value: _number(summary['overdue_loans']),
        note: 'cần xử lý',
        icon: Icons.schedule_rounded,
        color: kLibRed,
        onTap: onOpenOverdueLoans,
      ),
      _SummaryData(
        label: 'Tổng độc giả',
        value: _number(summary['total_readers']),
        note: 'hồ sơ độc giả',
        icon: Icons.groups_rounded,
        color: kLibBrownTitle,
        onTap: onOpenReaders,
      ),
      _SummaryData(
        label: 'Tổng đầu sách',
        value: _number(summary['total_titles']),
        note: '${_number(summary['total_copies'])} bản sao',
        icon: Icons.auto_stories_rounded,
        color: const Color(0xFF6E7E65),
        onTap: onOpenBooks,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 4 ? 1.5 : 1.38,
          ),
          itemCount: cards.length,
          itemBuilder: (_, index) => _SummaryCard(data: cards[index]),
        );
      },
    );
  }
}

class _SummaryData {
  const _SummaryData({
    required this.label,
    required this.value,
    required this.note,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final String note;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final _SummaryData data;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: data.onTap != null,
      label: '${data.label}: ${data.value}. Mở danh sách chi tiết',
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFEEEEEE)),
          borderRadius: BorderRadius.circular(13),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: data.onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: data.color,
                      child: Icon(data.icon, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        data.label,
                        maxLines: 2,
                        style: const TextStyle(
                          color: Color(0xFF4D4D4D),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (data.onTap != null)
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                        color: data.color.withValues(alpha: .75),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  data.value,
                  style: const TextStyle(
                    color: Color(0xFF26334C),
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  data.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9A9A9A),
                    fontSize: 10,
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

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    required this.title,
    required this.subtitle,
    required this.child,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(13),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF39445B),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kLibCardFill,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: kLibBrownTitle,
                      size: 22,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _DueSoonLoans extends StatelessWidget {
  const _DueSoonLoans({required this.items, required this.onOpen});

  final List<Map<String, dynamic>> items;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return _DashboardSection(
      title: 'Sắp đến hạn / quá hạn',
      subtitle: 'Quá hạn & 7 ngày tới',
      onTap: () => onOpen('attention'),
      child: items.isEmpty
          ? const _EmptyDashboardData(
              message: 'Không có lượt mượn cần nhắc trả',
            )
          : Column(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final days = int.tryParse('${item['days_until_due']}') ?? 0;
                final overdue = item['is_overdue'] == true || days < 0;
                final statusText = overdue
                    ? 'Quá hạn ${days.abs()} ngày'
                    : days == 0
                    ? 'Hạn trả hôm nay'
                    : days == 1
                    ? 'Còn 1 ngày'
                    : 'Còn $days ngày';
                final statusColor = overdue
                    ? kLibRed
                    : days <= 2
                    ? const Color(0xFFE29A55)
                    : kLibGreen;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onOpen(overdue ? 'overdue' : 'borrowed'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: index == items.length - 1
                            ? null
                            : const Border(
                                bottom: BorderSide(color: Color(0xFFEEEEEE)),
                              ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: statusColor.withValues(alpha: .14),
                            child: Icon(
                              overdue
                                  ? Icons.warning_amber_rounded
                                  : Icons.schedule_rounded,
                              color: statusColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  apiText(item['full_name']),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF39445B),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${apiText(item['reader_code'])} • ${apiText(item['title'])}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF777777),
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  'Hạn trả: ${apiDate(item['due_date'])}',
                                  style: const TextStyle(
                                    color: Color(0xFF999999),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 84),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: kLibBrownTitle,
                            size: 21,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
    );
  }
}

class _LoanTrendChart extends StatelessWidget {
  const _LoanTrendChart({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyDashboardData(message: 'Chưa có dữ liệu mượn trả');
    }
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ChartLegend(color: kLibBrownTitle, label: 'Mượn'),
            SizedBox(width: 18),
            _ChartLegend(color: kLibGreen, label: 'Trả'),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: CustomPaint(
            painter: _TrendPainter(items: items),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(color: Color(0xFF777777), fontSize: 10),
      ),
    ],
  );
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 24.0;
    const top = 8.0;
    const bottom = 24.0;
    final chartWidth = size.width - left - 4;
    final chartHeight = size.height - top - bottom;
    final maxValue = items.fold<int>(1, (value, item) {
      final borrowed = int.tryParse('${item['borrowed'] ?? 0}') ?? 0;
      final returned = int.tryParse('${item['returned'] ?? 0}') ?? 0;
      return math.max(value, math.max(borrowed, returned));
    });

    final gridPaint = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = top + chartHeight * i / 3;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
    }

    _drawSeries(
      canvas,
      size,
      left,
      top,
      chartWidth,
      chartHeight,
      maxValue,
      'borrowed',
      kLibBrownTitle,
    );
    _drawSeries(
      canvas,
      size,
      left,
      top,
      chartWidth,
      chartHeight,
      maxValue,
      'returned',
      kLibGreen,
    );

    final labelIndexes = <int>{0, items.length ~/ 2, items.length - 1};
    for (final index in labelIndexes) {
      if (index < 0 || index >= items.length) continue;
      final date = items[index]['date']?.toString() ?? '';
      final label = date.length >= 10 ? date.substring(5) : date;
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Color(0xFF999999), fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = items.length == 1
          ? left + chartWidth / 2
          : left + chartWidth * index / (items.length - 1);
      painter.paint(
        canvas,
        Offset(
          (x - painter.width / 2).clamp(0, size.width - painter.width),
          size.height - 17,
        ),
      );
    }
  }

  void _drawSeries(
    Canvas canvas,
    Size size,
    double left,
    double top,
    double chartWidth,
    double chartHeight,
    int maxValue,
    String key,
    Color color,
  ) {
    if (items.isEmpty) return;
    final path = Path();
    for (var index = 0; index < items.length; index++) {
      final value = int.tryParse('${items[index][key] ?? 0}') ?? 0;
      final x = items.length == 1
          ? left + chartWidth / 2
          : left + chartWidth * index / (items.length - 1);
      final y = top + chartHeight * (1 - value / maxValue);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.items != items;
}

class _CategoryDistribution extends StatelessWidget {
  const _CategoryDistribution({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyDashboardData(message: 'Chưa có dữ liệu thể loại');
    }
    final maximum = items.fold<int>(1, (value, item) {
      return math.max(value, int.tryParse('${item['title_count'] ?? 0}') ?? 0);
    });
    return Column(
      children: items.map((item) {
        final count = int.tryParse('${item['title_count'] ?? 0}') ?? 0;
        final copies = int.tryParse('${item['copy_count'] ?? 0}') ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      apiText(item['name']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4F596C),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '$count đầu sách • $copies bản',
                    style: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: count / maximum,
                  minHeight: 8,
                  color: kLibBrownTitle,
                  backgroundColor: kLibBeigeSoft,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TopBooks extends StatelessWidget {
  const _TopBooks({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) => _RankingSection(
    title: 'Sách được mượn nhiều',
    emptyMessage: 'Chưa có lượt mượn',
    items: items
        .map(
          (item) => _RankingData(
            title: apiText(item['title']),
            subtitle: '${_number(item['borrow_count'])} lượt mượn',
          ),
        )
        .toList(),
  );
}

class _TopReaders extends StatelessWidget {
  const _TopReaders({required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) => _RankingSection(
    title: 'Độc giả mượn nhiều',
    emptyMessage: 'Chưa có dữ liệu độc giả',
    items: items
        .map(
          (item) => _RankingData(
            title: apiText(item['full_name']),
            subtitle:
                '${apiText(item['reader_code'])} • ${_number(item['borrow_count'])} lượt',
          ),
        )
        .toList(),
  );
}

class _RankingData {
  const _RankingData({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

class _RankingSection extends StatelessWidget {
  const _RankingSection({
    required this.title,
    required this.emptyMessage,
    required this.items,
  });

  final String title;
  final String emptyMessage;
  final List<_RankingData> items;

  @override
  Widget build(BuildContext context) {
    return _DashboardSection(
      title: title,
      subtitle: 'Top 5',
      child: items.isEmpty
          ? _EmptyDashboardData(message: emptyMessage)
          : Column(
              children: List.generate(items.length, (index) {
                final item = items[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == items.length - 1 ? 0 : 10,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: index == 0
                            ? kLibBeigeButton
                            : kLibCardFill,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: kLibBrownTitle,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF4F596C),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              item.subtitle,
                              style: const TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
    );
  }
}

class _EmptyDashboardData extends StatelessWidget {
  const _EmptyDashboardData({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Color(0xFF999999), fontSize: 11),
    ),
  );
}

String _number(dynamic value) {
  final number = num.tryParse('${value ?? 0}') ?? 0;
  final digits = number.round().toString();
  return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
}
