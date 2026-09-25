import 'package:flutter/material.dart';

import 'librarian_nav.dart';

class Report extends StatefulWidget {
  const Report({super.key});

  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report> {
  final _noteController = TextEditingController();
  final _fineController = TextEditingController();

  bool _lostBook = false;
  bool _overdue = false;
  bool _damagedBook = false;
  bool _otherReason = false;

  bool get _hasReason => _lostBook || _overdue || _damagedBook || _otherReason;

  @override
  void dispose() {
    _noteController.dispose();
    _fineController.dispose();
    super.dispose();
  }

  void _submitReport() {
    if (!_hasReason) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một lý do báo cáo'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu báo cáo mẫu'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          LibBeigeHeader(
            child: SizedBox(
              height: 72,
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Quay lại',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Báo cáo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kLibBrownTitle,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
              child: Column(
                children: [
                  const _ReaderAndBookCard(),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
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
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 102,
                            height: 1,
                            margin: const EdgeInsets.only(top: 8, bottom: 14),
                            color: kLibBrownTitle.withValues(alpha: 0.35),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _ReasonCheckbox(
                                label: 'Làm mất sách',
                                value: _lostBook,
                                onChanged: (value) {
                                  setState(() => _lostBook = value);
                                },
                              ),
                            ),
                            Expanded(
                              child: _ReasonCheckbox(
                                label: 'Quá hạn',
                                value: _overdue,
                                onChanged: (value) {
                                  setState(() => _overdue = value);
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _ReasonCheckbox(
                                label: 'Làm hỏng sách',
                                value: _damagedBook,
                                onChanged: (value) {
                                  setState(() => _damagedBook = value);
                                },
                              ),
                            ),
                            Expanded(
                              child: _ReasonCheckbox(
                                label: 'Lý do khác',
                                value: _otherReason,
                                onChanged: (value) {
                                  setState(() => _otherReason = value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Ghi chú', style: _labelStyle),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _noteController,
                          minLines: 5,
                          maxLines: 7,
                          decoration: _inputDecoration(radius: 20),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const SizedBox(
                              width: 88,
                              child: Text('Tiền phạt', style: _labelStyle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: TextField(
                                  controller: _fineController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 88,
                              child: Text('Minh chứng', style: _labelStyle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Chọn ảnh minh chứng'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(7),
                                child: Container(
                                  height: 108,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: const Icon(
                                    Icons.image_rounded,
                                    color: Color(0xFF405170),
                                    size: 42,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Center(
                          child: SizedBox(
                            width: 114,
                            height: 68,
                            child: ElevatedButton(
                              onPressed: _submitReport,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kLibRed,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.all(6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 30),
                                  SizedBox(height: 2),
                                  Text(
                                    'Báo cáo',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
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
}

const _labelStyle = TextStyle(
  color: kLibBrownTitle,
  fontSize: 16,
  fontWeight: FontWeight.w700,
);

InputDecoration _inputDecoration({double radius = 7}) {
  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide.none,
    ),
  );
}

class _ReaderAndBookCard extends StatelessWidget {
  const _ReaderAndBookCard();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: kLibBeigeSoft,
          child: Icon(Icons.person, size: 54, color: kLibBrownTitle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: kLibCardFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: const BoxDecoration(
                    color: kLibBeigeButton,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Trần Ngọc An',
                    style: TextStyle(
                      color: kLibBrownTitle,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Mã độc giả: M1', style: _labelStyle),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Text('Sách', style: _labelStyle),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 32,
                              child: TextField(decoration: _inputDecoration()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Ngày mượn   27/7/2727', style: _labelStyle),
                      const SizedBox(height: 6),
                      const Text('Ngày trả      27/7/2727', style: _labelStyle),
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

class _ReasonCheckbox extends StatelessWidget {
  const _ReasonCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (next) => onChanged(next ?? false),
              activeColor: kLibBrownTitle,
              side: const BorderSide(color: Color(0xFF405170), width: 2.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                style: const TextStyle(
                  color: kLibBrownTitle,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
