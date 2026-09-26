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
  List<Map<String, dynamic>> _readers = const [];
  List<Map<String, dynamic>> _notices = const [];
  String? _readerId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReaders();
  }

  Future<void> _loadReaders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = apiMap(
        await ApiClient.get('/readers', query: {'limit': 100}),
      );
      final readers = apiList(result['items']);
      final selected =
          _readerId ??
          (readers.isEmpty ? null : readers.first['reader_id']?.toString());
      if (!mounted) return;
      setState(() {
        _readers = readers;
        _readerId = selected;
      });
      if (selected != null) await _loadNotices(selected, showLoading: false);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadNotices(String readerId, {bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = apiMap(
        await ApiClient.get(
          '/notifications',
          query: {'reader_id': readerId, 'limit': 100},
        ),
      );
      if (mounted) setState(() => _notices = apiList(result['data']));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (showLoading && mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const LibTitleHeader(title: 'Thông báo', showBack: true),
          if (_readers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
              child: DropdownButtonFormField<String>(
                value: _readerId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Thông báo của độc giả',
                  filled: true,
                  fillColor: kLibCardFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _readers
                    .map(
                      (reader) => DropdownMenuItem(
                        value: reader['reader_id']?.toString(),
                        child: Text(
                          '${apiText(reader['full_name'])} • '
                          '${apiText(reader['reader_code'])}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _readerId = value);
                  _loadNotices(value);
                },
              ),
            ),
          Expanded(
            child: ApiStateView(
              loading: _loading,
              error: _error,
              isEmpty: _readers.isEmpty || _notices.isEmpty,
              onRetry: _loadReaders,
              emptyMessage: _readers.isEmpty
                  ? 'Chưa có độc giả trong hệ thống'
                  : 'Độc giả này chưa có thông báo',
              child: RefreshIndicator(
                onRefresh: () => _readerId == null
                    ? _loadReaders()
                    : _loadNotices(_readerId!),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
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
            child: Icon(
              read ? Icons.notifications_none : Icons.notifications_active,
              color: kLibBrownTitle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

String _noticeTime(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}
