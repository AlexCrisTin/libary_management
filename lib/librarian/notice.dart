import 'dart:async';

import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';

import 'borrow_return_book_management.dart';
import 'librarian_nav.dart';
import 'librarian_pagination.dart';
import 'message_detail.dart';
import 'renewal_requests.dart';

class Notice extends StatefulWidget {
  const Notice({super.key});

  @override
  State<Notice> createState() => _NoticeState();
}

class _NoticeState extends State<Notice> {
  static const _pageSize = 10;

  List<Map<String, dynamic>> _notices = const [];
  bool _loading = true;
  bool _fetching = false;
  int _page = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      // Thông báo mới chỉ làm thay đổi trang đầu. Không truy vấn lại các
      // trang cũ khi thủ thư đang xem lịch sử để tránh tải thừa và lệch trang.
      if (_page == 1 && !_loading) _load(showLoading: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true, int? page}) async {
    if (_fetching) return;
    _fetching = true;
    var targetPage = page ?? _page;
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      var result = await _fetchPage(targetPage);
      var totalPages = _positiveInt(result['total_pages']);

      // Một tác vụ có thể vừa được xử lý ở màn hình khác khiến trang cuối
      // không còn tồn tại. Khi đó tự quay về trang cuối hợp lệ.
      if (targetPage > totalPages) {
        targetPage = totalPages;
        result = await _fetchPage(targetPage);
        totalPages = _positiveInt(result['total_pages']);
      }

      if (mounted) {
        setState(() {
          _notices = apiList(result['data']);
          _page = _positiveInt(result['page'], fallback: targetPage);
          _totalPages = totalPages;
          _totalItems = _nonNegativeInt(
            result['total'],
            fallback: _notices.length,
          );
          _error = null;
        });
      }
    } catch (error) {
      if (mounted && (showLoading || _notices.isEmpty)) {
        setState(() => _error = error.toString());
      }
    } finally {
      _fetching = false;
      if (mounted && showLoading) setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>> _fetchPage(int page) async => apiMap(
    await ApiClient.get(
      '/notifications/librarian',
      query: {'page': page, 'limit': _pageSize},
    ),
  );

  Future<void> _openNotice(Map<String, dynamic> notice) async {
    final type = notice['type']?.toString();
    Widget? page;
    switch (type) {
      case 'unread_message':
        final readerId = apiText(notice['reader_id'], fallback: '');
        if (readerId.isEmpty) return;
        page = MessageDetail(
          readerId: readerId,
          readerName: apiText(notice['reader_name'], fallback: 'Độc giả'),
        );
        break;
      case 'pickup_request':
        page = const BorrowReturnBookManagement(initialSection: 'pickupSlots');
        break;
      case 'renewal_request':
        page = const RenewalRequests();
        break;
      case 'overdue_loan':
        page = const BorrowReturnBookManagement(initialLoanStatus: 'overdue');
        break;
      case 'unpaid_fine':
        page = const BorrowReturnBookManagement(initialSection: 'fines');
        break;
    }
    final destination = page;
    if (destination == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
    await _load(showLoading: false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        const LibTitleHeader(title: 'Thông báo', showBack: true),
        if (_error == null)
          LibrarianPaginationBar(
            page: _page,
            totalPages: _totalPages,
            totalItems: _totalItems,
            pageSize: _pageSize,
            margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            onPrevious: !_loading && !_fetching && _page > 1
                ? () => _load(page: _page - 1)
                : null,
            onNext: !_loading && !_fetching && _page < _totalPages
                ? () => _load(page: _page + 1)
                : null,
          ),
        Expanded(
          child: ApiStateView(
            loading: _loading,
            error: _error,
            isEmpty: _notices.isEmpty,
            onRetry: _load,
            emptyMessage: 'Chưa có thông báo mới',
            child: RefreshIndicator(
              onRefresh: () => _load(showLoading: false),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                itemCount: _notices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) => _AdminNoticeTile(
                  notice: _notices[index],
                  onTap: () => _openNotice(_notices[index]),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _AdminNoticeTile extends StatelessWidget {
  const _AdminNoticeTile({required this.notice, required this.onTap});

  final Map<String, dynamic> notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = notice['type']?.toString();
    final opensPage = type != 'hold_request';
    return Material(
      color: kLibCardFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: kLibBeigeButton.withValues(alpha: .55)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: opensPage ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(_noticeIcon(notice['type']), color: kLibBrownTitle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${apiText(notice['reader_name'])} • '
                            '${apiText(notice['reader_code'])}',
                            style: const TextStyle(
                              color: kLibBrownTitle,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _noticeColor(
                              notice['type'],
                            ).withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _noticeBadge(notice['type']),
                            style: TextStyle(
                              color: _noticeColor(notice['type']),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      apiText(notice['title'], fallback: 'Thông báo'),
                      style: const TextStyle(
                        color: kLibBookTitle,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      apiText(notice['content']),
                      style: const TextStyle(
                        color: kLibBrownTitle,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _noticeTime(notice['created_at']),
                      style: TextStyle(
                        color: kLibBrownTitle.withValues(alpha: .6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _noticeIcon(dynamic type) => switch (type?.toString()) {
  'pickup_request' => Icons.event_available_rounded,
  'hold_request' => Icons.bookmark_add_rounded,
  'renewal_request' => Icons.update_rounded,
  'overdue_loan' => Icons.warning_amber_rounded,
  'unpaid_fine' => Icons.payments_outlined,
  'unread_message' => Icons.mark_chat_unread_rounded,
  _ => Icons.notifications_rounded,
};

Color _noticeColor(dynamic type) => switch (type?.toString()) {
  'overdue_loan' => kLibRed,
  'pickup_request' => const Color(0xFFE29A55),
  'hold_request' => const Color(0xFF9A79B8),
  'renewal_request' => const Color(0xFF588A73),
  'unpaid_fine' => kLibRed,
  'unread_message' => kLibBrownTitle,
  _ => kLibBrownTitle,
};

String _noticeBadge(dynamic type) => switch (type?.toString()) {
  'unread_message' => 'Tin mới',
  'pickup_request' => 'Chờ duyệt',
  'hold_request' => 'Đặt trước',
  'renewal_request' => 'Chờ duyệt',
  'overdue_loan' => 'Quá hạn',
  'unpaid_fine' => 'Chưa thu',
  _ => 'Mới',
};

String _noticeTime(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

int _positiveInt(dynamic value, {int fallback = 1}) {
  final parsed = int.tryParse(value?.toString() ?? '');
  return parsed == null || parsed < 1 ? fallback : parsed;
}

int _nonNegativeInt(dynamic value, {int fallback = 0}) {
  final parsed = int.tryParse(value?.toString() ?? '');
  return parsed == null || parsed < 0 ? fallback : parsed;
}
