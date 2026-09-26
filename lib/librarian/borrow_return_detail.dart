import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';

import 'librarian_nav.dart';

class BorrowReturnDetail extends StatefulWidget {
  const BorrowReturnDetail({super.key, required this.loan});
  final Map<String, dynamic> loan;
  @override
  State<BorrowReturnDetail> createState() => _BorrowReturnDetailState();
}

class _BorrowReturnDetailState extends State<BorrowReturnDetail> {
  bool _loading = false;
  Future<void> _action(String path, String success) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _loading = true);
    try {
      await ApiClient.post(path);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(success)));
      navigator.pop(true);
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final tx = apiText(loan['tx_id'], fallback: '');
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const LibTitleHeader(title: 'Chi tiết', showBack: true),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kLibCardFill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Thông tin sách và người mượn',
                          style: TextStyle(
                            color: kLibBrownTitle,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _row('Sách', loan['book_title']),
                      _row('Mã giao dịch', loan['tx_id']),
                      _row('Người mượn', loan['reader_name']),
                      _row('Mã độc giả', loan['reader_code']),
                      _row('Ngày mượn', apiDate(loan['borrow_date'])),
                      _row('Ngày trả', apiDate(loan['due_date'])),
                      _row('Tình trạng', loan['status']),
                      _row('Tiền phạt', loan['fine_amount']),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _loading
                                  ? null
                                  : () => _action(
                                      '/circulation/renew/$tx',
                                      'Gia hạn thành công',
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kLibGreen,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.library_books),
                              label: const Text('Gia hạn'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _loading
                                  ? null
                                  : () async {
                                      final navigator = Navigator.of(context);
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      setState(() => _loading = true);
                                      try {
                                        await ApiClient.post(
                                          '/circulation/return',
                                          body: {'tx_id': tx},
                                        );
                                        if (!mounted) return;
                                        navigator.pop(true);
                                      } catch (error) {
                                        if (mounted) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(error.toString()),
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => _loading = false);
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kLibBeigeButton,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.assignment_return),
                              label: const Text('Trả sách'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, dynamic value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      '$label: ${apiText(value)}',
      style: const TextStyle(
        color: kLibBookTitle,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
