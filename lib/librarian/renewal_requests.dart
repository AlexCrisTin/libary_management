import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';

import 'librarian_nav.dart';

class RenewalRequests extends StatefulWidget {
  const RenewalRequests({super.key});

  @override
  State<RenewalRequests> createState() => _RenewalRequestsState();
}

class _RenewalRequestsState extends State<RenewalRequests> {
  List<Map<String, dynamic>> _requests = const [];
  bool _loading = true;
  String? _error;
  String? _processingId;

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
        await ApiClient.get(
          '/circulation/renew-requests',
          query: {'status': 'pending'},
        ),
      );
      if (mounted) setState(() => _requests = apiList(result['data']));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(Map<String, dynamic> request) async {
    var days = (int.tryParse('${request['requested_days'] ?? 7}') ?? 7).clamp(
      1,
      7,
    );
    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Duyệt gia hạn'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                apiText(request['book_title']),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text('Độc giả: ${apiText(request['reader_name'])}'),
              const SizedBox(height: 18),
              DropdownButtonFormField<int>(
                value: days,
                decoration: const InputDecoration(
                  labelText: 'Số ngày gia hạn',
                  border: OutlineInputBorder(),
                  helperText: 'Tối đa 7 ngày',
                ),
                items: [
                  for (var value = 1; value <= 7; value++)
                    DropdownMenuItem(value: value, child: Text('$value ngày')),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => days = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, days),
              style: FilledButton.styleFrom(backgroundColor: kLibGreen),
              child: const Text('Duyệt'),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await _resolve(request, action: 'approve', days: selected);
  }

  Future<void> _reject(Map<String, dynamic> request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Từ chối gia hạn?'),
        content: Text(
          'Yêu cầu gia hạn “${apiText(request['book_title'])}” sẽ bị từ chối.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: kLibRed),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _resolve(request, action: 'reject');
    }
  }

  Future<void> _resolve(
    Map<String, dynamic> request, {
    required String action,
    int? days,
  }) async {
    final id = apiText(request['request_id'], fallback: '');
    if (id.isEmpty || _processingId != null) return;
    setState(() => _processingId = id);
    try {
      await ApiClient.put(
        '/circulation/renew-requests/$id',
        body: {'action': action, if (days != null) 'extend_days': days},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'approve'
                ? 'Đã duyệt gia hạn thêm $days ngày.'
                : 'Đã từ chối yêu cầu gia hạn.',
          ),
        ),
      );
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        LibTitleHeader(
          title: 'Duyệt gia hạn',
          showBack: true,
          trailing: IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ),
        Expanded(
          child: ApiStateView(
            loading: _loading,
            error: _error,
            isEmpty: _requests.isEmpty,
            onRetry: _load,
            emptyMessage: 'Không có yêu cầu gia hạn đang chờ duyệt',
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) {
                  final request = _requests[index];
                  final processing =
                      _processingId == request['request_id']?.toString();
                  return Card(
                    color: kLibCardFill,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            apiText(request['book_title']),
                            style: const TextStyle(
                              color: kLibBookTitle,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${apiText(request['reader_name'])} • '
                            '${apiText(request['reader_code'])}',
                          ),
                          Text('Barcode: ${apiText(request['barcode'])}'),
                          Text('Hạn hiện tại: ${apiDate(request['due_date'])}'),
                          Text(
                            'Độc giả đề nghị: '
                            '${apiText(request['requested_days'])} ngày',
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: processing
                                      ? null
                                      : () => _reject(request),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: kLibRed,
                                  ),
                                  child: const Text('Từ chối'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton(
                                  onPressed: processing
                                      ? null
                                      : () => _approve(request),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: kLibGreen,
                                  ),
                                  child: processing
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Duyệt'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
