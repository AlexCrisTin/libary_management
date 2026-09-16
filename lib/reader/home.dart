import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
                left: 15,
                top: 91,
                child: Text(
                    'Sách đang hot',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 25,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 15,
                top: 353,
                child: Text(
                    'Khám phá chủ đề',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 25,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 44,
                top: 317,
                child: Text(
                    'Toán cao cấp',
                    style: TextStyle(
                        color: const Color(0xFF6F3636),
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 26,
                top: 142,
                child: Container(
                    width: 113,
                    height: 169,
                    decoration: ShapeDecoration(
                        image: DecorationImage(
                            image: NetworkImage("https://placehold.co/113x169"),
                            fit: BoxFit.cover,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 179,
                top: 317,
                child: Text(
                    'Toán cao cấp',
                    style: TextStyle(
                        color: const Color(0xFF6F3636),
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 161,
                top: 142,
                child: Container(
                    width: 113,
                    height: 169,
                    decoration: ShapeDecoration(
                        image: DecorationImage(
                            image: NetworkImage("https://placehold.co/113x169"),
                            fit: BoxFit.cover,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 37,
                top: 449,
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
                left: 324,
                top: 317,
                child: Text(
                    'Toán cao cấp',
                    style: TextStyle(
                        color: const Color(0xFF6F3636),
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 301,
                top: 142,
                child: Container(
                    width: 113,
                    height: 169,
                    decoration: ShapeDecoration(
                        image: DecorationImage(
                            image: NetworkImage("https://placehold.co/113x169"),
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
                left: 15,
                top: 397,
                child: Text(
                    'Sách giáo khoa',
                    style: TextStyle(
                        color: const Color(0xFFBC5F5F),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        height: 1.50,
                    ),
                ),
            ),
            Positioned(
                left: 137,
                top: 449,
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
                left: 138,
                top: 472,
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
                left: 139,
                top: 500,
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
                left: 138,
                top: 521,
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
                left: 138,
                top: 485,
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
                left: 280,
                top: 552,
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
                left: 289,
                top: 559,
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
        ],
    ),
)
    );
  }
}
