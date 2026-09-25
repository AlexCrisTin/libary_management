import 'package:flutter/material.dart';
import 'librarian_nav.dart';
import 'reader_detail.dart';
import 'form_addreader.dart';

class ReaderManagement extends StatelessWidget {
  const ReaderManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            LibTitleHeader(
              title: 'Quản lý độc giả',
              trailing: IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FormAddReader()),
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
                        hintText: 'Tìm kiếm độc giả...',
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
            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 8, 11, 0),
              child: Row(
                children: [
                  _actionBtn(
                    icon: Icons.delete_outline,
                    color: const Color(0xFFFC5F5F),
                    onTap: () {},
                  ),
                  const Spacer(),
                  _actionBtn(
                    icon: Icons.add,
                    color: kLibBeigeButton,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FormAddReader()),
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
                    Expanded(flex: 1, child: Text('Mã', style: _hStyle)),
                    Expanded(flex: 2, child: Text('Họ tên', style: _hStyle)),
                    Expanded(
                      flex: 3,
                      child: Text('Số điện thoại', style: _hStyle),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(child: Text('Chi tiết', style: _hStyle)),
                    ),
                  ],
                ),
              ),
            ),
            // Reader list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(11, 6, 11, 8),
                itemCount: _sampleReaders.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = _sampleReaders[i];
                  return _ReaderRow(
                    reader: r,
                    onDetailTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReaderDetail()),
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

class _ReaderData {
  const _ReaderData(this.id, this.name, this.phone);
  final String id, name, phone;
}

const _sampleReaders = [
  _ReaderData('M1', 'Trần Ngọc An', '02727272727'),
  _ReaderData('M2', 'Nguyễn Văn Bình', '0901234567'),
];

class _ReaderRow extends StatelessWidget {
  const _ReaderRow({required this.reader, this.onDetailTap});
  final _ReaderData reader;
  final VoidCallback? onDetailTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              reader.id,
              style: const TextStyle(
                color: kLibBrownTitle,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              reader.name,
              style: const TextStyle(
                color: kLibBrownTitle,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              reader.phone,
              style: const TextStyle(
                color: kLibBrownTitle,
                fontSize: 13,
                fontWeight: FontWeight.w700,
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
