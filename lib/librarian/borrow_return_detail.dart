import 'package:flutter/material.dart';

class BorrowReturnDetail extends StatelessWidget {
  const BorrowReturnDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
    width: 402,
    height: 874,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(color: Colors.white),
    child: Stack(
        children: [
            Positioned(
                left: 0,
                top: 0,
                child: Container(
                    width: 402,
                    height: 70,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFDBB9A0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                            ),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 167,
                top: 794,
                child: Container(
                    width: 67,
                    height: 67,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFEFE2D9),
                        shape: OvalBorder(),
                    ),
                ),
            ),
            Positioned(
                left: 177,
                top: 805,
                child: Container(width: 45, height: 45, child: Stack()),
            ),
            Positioned(
                left: 12,
                top: 338,
                child: Container(
                    width: 379,
                    height: 51,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFE2C5B5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 24,
                top: 414,
                child: Text(
                    'Sách:',
                    style: TextStyle(
                        color: const Color(0xFFC16767),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 26,
                top: 514,
                child: Text(
                    'Ngày mượn',
                    style: TextStyle(
                        color: const Color(0xFFC16767),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 26,
                top: 547,
                child: Text(
                    'Ngày trả',
                    style: TextStyle(
                        color: const Color(0xFFC16767),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 26,
                top: 478,
                child: Text(
                    'Người mượn',
                    style: TextStyle(
                        color: const Color(0xFFC16767),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 26,
                top: 446,
                child: Text(
                    'Mã',
                    style: TextStyle(
                        color: const Color(0xFFC16767),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 153,
                top: 20,
                child: Text(
                    'Chi tiết',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 25,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 121,
                top: 92,
                child: Container(
                    width: 147,
                    height: 221,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: NetworkImage("https://placehold.co/147x221"),
                            fit: BoxFit.cover,
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 234,
                top: 697,
                child: Container(
                    width: 113,
                    height: 67,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFD18282),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 50,
                top: 697,
                child: Container(
                    width: 113,
                    height: 67,
                    decoration: ShapeDecoration(
                        color: const Color(0xFF82D1A8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: -4,
                top: 579,
                child: SizedBox(
                    width: 108,
                    child: Text(
                        'Ghi chú',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: const Color(0xFFC16767),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 5,
                top: 612,
                child: SizedBox(
                    width: 108,
                    child: Text(
                        'Tình trạng',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: const Color(0xFFC16767),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 88,
                top: 354,
                child: SizedBox(
                    width: 225,
                    child: Text(
                        'Thông tin sách và người mượn',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: const Color(0xFF444A58),
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 271,
                top: 697,
                child: Container(width: 40, height: 40, child: Stack()),
            ),
            Positioned(
                left: 265,
                top: 737,
                child: Text(
                    'Báo cáo',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 82,
                top: 737,
                child: Text(
                    'Gia hạn',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 83,
                top: 697,
                child: Container(width: 41, height: 41, child: Stack()),
            ),
            Positioned(
                left: 12,
                top: 17,
                child: Container(width: 37, height: 37, child: Stack()),
            ),
        ],
    ),
);
  }
}