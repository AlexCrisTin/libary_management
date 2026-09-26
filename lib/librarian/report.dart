import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';

import 'librarian_nav.dart';

class Report extends StatefulWidget {
  const Report({super.key, this.transactionId});
  final String? transactionId;
  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report> {
  late final TextEditingController _transaction = TextEditingController(
    text: widget.transactionId ?? '',
  );
  bool _lost = false;
  bool _loading = false;
  @override
  void dispose() {
    _transaction.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_lost || _transaction.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhập mã giao dịch và chọn “Làm mất sách”.'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiClient.put('/circulation/${_transaction.text.trim()}/lost');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã ghi nhận sách bị mất.')));
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        const LibTitleHeader(title: 'Báo cáo', showBack: true),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kLibCardFill,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _transaction,
                      decoration: const InputDecoration(
                        labelText: 'Mã giao dịch',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: _lost,
                      onChanged: (v) => setState(() => _lost = v ?? false),
                      title: const Text('Làm mất sách'),
                      activeColor: kLibBrownTitle,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Backend hiện chỉ có API ghi nhận mất sách; các loại báo cáo khác chưa được hỗ trợ.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kLibRed,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.warning_amber),
                      label: const Text('Báo cáo'),
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
