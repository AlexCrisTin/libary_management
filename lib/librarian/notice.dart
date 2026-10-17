import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';

import 'librarian_nav.dart';

class Notice extends StatefulWidget {
  const Notice({super.key});

  @override
  State<Notice> createState() => _NoticeState();
}

class _NoticeState extends State<Notice> {
  List<Map<String, dynamic>> _notices = const [];
  bool _loading = true;
  String? _error;

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
      final result = apiMap(
        await ApiClient.get('/notifications/librarian', query: {'limit': 200}),
      );
      if (mounted) setState(() => _notices = apiList(result['data']));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        const LibTitleHeader(title: 'Thông báo', showBack: true),
        Expanded(
          child: ApiStateView(
            loading: _loading,
            error: _error,
            isEmpty: _notices.isEmpty,
            onRetry: _load,
            emptyMessage: 'Không có công việc mới cần xử lý',
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                itemCount: _notices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) =>
                    _AdminNoticeTile(notice: _notices[index]),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _AdminNoticeTile extends StatelessWidget {
  const _AdminNoticeTile({required this.notice});

  final Map<String, dynamic> notice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kLibCardFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLibBeigeButton.withValues(alpha: .55)),
      ),
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
                        'Cần xử lý',
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
                  style: const TextStyle(color: kLibBrownTitle, height: 1.35),
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
    );
  }
}

IconData _noticeIcon(dynamic type) => switch (type?.toString()) {
  'pickup_request' => Icons.event_available_rounded,
  'renewal_request' => Icons.update_rounded,
  'overdue_loan' => Icons.warning_amber_rounded,
  'unread_message' => Icons.mark_chat_unread_rounded,
  _ => Icons.notifications_rounded,
};

Color _noticeColor(dynamic type) => switch (type?.toString()) {
  'overdue_loan' => kLibRed,
  'pickup_request' => const Color(0xFFE29A55),
  'renewal_request' => const Color(0xFF588A73),
  'unread_message' => kLibBrownTitle,
  _ => kLibBrownTitle,
};

String _noticeTime(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}
