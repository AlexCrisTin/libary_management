import 'package:flutter/material.dart';
import 'package:libary_management/reader/reader_nav.dart';

class SeeBorrowBook extends StatelessWidget {
  const SeeBorrowBook({super.key, this.onOpenSearch});

  final VoidCallback? onOpenSearch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchHeaderBar(
          readOnly: true,
          onTap: onOpenSearch,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: CalendarDatePicker(
                  initialDate: DateTime(2025, 10, 15),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  onDateChanged: (_) {},
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sách đang mượn',
                style: TextStyle(
                  color: kBrownTitle,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              const _BorrowedBookCard(),
            ],
          ),
        ),
      ],
    );
  }
}

class _BorrowedBookCard extends StatelessWidget {
  const _BorrowedBookCard();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BookCover(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Toán cao cấp',
                style: TextStyle(
                  color: kBookTitle,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ngày mượn: 27/7/2727',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
              const Text(
                'Ngày trả: 27/7/2727',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBeigeButton,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Trả sách',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBeigeButton,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Gia hạn',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
