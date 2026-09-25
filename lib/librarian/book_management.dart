import 'package:flutter/material.dart';
import 'librarian_nav.dart';
import 'detail_book.dart';
import 'form_addbook.dart';

class BookManagement extends StatelessWidget {
  const BookManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            LibTitleHeader(
              title: 'Quản lý sách',
              trailing: IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FormAddBook()),
                ),
              ),
            ),
            // Search + filter
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
            // Action buttons row
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 8, 11, 0),
              child: Row(
                children: [
                  // Delete
                  _actionBtn(
                    icon: Icons.delete_outline,
                    color: const Color(0xFFFC5F5F),
                    onTap: () {},
                  ),
                  const Spacer(),
                  // Add
                  _actionBtn(
                    icon: Icons.add,
                    color: kLibBeigeButton,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FormAddBook()),
                    ),
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
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Sách', style: _headerStyle),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text('Trạng thái', style: _headerStyle),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text('Số lượng', style: _headerStyle),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text('Chi tiết', style: _headerStyle),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Book list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(11, 6, 11, 8),
                itemCount: _sampleBooks.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final book = _sampleBooks[i];
                  return _BookRow(
                    book: book,
                    onDetailTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DetailBook()),
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

  static const TextStyle _headerStyle = TextStyle(
    color: Colors.white,
    fontSize: 13,
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
  );

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 43,
        decoration: ShapeDecoration(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

// ─── Sample data ──────────────────────────────────────────────────────────────
class _BookData {
  const _BookData(this.title, this.available, this.total);
  final String title;
  final int available;
  final int total;
}

const _sampleBooks = [
  _BookData('Toán cao cấp', 9, 10),
  _BookData('Vật lý đại cương', 5, 8),
  _BookData('Lập trình Flutter', 3, 5),
];

// ─── Row widget ───────────────────────────────────────────────────────────────
class _BookRow extends StatelessWidget {
  const _BookRow({required this.book, this.onDetailTap});

  final _BookData book;
  final VoidCallback? onDetailTap;

  @override
  Widget build(BuildContext context) {
    final isAvailable = book.available > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              book.title,
              style: const TextStyle(
                color: kLibBookTitle,
                fontSize: 13,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? const Color(0xFFC2E2B5)
                      : const Color(0xFFFFCDD2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isAvailable ? 'Còn' : 'Hết',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: kLibBookTitle,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                '${book.available}/${book.total}',
                style: const TextStyle(
                  color: kLibBookTitle,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
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
                    size: 20,
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
