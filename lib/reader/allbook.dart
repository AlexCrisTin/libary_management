import 'package:flutter/material.dart';

class AllBook extends StatelessWidget {
  const AllBook({super.key});

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
                left: 26,
                top: 798,
                child: Container(
                    width: 349,
                    height: 61,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFEFE2D9),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 108,
                top: 79,
                child: Container(
                    width: 112,
                    height: 24,
                    decoration: ShapeDecoration(
                        color: const Color(0xFF8A6060),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 232,
                top: 79,
                child: Container(
                    width: 77,
                    height: 24,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            side: BorderSide(
                                width: 1,
                                color: Colors.black.withValues(alpha: 0.20),
                            ),
                            borderRadius: BorderRadius.circular(30),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 15,
                top: 12,
                child: Container(
                    width: 322,
                    height: 45,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            side: BorderSide(
                                width: 3,
                                color: const Color(0xFFDDDDDD),
                            ),
                            borderRadius: BorderRadius.circular(20),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 36,
                top: 26,
                child: Text(
                    'Bạn muốn đọc gì................',
                    style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.20),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 344,
                top: 12,
                child: Container(width: 49, height: 49, child: Stack()),
            ),
            Positioned(
                left: 47,
                top: 806,
                child: Container(width: 45, height: 45, child: Stack()),
            ),
            Positioned(
                left: 315,
                top: 806,
                child: Container(width: 45, height: 45, child: Stack()),
            ),
            Positioned(
                left: 113,
                top: 806,
                child: Container(width: 45, height: 45, child: Stack()),
            ),
            Positioned(
                left: 180,
                top: 806,
                child: Container(width: 45, height: 45, child: Stack()),
            ),
            Positioned(
                left: 247,
                top: 806,
                child: Container(width: 45, height: 45, child: Stack()),
            ),
            Positioned(
                left: 299,
                top: 23,
                child: Container(width: 24, height: 24, child: Stack()),
            ),
            Positioned(
                left: 42,
                top: 131,
                child: Container(
                    width: 83,
                    height: 125,
                    decoration: ShapeDecoration(
                        image: DecorationImage(
                            image: NetworkImage("https://placehold.co/83x125"),
                            fit: BoxFit.cover,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 308,
                top: 710,
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
                left: 318,
                top: 721,
                child: Container(width: 45, height: 45, child: Stack()),
            ),
            Positioned(
                left: 142,
                top: 131,
                child: Text(
                    'Toán Cao Cấp',
                    style: TextStyle(
                        color: const Color(0xFF6F3636),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        height: 1.50,
                    ),
                ),
            ),
            Positioned(
                left: 143,
                top: 154,
                child: Text(
                    'Tác giả: Lê Trọng Lang',
                    style: TextStyle(
                        color: const Color(0xFF939393),
                        fontSize: 11,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                    ),
                ),
            ),
            Positioned(
                left: 144,
                top: 182,
                child: SizedBox(
                    width: 107,
                    height: 11,
                    child: Text(
                        'Năm xuất bản: 2023',
                        style: TextStyle(
                            color: const Color(0xFF939393),
                            fontSize: 11,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 143,
                top: 203,
                child: SizedBox(
                    width: 223,
                    child: Text(
                        'Mô tả:Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed ...',
                        style: TextStyle(
                            color: const Color(0xB2939393),
                            fontSize: 11,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 143,
                top: 167,
                child: Text(
                    'Thể loại: Sách giáo khoa',
                    style: TextStyle(
                        color: const Color(0xFF939393),
                        fontSize: 11,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        height: 1.50,
                    ),
                ),
            ),
            Positioned(
                left: 285,
                top: 234,
                child: Container(
                    width: 81,
                    height: 33,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFE2C5B5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 294,
                top: 241,
                child: Text(
                    'Xem sách',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        height: 1.50,
                    ),
                ),
            ),
            Positioned(
                left: 15,
                top: 83,
                child: Text(
                    'Lọc tìm kiếm',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 116,
                top: 83,
                child: Text(
                    'Sách giáo khoa',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 243,
                top: 83,
                child: Text(
                    'Giáo dục',
                    style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.20),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 350,
                top: 75,
                child: Container(
                    width: 32,
                    height: 32,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(),
                    child: Stack(),
                ),
            ),
        ],
    ),
);
  }}