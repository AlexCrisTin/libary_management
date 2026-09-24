import 'package:flutter/material.dart';
import 'librarian_nav.dart';
import 'borrow_return_detail.dart';

class BorrowReturnBookManagement extends StatelessWidget {
  const BorrowReturnBookManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            LibTitleHeader(title: 'Quản lý mượn / trả'),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm...',
                        hintStyle: TextStyle(
                          color: Colors.black.withValues(alpha: 0.25),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            width: 3,
                            color: Color(0xFFDDDDDD),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            width: 3,
                            color: Color(0xFFDDDDDD),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: kLibBrownTitle),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Table header
            Container(
              margin: const EdgeInsets.fromLTRB(11, 8, 11, 0),
              height: 44,
              decoration: ShapeDecoration(
                color: kLibBeigeButton,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 8),
                  Expanded(flex: 2, child: Text('Độc giả', style: _hStyle)),
                  Expanded(flex: 2, child: Text('Sách', style: _hStyle)),
                  Expanded(flex: 2, child: Text('Ngày mượn', style: _hStyle)),
                  Expanded(flex: 2, child: Text('Ngày trả', style: _hStyle)),
                  Expanded(flex: 2, child: Text('Chi tiết', style: _hStyle)),
                ],
              ),
            ),
            // Borrow list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(11, 6, 11, 8),
                itemCount: _sampleBorrows.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final b = _sampleBorrows[i];
                  return _BorrowRow(
                    borrow: b,
                    onDetailTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BorrowReturnDetail(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const TextStyle _hStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
  );
}

class _BorrowData {
  const _BorrowData(this.reader, this.book, this.borrowDate, this.returnDate);
  final String reader, book, borrowDate, returnDate;
}

const _sampleBorrows = [
  _BorrowData('Trần Ngọc An', 'Toán CC', '01/01/2727', '27/7/2727'),
  _BorrowData('Nguyễn Văn B', 'Vật lý', '05/01/2727', '20/7/2727'),
];

class _BorrowRow extends StatelessWidget {
  const _BorrowRow({required this.borrow, this.onDetailTap});
  final _BorrowData borrow;
  final VoidCallback? onDetailTap;

  @override
  Widget build(BuildContext context) {
    const ts = TextStyle(
      color: kLibBrownTitle,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(borrow.reader, style: ts)),
          Expanded(flex: 2, child: Text(borrow.book, style: ts)),
          Expanded(flex: 2, child: Text(borrow.borrowDate, style: ts)),
          Expanded(flex: 2, child: Text(borrow.returnDate, style: ts)),
          Expanded(
            flex: 2,
            child: Center(
              child: GestureDetector(
                onTap: onDetailTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kLibBeigeButton,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
