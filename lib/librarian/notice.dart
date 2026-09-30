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
        await ApiClient.get('/notifications/all', query: {'limit': 200}),
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
        const LibTitleHeader(title: 'Thông báo độc giả', showBack: true),
        Expanded(
          child: ApiStateView(
            loading: _loading,
            error: _error,
            isEmpty: _notices.isEmpty,
            onRetry: _load,
            emptyMessage: 'Chưa có thông báo độc giả',
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
    final read =
        notice['is_read'] == true ||
        notice['is_read'] == 1 ||
        notice['is_read']?.toString() == '1';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: read ? kLibCardFill : kLibBeigeSoft,
        borderRadius: BorderRadius.circular(14),
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
                    if (!read)
                      const CircleAvatar(radius: 4, backgroundColor: kLibRed),
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
  'due_soon' => Icons.schedule_rounded,
  'overdue' => Icons.warning_amber_rounded,
  'hold_available' => Icons.bookmark_added_rounded,
  'card_expired' => Icons.credit_card_off_rounded,
  _ => Icons.notifications_rounded,
};

String _noticeTime(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}
