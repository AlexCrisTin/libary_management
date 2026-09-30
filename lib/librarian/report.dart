import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/core/local_image.dart';

import 'librarian_nav.dart';

class Report extends StatefulWidget {
  const Report({super.key, this.transactionId, this.initialLoan});

  final String? transactionId;
  final Map<String, dynamic>? initialLoan;

  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report> {
  final _note = TextEditingController();
  final _fine = TextEditingController();
  List<Map<String, dynamic>> _loans = const [];
  Map<String, dynamic>? _selectedLoan;
  String _reason = 'lost';
  String? _evidenceDataUri;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  @override
  void dispose() {
    _note.dispose();
    _fine.dispose();
    super.dispose();
  }

  Future<void> _loadLoans() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = apiMap(
        await ApiClient.get('/circulation/active', query: {'limit': 100}),
      );
      final loans = apiList(result['data']);
      final initialId =
          widget.transactionId ?? widget.initialLoan?['tx_id']?.toString();
      Map<String, dynamic>? selected = widget.initialLoan;
      if (initialId != null) {
        for (final loan in loans) {
          if (loan['tx_id']?.toString() == initialId) {
            selected = loan;
            break;
          }
        }
      }
      selected ??= loans.isNotEmpty ? loans.first : null;
      if (mounted) {
        _fine.text = _fineValue(selected);
        setState(() {
          _loans = loans;
          _selectedLoan = selected;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fineValue(Map<String, dynamic>? loan) {
    final value = num.tryParse('${loan?['fine_amount'] ?? 0}') ?? 0;
    return value == 0 ? '' : value.toStringAsFixed(0);
  }

  void _selectLoan(Map<String, dynamic> loan) {
    setState(() {
      _selectedLoan = loan;
      _fine.text = _fineValue(loan);
    });
  }

  Future<void> _pickEvidence() async {
    try {
      final value = await pickLocalImageAsDataUri();
      if (value != null && mounted) setState(() => _evidenceDataUri = value);
    } catch (error) {
      _show(error.toString());
    }
  }

  Future<void> _submit() async {
    final loan = _selectedLoan;
    if (loan == null) {
      _show('Vui lòng chọn giao dịch cần báo cáo.');
      return;
    }
    final fine = num.tryParse(_fine.text.trim().replaceAll(',', '')) ?? 0;
    if (fine < 0) {
      _show('Tiền phạt không được nhỏ hơn 0.');
      return;
    }

    setState(() => _submitting = true);
    try {
      String? evidenceUrl;
      final bytes = decodeDataImage(_evidenceDataUri);
      if (bytes != null) {
        final uploaded = apiMap(
          await ApiClient.uploadImage(
            '/uploads/report-evidence',
            bytes: bytes,
            filename: 'minh-chung.jpg',
          ),
        );
        evidenceUrl = uploaded['url']?.toString();
      }

      await ApiClient.put(
        '/circulation/${loan['tx_id']}/report',
        body: {
          'reason': _reason,
          'note': _note.text.trim(),
          'fine_amount': fine,
          'evidence_url': evidenceUrl,
        },
      );
      if (!mounted) return;
      _show('Đã ghi nhận báo cáo.');
      Navigator.pop(context, true);
    } catch (error) {
      _show(error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        const LibTitleHeader(title: 'Báo cáo', showBack: true),
        Expanded(
          child: ApiStateView(
            loading: _loading,
            error: _error,
            isEmpty: _loans.isEmpty,
            onRetry: _loadLoans,
            emptyMessage: 'Không có giao dịch đang mượn để báo cáo',
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 38),
              children: [
                _ReaderLoanCard(
                  loans: _loans,
                  selected: _selectedLoan,
                  onChanged: _selectLoan,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  decoration: BoxDecoration(
                    color: kLibCardFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Lý do báo cáo',
                          style: TextStyle(
                            color: kLibBrownTitle,
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 105,
                          height: 1,
                          margin: const EdgeInsets.only(top: 8, bottom: 18),
                          color: kLibBrownTitle.withValues(alpha: .45),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children:
                            const [
                                  ('lost', 'Làm mất sách'),
                                  ('damaged', 'Làm hỏng sách'),
                                  ('overdue', 'Quá hạn'),
                                  ('other', 'Lý do khác'),
                                ]
                                .map(
                                  (item) => SizedBox(
                                    width: 142,
                                    child: CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      value: _reason == item.$1,
                                      onChanged: (_) =>
                                          setState(() => _reason = item.$1),
                                      activeColor: kLibBrownTitle,
                                      title: Text(
                                        item.$2,
                                        style: const TextStyle(
                                          color: kLibBrownTitle,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 8),
                      const Text('Ghi chú', style: _labelStyle),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _note,
                        minLines: 4,
                        maxLines: 6,
                        decoration: _inputDecoration(),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const SizedBox(
                            width: 105,
                            child: Text('Tiền phạt', style: _labelStyle),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _fine,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(suffixText: 'đ'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 105,
                            child: Text('Minh chứng', style: _labelStyle),
                          ),
                          Expanded(
                            child: _EvidencePicker(
                              dataUri: _evidenceDataUri,
                              onTap: _pickEvidence,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: SizedBox(
                          width: 142,
                          height: 66,
                          child: ElevatedButton.icon(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kLibRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.warning_rounded),
                            label: const Text(
                              'Báo cáo',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

const _labelStyle = TextStyle(
  color: kLibBrownTitle,
  fontSize: 17,
  fontWeight: FontWeight.w700,
);

InputDecoration _inputDecoration({String? suffixText}) => InputDecoration(
  suffixText: suffixText,
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide.none,
  ),
);

class _ReaderLoanCard extends StatelessWidget {
  const _ReaderLoanCard({
    required this.loans,
    required this.selected,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> loans;
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>> onChanged;

  @override
  Widget build(BuildContext context) {
    final loan = selected ?? const <String, dynamic>{};
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 49,
          backgroundColor: kLibBeigeSoft,
          child: Icon(Icons.person, size: 46, color: kLibBrownTitle),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: kLibCardFill,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(
                    color: kLibBeigeButton,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    apiText(loan['reader_name']),
                    style: const TextStyle(
                      color: kLibBrownTitle,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mã độc giả: ${apiText(loan['reader_code'])}',
                        style: _labelStyle.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: ValueKey(loan['tx_id']),
                        value: loan['tx_id']?.toString(),
                        isExpanded: true,
                        decoration: _inputDecoration(),
                        items: loans
                            .map(
                              (item) => DropdownMenuItem(
                                value: item['tx_id']?.toString(),
                                child: Text(
                                  '${apiText(item['book_title'])} • ${apiText(item['reader_code'])}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (id) {
                          if (id == null) return;
                          onChanged(
                            loans.firstWhere(
                              (item) => item['tx_id']?.toString() == id,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text('Ngày mượn: ${apiDate(loan['borrow_date'])}'),
                      Text('Ngày trả: ${apiDate(loan['due_date'])}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EvidencePicker extends StatelessWidget {
  const _EvidencePicker({required this.dataUri, required this.onTap});

  final String? dataUri;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = decodeDataImage(dataUri);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 125,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: bytes == null
            ? const Center(
                child: Icon(
                  Icons.image_rounded,
                  size: 42,
                  color: Color(0xFF435675),
                ),
              )
            : Image.memory(bytes, fit: BoxFit.cover),
      ),
    );
  }
}
