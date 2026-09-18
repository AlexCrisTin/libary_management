import 'package:flutter/material.dart';
import 'package:libary_management/reader/reader_nav.dart';
import 'package:libary_management/reader/reader_routes.dart';
import 'package:libary_management/reader/message.dart';
import 'package:libary_management/reader/qr_scanner.dart';

class DetailBook extends StatelessWidget {
  const DetailBook({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: ChatFab(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Message()),
        ),
      ),
      bottomNavigationBar: ReaderBottomBar(
        currentIndex: 0,
        onSelect: (i) => openReaderTab(context, i),
        onScan: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QrScanner()),
        ),
      ),
      body: Column(
        children: [
          TitleHeader(
            title: 'Thông tin sách',
            showBack: true,
            trailing: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.bookmark_border, color: Colors.white),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                const Center(child: BookCover(width: 168, height: 253)),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: 151,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBeigeButton,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Mượn',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Thông tin sách',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kBookTitle,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tên sách: Toán cao cấp',
                            style: TextStyle(
                              color: kBookTitle,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tác giả: Lê Trọng Lang',
                            style: TextStyle(
                              color: kBookTitle,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Năm xuất bản: 2023',
                            style: TextStyle(
                              color: kBookTitle,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Nhà xuất bản: Long Tuất',
                            style: TextStyle(
                              color: kBookTitle,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Thể loại: Sách giáo khoa',
                            style: TextStyle(
                              color: kBookTitle,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Mô tả: Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut...',
                            style: TextStyle(
                              color: kBookTitle,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 113,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD18282),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'Số người đang mượn',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: kBookTitle,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Icon(Icons.groups, color: Colors.white, size: 36),
                          SizedBox(height: 8),
                          Text(
                            '0/10',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
