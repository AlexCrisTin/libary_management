import 'package:flutter/material.dart';
import 'package:libary_management/reader/allbook.dart';
import 'package:libary_management/reader/detailbook.dart';
import 'package:libary_management/reader/message.dart';
import 'package:libary_management/reader/profile.dart';
import 'package:libary_management/reader/qr_scanner.dart';
import 'package:libary_management/reader/reader_nav.dart';
import 'package:libary_management/reader/notice.dart';
import 'package:libary_management/reader/seeborrowbook.dart';

class Home extends StatefulWidget {
  const Home({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeContent(
        onOpenSearch: () => setState(() => _index = 1),
        onOpenNotice: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Notice()),
          );
        },
      ),
      const AllBook(),
      const SizedBox.shrink(),
      SeeBorrowBook(onOpenSearch: () => setState(() => _index = 1)),
      const Profile(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: pages[_index],
      floatingActionButton: _index < 4
          ? ChatFab(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Message()),
              ),
            )
          : null,
      bottomNavigationBar: ReaderBottomBar(
        currentIndex: _index,
        onSelect: (i) => setState(() => _index = i),
        onScan: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QrScanner()),
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key, this.onOpenSearch, this.onOpenNotice});

  final VoidCallback? onOpenSearch;
  final VoidCallback? onOpenNotice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchHeaderBar(
          readOnly: true,
          onTap: onOpenSearch,
          trailing: IconButton(
            onPressed: onOpenNotice,
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const Text(
                'Sách đang hot',
                style: TextStyle(
                  color: kBrownTitle,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DetailBook()),
                        );
                      },
                      child: const Column(
                        children: [
                          BookCover(width: 113, height: 169),
                          SizedBox(height: 8),
                          Text(
                            'Toán cao cấp',
                            style: TextStyle(
                              color: kBookTitle,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Khám phá chủ đề',
                style: TextStyle(
                  color: kBrownTitle,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sách giáo khoa',
                style: TextStyle(
                  color: Color(0xFFBC5F5F),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const _TopicBookCard(),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopicBookCard extends StatelessWidget {
  const _TopicBookCard();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BookCover(width: 83, height: 125),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Toán Cao Cấp',
                style: TextStyle(
                  color: kBookTitle,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
              const Text(
                'Tác giả: Lê Trọng Lang',
                style: TextStyle(
                  color: kMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(
                'Thể loại: Sách giáo khoa',
                style: TextStyle(
                  color: kMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const Text(
                'Năm xuất bản: 2023',
                style: TextStyle(
                  color: kMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(
                'Mô tả: Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed ...',
                style: TextStyle(
                  color: Color(0xB2939393),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DetailBook()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBeigeButton,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(81, 33),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Xem sách',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
