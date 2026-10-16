import 'package:flutter/material.dart';

import 'librarian_nav.dart';

class LibrarianPaginationBar extends StatelessWidget {
  const LibrarianPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPrevious,
    required this.onNext,
    this.margin = const EdgeInsets.fromLTRB(11, 4, 11, 10),
  });

  final int page;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final firstItem = totalItems == 0 ? 0 : (page - 1) * pageSize + 1;
    final lastItem = (page * pageSize).clamp(0, totalItems);
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: kLibCardFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Trang trước',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Trang $page/$totalPages',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: kLibBrownTitle,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$firstItem–$lastItem trên $totalItems mục',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Trang sau',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
