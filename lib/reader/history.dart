import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/reader/detailbook.dart';
import 'package:libary_management/reader/reader_nav.dart';

enum _HistoryTab { borrowed, returned }

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List<Map<String, dynamic>> _items = const [];
  _HistoryTab _selectedTab = _HistoryTab.borrowed;
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> get _visibleItems {
    if (_selectedTab == _HistoryTab.returned) {
      return _items
          .where((item) => item['status']?.toString() == 'returned')
          .toList();
    }
    return _items;
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
      final data = apiMap(
        await ApiClient.get('/circulation/history', query: {'limit': 100}),
      );
      if (mounted) setState(() => _items = apiList(data['data']));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _borrowAgain(Map<String, dynamic> item) {
    final bookId = apiText(item['bib_id'], fallback: '');
    if (bookId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin đầu sách.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailBook(bookId: bookId)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        const TitleHeader(
          title: 'Lịch sử',
          showBack: true,
          color: Colors.white,
        ),
        Expanded(
          child: ApiStateView(
            loading: _loading,
            error: _error,
            isEmpty: _items.isEmpty,
            onRetry: _load,
            emptyMessage: 'Chưa có lịch sử mượn trả',
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                children: [
                  _HistoryTabs(
                    selected: _selectedTab,
                    onChanged: (value) => setState(() => _selectedTab = value),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    constraints: const BoxConstraints(minHeight: 440),
                    padding: const EdgeInsets.fromLTRB(14, 20, 14, 24),
                    decoration: BoxDecoration(
                      color: kCardFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _visibleItems.isEmpty
                        ? _EmptyHistory(tab: _selectedTab)
                        : Column(
                            children: [
                              for (
                                var index = 0;
                                index < _visibleItems.length;
                                index++
                              ) ...[
                                _HistoryCard(
                                  item: _visibleItems[index],
                                  onBorrowAgain: () =>
                                      _borrowAgain(_visibleItems[index]),
                                ),
                                if (index < _visibleItems.length - 1)
                                  const Divider(height: 30),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _HistoryTabs extends StatelessWidget {
  const _HistoryTabs({required this.selected, required this.onChanged});

  final _HistoryTab selected;
  final ValueChanged<_HistoryTab> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: kBeigeButton,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      children: [
        _tab('Mượn', _HistoryTab.borrowed),
        _tab('Trả', _HistoryTab.returned),
      ],
    ),
  );

  Widget _tab(String label, _HistoryTab value) {
    final active = selected == value;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? kCardFill : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? kBeigeButton : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item, required this.onBorrowAgain});

  final Map<String, dynamic> item;
  final VoidCallback onBorrowAgain;

  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString() ?? '';
    final returned = status == 'returned';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kBeigeSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: BookCover(
            width: 92,
            height: 138,
            url: item['cover_url']?.toString(),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: SizedBox(
            height: 158,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  apiText(item['book_title']),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kBookTitle,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ngày mượn: ${apiDate(item['borrow_date'])}',
                  style: _dateStyle,
                ),
                Text(
                  returned
                      ? 'Ngày trả: ${apiDate(item['return_date'])}'
                      : 'Hạn trả: ${apiDate(item['due_date'])}',
                  style: _dateStyle,
                ),
                const Spacer(),
                if (returned)
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 126,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: onBorrowAgain,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: kBeigeButton,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Mượn lại'),
                      ),
                    ),
                  )
                else
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _StatusChip(status: status),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'borrowed' => ('Đang mượn', kBeigeButton),
      'overdue' => ('Quá hạn', const Color(0xFFD18282)),
      'lost' => ('Đã mất', const Color(0xFFD18282)),
      _ => (apiText(status), kBeigeButton),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.tab});

  final _HistoryTab tab;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 220,
    child: Center(
      child: Text(
        tab == _HistoryTab.returned
            ? 'Chưa có sách đã trả'
            : 'Chưa có lịch sử mượn sách',
        style: const TextStyle(color: kMuted, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

const _dateStyle = TextStyle(
  color: Colors.black87,
  fontSize: 13,
  fontWeight: FontWeight.w600,
  height: 1.45,
);
