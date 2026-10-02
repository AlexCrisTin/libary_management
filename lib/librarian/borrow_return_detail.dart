import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/local_image.dart';

import 'librarian_nav.dart';
import 'message_detail.dart';
import 'report.dart';

class BorrowReturnDetail extends StatefulWidget {
  const BorrowReturnDetail({super.key, required this.loan});
  final Map<String, dynamic> loan;
  @override
  State<BorrowReturnDetail> createState() => _BorrowReturnDetailState();
}

class _BorrowReturnDetailState extends State<BorrowReturnDetail> {
  bool _loading = false;
  Future<void> _renew(String tx) async {
    var days = 7;
    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Gia hạn sách'),
          content: DropdownButtonFormField<int>(
            value: days,
            decoration: const InputDecoration(
              labelText: 'Số ngày gia hạn',
              helperText: 'Tối đa 7 ngày',
              border: OutlineInputBorder(),
            ),
            items: [
              for (var value = 1; value <= 7; value++)
                DropdownMenuItem(value: value, child: Text('$value ngày')),
            ],
            onChanged: (value) {
              if (value != null) setDialogState(() => days = value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, days),
              style: FilledButton.styleFrom(backgroundColor: kLibGreen),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _loading = true);
    try {
      await ApiClient.post(
        '/circulation/renew/$tx',
        body: {'extend_days': selected},
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Đã gia hạn thêm $selected ngày.')),
      );
      navigator.pop(true);
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _payFine(String tx) async {
    setState(() => _loading = true);
    try {
      await ApiClient.put('/circulation/$tx/pay-fine');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xác nhận thu tiền phạt.')),
      );
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

  Future<void> _returnBook(String tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận trả sách'),
        content: const Text('Bạn muốn xác nhận độc giả đã trả cuốn sách này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await ApiClient.post('/circulation/return', body: {'tx_id': tx});
      if (!mounted) return;
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

  Future<void> _openReport(String tx) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => Report(transactionId: tx, initialLoan: widget.loan),
      ),
    );
    if (changed == true && mounted) Navigator.of(context).pop(true);
  }

  void _openMessage() {
    final readerId = apiText(widget.loan['reader_id'], fallback: '');
    if (readerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy mã độc giả để nhắn tin.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessageDetail(
          readerId: readerId,
          readerName: apiText(widget.loan['reader_name'], fallback: 'Độc giả'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final tx = apiText(loan['tx_id'], fallback: '');
    final fineAmount = num.tryParse('${loan['fine_amount'] ?? 0}') ?? 0;
    final finePaid =
        loan['fine_paid'] == true ||
        loan['fine_paid'] == 1 ||
        loan['fine_paid']?.toString() == '1';
    final status = loan['status']?.toString();
    final active = status == 'borrowed' || status == 'overdue';
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const LibTitleHeader(title: 'Chi tiết', showBack: true),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
              children: [
                Center(child: _BookCover(url: loan['cover_url']?.toString())),
                const SizedBox(height: 28),
                _InformationCard(
                  loan: loan,
                  active: active,
                  loading: _loading,
                  showPayFine: fineAmount > 0 && !finePaid,
                  onRenew: () => _renew(tx),
                  onReturn: () => _returnBook(tx),
                  onReport: () => _openReport(tx),
                  onPayFine: () => _payFine(tx),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Material(
                    color: kLibBeigeSoft,
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Nhắn tin với độc giả',
                      onPressed: _openMessage,
                      padding: const EdgeInsets.all(22),
                      icon: const Icon(
                        Icons.chat_bubble_rounded,
                        color: kLibBrownTitle,
                        size: 31,
                      ),
                    ),
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

class _BookCover extends StatelessWidget {
  const _BookCover({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final value = url?.trim() ?? '';
    final Uint8List? bytes = decodeDataImage(value);
    final image = bytes != null
        ? Image.memory(bytes, fit: BoxFit.cover)
        : value.isNotEmpty
        ? Image.network(
            apiAssetUrl(value),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _CoverPlaceholder(),
          )
        : const _CoverPlaceholder();
    return Container(
      width: 184,
      height: 254,
      decoration: BoxDecoration(
        color: kLibCardFill,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: kLibCardFill,
    child: Center(
      child: Icon(Icons.menu_book_rounded, color: kLibBrownTitle, size: 62),
    ),
  );
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({
    required this.loan,
    required this.active,
    required this.loading,
    required this.showPayFine,
    required this.onRenew,
    required this.onReturn,
    required this.onReport,
    required this.onPayFine,
  });

  final Map<String, dynamic> loan;
  final bool active;
  final bool loading;
  final bool showPayFine;
  final VoidCallback onRenew;
  final VoidCallback onReturn;
  final VoidCallback onReport;
  final VoidCallback onPayFine;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: kLibCardFill,
      borderRadius: BorderRadius.circular(20),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          color: kLibBeigeButton,
          child: const Text(
            'Thông tin sách và người mượn',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF3F4655),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          child: Column(
            children: [
              _InfoRow(label: 'Sách', value: loan['book_title']),
              _InfoRow(label: 'Mã', value: loan['barcode'] ?? loan['tx_id']),
              _InfoRow(label: 'Người mượn', value: loan['reader_name']),
              _InfoRow(label: 'Mã độc giả', value: loan['reader_code']),
              _InfoRow(label: 'Ngày mượn', value: apiDate(loan['borrow_date'])),
              _InfoRow(label: 'Ngày trả', value: apiDate(loan['due_date'])),
              _InfoRow(
                label: 'Ghi chú',
                value: loan['notes'],
                fallback: 'Không có',
              ),
              _InfoRow(
                label: 'Tình trạng',
                value: _statusLabel(loan['status']),
              ),
              if ((num.tryParse('${loan['fine_amount'] ?? 0}') ?? 0) > 0)
                _InfoRow(
                  label: 'Tiền phạt',
                  value: '${loan['fine_amount']} VNĐ',
                ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Gia hạn',
                      icon: Icons.library_books_rounded,
                      color: kLibGreen,
                      onPressed: active && !loading ? onRenew : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _ActionButton(
                      label: 'Báo cáo',
                      icon: Icons.warning_amber_rounded,
                      color: kLibRed,
                      onPressed: loading ? null : onReport,
                    ),
                  ),
                ],
              ),
              if (active) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _ActionButton(
                    label: 'Xác nhận trả sách',
                    icon: Icons.assignment_return_rounded,
                    color: kLibBeigeButton,
                    onPressed: loading ? null : onReturn,
                  ),
                ),
              ],
              if (showPayFine) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _ActionButton(
                    label: 'Thu tiền phạt',
                    icon: Icons.payments_outlined,
                    color: kLibBrownTitle,
                    onPressed: loading ? null : onPayFine,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.fallback = '—',
  });

  final String label;
  final dynamic value;
  final String fallback;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: Color(0xFFC65E62),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            apiText(value, fallback: fallback),
            style: const TextStyle(
              color: kLibBookTitle,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 72,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withValues(alpha: .45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      icon: Icon(icon, size: 27),
      label: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

String _statusLabel(dynamic value) {
  switch (value?.toString()) {
    case 'borrowed':
      return 'Đang mượn';
    case 'overdue':
      return 'Quá hạn';
    case 'returned':
      return 'Đã trả';
    case 'lost':
      return 'Làm mất';
    case 'damaged':
      return 'Hư hỏng';
    default:
      return apiText(value);
  }
}
