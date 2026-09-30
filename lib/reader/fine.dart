import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/reader/reader_nav.dart';

class Fine extends StatefulWidget {
  const Fine({super.key});
  @override
  State<Fine> createState() => _FineState();
}

class _FineState extends State<Fine> {
  List<Map<String, dynamic>> _items = const [];
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
      final data = apiMap(
        await ApiClient.get('/circulation/history', query: {'limit': 100}),
      );
      final all = apiList(data['data']);
      if (mounted) {
        setState(
          () => _items = all
              .where((e) => (num.tryParse('${e['fine_amount']}') ?? 0) > 0)
              .toList(),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        const TitleHeader(
          title: 'Tiền phạt',
          showBack: true,
          color: Colors.white,
        ),
        Expanded(
          child: ApiStateView(
            loading: _loading,
            error: _error,
            isEmpty: _items.isEmpty,
            onRetry: _load,
            emptyMessage: 'Bạn không có khoản phạt nào',
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) {
                final item = _items[i];
                final paid =
                    item['fine_paid'] == true ||
                    item['fine_paid'] == 1 ||
                    item['fine_paid']?.toString() == '1';
                return ListTile(
                  title: Text(apiText(item['book_title'])),
                  subtitle: Text(
                    'Hạn trả: ${apiDate(item['due_date'])}\n'
                    '${paid ? 'Đã thanh toán' : 'Chưa thanh toán'}',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: paid ? const Color(0xFF82D1A8) : kBeigeButton,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${item['fine_amount']} đ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}
