import 'package:flutter/material.dart';

class ReaderDetail extends StatelessWidget {
  const ReaderDetail({super.key});

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
                left: 11,
                top: 273,
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
                left: 71,
                top: 738,
                child: Text(
                    'Mượn sách',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 12,
                top: 17,
                child: Container(width: 37, height: 37, child: Stack()),
            ),
            Positioned(
                left: 125,
                top: 96,
                child: Container(
                    width: 151,
                    height: 151,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFEFE2D9),
                        shape: OvalBorder(),
                    ),
                ),
            ),
            Positioned(
                left: 88,
                top: 289,
                child: SizedBox(
                    width: 225,
                    child: Text(
                        'Thông tin độc giả',
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
                left: 52,
                top: 353,
                child: Text(
                    'Họ và tên: Trần Ngọc An',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 52,
                top: 405,
                child: Text(
                    'Mã độc giả: M1',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 51,
                top: 457,
                child: Text(
                    'Ngày sinh: 27/7/2727',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 51,
                top: 509,
                child: Text(
                    'Số điện thoại: 02727272727',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 51,
                top: 567,
                child: Text(
                    'Địa chỉ: 27 trần văn phú',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 50,
                top: 620,
                child: Text(
                    'Email:2727@gmail.com',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 342,
                top: 279,
                child: Container(width: 37, height: 37, child: Stack()),
            ),
            Positioned(
                left: 88,
                top: 701,
                child: Container(width: 36, height: 36, child: Stack()),
            ),
        ],
    ),
);
  }
}