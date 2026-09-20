import 'package:flutter/material.dart';

class DetailBook extends StatelessWidget {
  const DetailBook({super.key});

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
                left: 110,
                top: 20,
                child: Text(
                    'Thông tin sách',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 25,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 113,
                top: 160,
                child: Container(
                    width: 168,
                    height: 253,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: NetworkImage("https://placehold.co/168x253"),
                            fit: BoxFit.cover,
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 121,
                top: 431,
                child: Container(
                    width: 151,
                    height: 46,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFE2C5B5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 248,
                top: 564,
                child: Container(
                    width: 113,
                    height: 108,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFD18282),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 151,
                top: 444,
                child: Text(
                    'Cho mượn',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 283,
                top: 644,
                child: Text(
                    '0/10',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 341,
                top: 12,
                child: Container(width: 45, height: 45, child: Stack()),
            ),
            Positioned(
                left: 12,
                top: 16,
                child: Container(width: 37, height: 37, child: Stack()),
            ),
            Positioned(
                left: 153,
                top: 525,
                child: Text(
                    'Thông tin sách',
                    style: TextStyle(
                        color: const Color(0xFF6F3636),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 256,
                top: 572,
                child: SizedBox(
                    width: 86,
                    child: Text(
                        'Số người đang mượn',
                        style: TextStyle(
                            color: const Color(0xFF6F3636),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 39,
                top: 564,
                child: Text(
                    'Tên sách: Toán cao cấp',
                    style: TextStyle(
                        color: const Color(0xFF6F3636),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 39,
                top: 589,
                child: Text(
                    'Tác giả: Lê Trọng Lang',
                    style: TextStyle(
                        color: const Color(0xFF6F3636),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 39,
                top: 614,
                child: Text(
                    'Năm xuất bản: 2023',
                    style: TextStyle(
                        color: const Color(0xFF6F3636),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 39,
                top: 639,
                child: Text(
                    'Nhà xuất bản: Long Tuất ',
                    style: TextStyle(
                        color: const Color(0xFF6F3636),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 39,
                top: 664,
                child: Text(
                    'Thể loại: Sách giáo khoa',
                    style: TextStyle(
                        color: const Color(0xFF6F3636),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 39,
                top: 691,
                child: Text(
                    'Tình trạng: Tốt',
                    style: TextStyle(
                        color: const Color(0xFF6F3636),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 39,
                top: 721,
                child: SizedBox(
                    width: 223,
                    child: Text(
                        'Mô tả:Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut...',
                        style: TextStyle(
                            color: const Color(0xFF6F3636),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 282,
                top: 603,
                child: Container(width: 41, height: 41, child: Stack()),
            ),
            Positioned(
                left: 335,
                top: 515,
                child: Container(width: 37, height: 37, child: Stack()),
            ),
        ],
    ),
);
  }
}