import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/reader/reader_nav.dart';

class Notice extends StatefulWidget {
  const Notice({super.key});

  @override
  State<Notice> createState() => _NoticeState();
}

class _NoticeState extends State<Notice> {
  List<Map<String, dynamic>> _notices = const [];
  bool _loading = true;
  bool _markingAll = false;
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
        await ApiClient.get('/notifications', query: {'limit': 100}),
      );
      if (mounted) setState(() => _notices = apiList(result['data']));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(Map<String, dynamic> notice) async {
    if (_isRead(notice)) return;
    final id = apiText(notice['notification_id'], fallback: '');
    if (id.isEmpty) return;
    try {
      await ApiClient.put('/notifications/$id/read');
      if (mounted) setState(() => notice['is_read'] = 1);
    } catch (error) {
      if (mounted) _show(error.toString());
    }
  }

  Future<void> _markAllRead() async {
    if (_markingAll || !_notices.any((item) => !_isRead(item))) return;
    setState(() => _markingAll = true);
    try {
      await ApiClient.put('/notifications/read-all');
      if (mounted) {
        setState(() {
          for (final item in _notices) {
            item['is_read'] = 1;
          }
        });
      }
    } catch (error) {
      if (mounted) _show(error.toString());
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<bool> _delete(Map<String, dynamic> notice) async {
    final id = apiText(notice['notification_id'], fallback: '');
    if (id.isEmpty) return false;
    try {
      await ApiClient.delete('/notifications/$id');
      return true;
    } catch (error) {
      if (mounted) _show(error.toString());
      return false;
    }
  }

  bool _isRead(Map<String, dynamic> notice) {
    final value = notice['is_read'];
    return value == true || value == 1 || value?.toString() == '1';
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notices.where((item) => !_isRead(item)).length;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          TitleHeader(
            title: 'Thông báo',
            showBack: true,
            trailing: unread == 0
                ? null
                : IconButton(
                    tooltip: 'Đánh dấu tất cả đã đọc',
                    onPressed: _markingAll ? null : _markAllRead,
                    icon: _markingAll
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.done_all, color: Colors.white),
                  ),
          ),
          Expanded(
            child: ApiStateView(
              loading: _loading,
              error: _error,
              isEmpty: _notices.isEmpty,
              onRetry: _load,
              emptyMessage: 'Chưa có thông báo',
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  itemCount: _notices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final notice = _notices[index];
                    return Dismissible(
                      key: ValueKey(notice['notification_id']),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => _delete(notice),
                      onDismissed: (_) => setState(
                        () => _notices.removeWhere(
                          (item) =>
                              item['notification_id']?.toString() ==
                              notice['notification_id']?.toString(),
                        ),
                      ),
                      background: Container(
                        padding: const EdgeInsets.only(right: 22),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD18282),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: _NoticeTile(
                        notice: notice,
                        read: _isRead(notice),
                        onTap: () => _markRead(notice),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({
    required this.notice,
    required this.read,
    required this.onTap,
  });

  final Map<String, dynamic> notice;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: read ? kCardFill : kBeigeSoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: read ? Colors.white : kBeigeButton,
                child: Icon(_noticeIcon(notice['type']), color: kBrownTitle),
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
                            apiText(notice['title'], fallback: 'Thông báo'),
                            style: const TextStyle(
                              color: kBookTitle,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!read)
                          const CircleAvatar(
                            radius: 4,
                            backgroundColor: Color(0xFFD18282),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      apiText(notice['content']),
                      style: const TextStyle(color: kBrownTitle, height: 1.35),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _noticeTime(notice['created_at']),
                      style: TextStyle(
                        color: kBrownTitle.withValues(alpha: .6),
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

IconData _noticeIcon(dynamic type) {
  switch (type?.toString()) {
    case 'due_soon':
    case 'overdue':
      return Icons.schedule_rounded;
    case 'hold_available':
      return Icons.bookmark_added_rounded;
    case 'card_expired':
      return Icons.credit_card_off_rounded;
    default:
      return Icons.notifications_rounded;
  }
}

String _noticeTime(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}
