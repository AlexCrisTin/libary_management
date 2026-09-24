import 'package:flutter/material.dart';

class BorrowReturnBookManagement extends StatelessWidget {
  const BorrowReturnBookManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar header
            Container(
              width: double.infinity,
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const ShapeDecoration(
                color: Color(0xFFDBB9A0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
              ),
              child: const Center(
                child: Text(
                  'Quản lý mượn/trả',
                  style: TextStyle(
                    color: Color(0xFF8A6060),
                    fontSize: 25,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 12, 11, 0),
              child: Row(
                children: [
                  // Search field
                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 3,
                            color: Color(0xFFDDDDDD),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Tìm kiếm',
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.20),
                                fontSize: 15,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                              width: 24,
                              height: 24,
                              child: const Stack()),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 40, height: 40, child: const Stack()),
                ],
              ),
            ),
            // Table header
            Container(
              margin: const EdgeInsets.fromLTRB(11, 8, 11, 0),
              height: 51,
              decoration: ShapeDecoration(
                color: const Color(0xFFE2C5B5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Độc giả',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Sách',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Ngày mượn',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Ngày trả',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Chi tiết',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // List item (sample)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 11, vertical: 4),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        // Reader name
                        const Expanded(
                          flex: 2,
                          child: SizedBox(
                            width: 61,
                            child: Text(
                              'Trần Ngọc An',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF8A6060),
                                fontSize: 13,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        // Book cover
                        Expanded(
                          flex: 2,
                          child: Container(
                            width: 53,
                            height: 80,
                            decoration: BoxDecoration(
                              image: const DecorationImage(
                                image: NetworkImage(
                                    "https://placehold.co/53x80"),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        // Borrow date
                        const Expanded(
                          flex: 2,
                          child: Text(
                            '27/7/2727',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF8A6060),
                              fontSize: 13,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // Return date
                        const Expanded(
                          flex: 2,
                          child: Text(
                            '27/7/2727',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF8A6060),
                              fontSize: 13,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        // Detail button
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 39,
                            decoration: ShapeDecoration(
                              color: const Color(0xFFE2C5B5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Stack(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // FAB
            Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 67,
                  height: 67,
                  decoration: const ShapeDecoration(
                    color: Color(0xFFEFE2D9),
                    shape: OvalBorder(),
                  ),
                  child: const Stack(),
                ),
              ),
            ),
            // Bottom nav
            Container(
              margin: const EdgeInsets.fromLTRB(26, 0, 26, 8),
              height: 61,
              decoration: ShapeDecoration(
                color: const Color(0xFFEFE2D9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(width: 45, height: 45, child: const Stack()),
                  Container(width: 45, height: 45, child: const Stack()),
                  Container(width: 45, height: 45, child: const Stack()),
                  Container(width: 45, height: 45, child: const Stack()),
                  Container(width: 45, height: 45, child: const Stack()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}