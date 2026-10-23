import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/core/local_image.dart';
import 'package:libary_management/reader/reader_nav.dart';

class ReaderHolds extends StatefulWidget {
  const ReaderHolds({super.key});

  @override
  State<ReaderHolds> createState() => _ReaderHoldsState();
}

class _ReaderHoldsState extends State<ReaderHolds> {
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _error;
  String? _cancellingId;

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
      final responses = await Future.wait([
        ApiClient.get('/holds/my-holds'),
        ApiClient.get('/pickup-reservations/my-reservations'),
      ]);
      final queueHolds = apiList(
        responses[0],
      ).map((item) => {...item, '_reservation_kind': 'queue'}).toList();
      final pickupSlots = apiList(
        responses[1],
      ).map((item) => {...item, '_reservation_kind': 'pickup'}).toList();
      final items = [...queueHolds, ...pickupSlots]
        ..sort((a, b) {
          final aDate = DateTime.tryParse('${a['requested_at']}');
          final bDate = DateTime.tryParse('${b['requested_at']}');
          return (bDate ?? DateTime(1970)).compareTo(aDate ?? DateTime(1970));
        });
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel(Map<String, dynamic> item) async {
    final pickup = item['_reservation_kind'] == 'pickup';
    final id = apiText(
      pickup ? item['reservation_id'] : item['hold_id'],
      fallback: '',
    );
    if (id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pickup ? 'Hủy đặt slot?' : 'Hủy báo khi có?'),
        content: Text(
          'Bạn muốn hủy ${pickup ? 'đặt slot' : 'báo khi có'} '
          '“${apiText(item['book_title'])}”?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(pickup ? 'Hủy đặt slot' : 'Hủy báo khi có'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancellingId = id);
    try {
      await ApiClient.put(
        pickup ? '/pickup-reservations/$id/cancel' : '/holds/$id/cancel',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pickup ? 'Đã hủy yêu cầu đặt slot.' : 'Đã hủy báo khi có.',
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
      if (mounted) setState(() => _cancellingId = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        const TitleHeader(
          title: 'Đăng ký sách',
          showBack: true,
          color: Colors.white,
        ),
        Expanded(
          child: ApiStateView(
            loading: _loading,
            error: _error,
            isEmpty: _items.isEmpty,
            onRetry: _load,
            emptyMessage: 'Bạn chưa có đăng ký sách nào',
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) => _HoldCard(
                  item: _items[index],
                  cancelling:
                      _cancellingId ==
                      (_items[index]['reservation_id'] ??
                              _items[index]['hold_id'])
                          ?.toString(),
                  onCancel: () => _cancel(_items[index]),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _HoldCard extends StatelessWidget {
  const _HoldCard({
    required this.item,
    required this.cancelling,
    required this.onCancel,
  });

  final Map<String, dynamic> item;
  final bool cancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final status = item['status']?.toString() ?? '';
    final pickup = item['_reservation_kind'] == 'pickup';
    final active = pickup
        ? status == 'pending' || status == 'approved'
        : status == 'waiting' || status == 'notified';
    final cover = item['cover_url']?.toString() ?? '';
    final bytes = decodeDataImage(cover);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 78,
              height: 108,
              child: bytes != null
                  ? Image.memory(bytes, fit: BoxFit.cover)
                  : cover.isNotEmpty
                  ? Image.network(
                      apiAssetUrl(cover),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  apiText(item['book_title']),
                  style: const TextStyle(
                    color: kBookTitle,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text('ISBN: ${apiText(item['isbn'])}'),
                Text('Ngày đặt: ${apiDate(item['requested_at'])}'),
                if (!pickup && status == 'waiting')
                  Text('Báo khi có đến: ${apiDate(item['expires_at'])}'),
                if (!pickup && status == 'notified')
                  Text('Đặt slot trước: ${apiDate(item['expires_at'])}'),
                if (pickup && status == 'pending')
                  const Text('Đang chờ thủ thư xác nhận slot'),
                if (pickup && status == 'approved') ...[
                  Text('Nhận trước: ${_dateTime(item['pickup_expires_at'])}'),
                  Text('Mã bản sách: ${apiText(item['barcode'])}'),
                ],
                if (pickup && status == 'rejected')
                  Text('Lý do: ${apiText(item['rejection_reason'])}'),
                const SizedBox(height: 9),
                Row(
                  children: [
                    _StatusChip(status: status),
                    const Spacer(),
                    if (active)
                      TextButton(
                        onPressed: cancelling ? null : onCancel,
                        child: cancelling
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Hủy'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    color: kBeigeSoft,
    child: const Icon(Icons.menu_book_rounded, color: kBrownTitle, size: 38),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'waiting' => ('Chờ thông báo', kBeigeButton),
      'notified' => ('Có sách • đặt slot', const Color(0xFF82D1A8)),
      'pending' => ('Chờ duyệt slot', kBeigeButton),
      'approved' => ('Đã giữ sách', const Color(0xFF82D1A8)),
      'rejected' => ('Bị từ chối', const Color(0xFFD18282)),
      'fulfilled' => ('Đã nhận', const Color(0xFF82D1A8)),
      'cancelled' => ('Đã hủy', const Color(0xFFD18282)),
      'expired' => ('Hết hạn', const Color(0xFFD18282)),
      _ => (status, kBeigeButton),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _dateTime(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '—';
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(date.hour)}:${two(date.minute)} '
      '${two(date.day)}/${two(date.month)}/${date.year}';
}
