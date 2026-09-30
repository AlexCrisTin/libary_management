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
      final items = apiList(await ApiClient.get('/holds/my-holds'));
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel(Map<String, dynamic> item) async {
    final id = apiText(item['hold_id'], fallback: '');
    if (id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đặt trước?'),
        content: Text(
          'Bạn muốn hủy đặt trước “${apiText(item['book_title'])}”?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy đặt trước'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancellingId = id);
    try {
      await ApiClient.put('/holds/$id/cancel');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy yêu cầu đặt trước.')),
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
          title: 'Sách đã đặt trước',
          showBack: true,
          color: Colors.white,
        ),
        Expanded(
          child: ApiStateView(
            loading: _loading,
            error: _error,
            isEmpty: _items.isEmpty,
            onRetry: _load,
            emptyMessage: 'Bạn chưa đặt trước sách nào',
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) => _HoldCard(
                  item: _items[index],
                  cancelling:
                      _cancellingId == _items[index]['hold_id']?.toString(),
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
    final active = status == 'waiting' || status == 'notified';
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
                if (status == 'waiting')
                  Text('Vị trí chờ: ${apiText(item['queue_position'])}'),
                if (status == 'notified')
                  Text('Giữ đến: ${apiDate(item['expires_at'])}'),
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
      'waiting' => ('Đang chờ', kBeigeButton),
      'notified' => ('Có thể nhận', const Color(0xFF82D1A8)),
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
