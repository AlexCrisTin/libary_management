import 'package:flutter/material.dart';
import 'package:libary_management/reader/detailbook.dart';
import 'package:libary_management/reader/reader_nav.dart';

class AllBook extends StatelessWidget {
  const AllBook({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SearchHeaderBar(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: 6,
            separatorBuilder: (_, __) => const Divider(height: 28),
            itemBuilder: (context, index) => _BookListItem(
              title: index.isEven ? 'Toán cao cấp' : 'Lập trình Flutter',
              author: index.isEven ? 'Lê Trọng Lang' : 'Nhóm tác giả Flutter',
            ),
          ),
        ),
      ],
    );
  }
}

class _BookListItem extends StatelessWidget {
  const _BookListItem({required this.title, required this.author});

  final String title;
  final String author;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DetailBook()),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BookCover(width: 72, height: 108),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kBookTitle,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Tác giả: $author', style: const TextStyle(color: kMuted)),
                const SizedBox(height: 4),
                const Text(
                  'Thể loại: Sách giáo khoa',
                  style: TextStyle(color: kMuted),
                ),
                const SizedBox(height: 10),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
