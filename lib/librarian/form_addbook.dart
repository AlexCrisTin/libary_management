import 'package:flutter/material.dart';

class FormAddBook extends StatelessWidget {
  const FormAddBook({super.key});

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
                left: 182,
                top: 378,
                child: Container(
                    width: 25,
                    height: 22,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFE2C5B5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 184,
                top: 380,
                child: Container(width: 21, height: 21, child: Stack()),
            ),
            Positioned(
                left: 184,
                top: 456,
                child: Container(
                    width: 25,
                    height: 22,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFE2C5B5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 186,
                top: 457,
                child: Container(width: 21, height: 21, child: Stack()),
            ),
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
                left: 127,
                top: 20,
                child: Text(
                    'Thêm sách',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 25,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 12,
                top: 16,
                child: Container(width: 37, height: 37, child: Stack()),
            ),
            Positioned(
                left: 150,
                top: 107,
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
                left: 31,
                top: 267,
                child: Text(
                    'Tên sách',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 103,
                top: 261,
                child: Container(
                    width: 234,
                    height: 29,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                ),
            ),
            Positioned(
                left: 31,
                top: 305,
                child: Text(
                    'Phụ đề',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 103,
                top: 298,
                child: Container(
                    width: 234,
                    height: 29,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                ),
            ),
            Positioned(
                left: 31,
                top: 343,
                child: Text(
                    'ISBN',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 103,
                top: 335,
                child: Container(
                    width: 234,
                    height: 29,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                ),
            ),
            Positioned(
                left: 31,
                top: 381,
                child: Text(
                    'Tác giả',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 207,
                top: 421,
                child: Text(
                    'Năm xuất bản',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 309,
                top: 414,
                child: Container(
                    width: 55,
                    height: 29,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                ),
            ),
            Positioned(
                left: 31,
                top: 458,
                child: Text(
                    'Thể loại',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 103,
                top: 452,
                child: Container(
                    width: 74,
                    height: 29,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                ),
            ),
            Positioned(
                left: 31,
                top: 458,
                child: Text(
                    'Thể loại',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 104,
                top: 489,
                child: Container(
                    width: 74,
                    height: 29,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                ),
            ),
            Positioned(
                left: 32,
                top: 495,
                child: Text(
                    'Ngôn ngữ',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 103,
                top: 526,
                child: Container(
                    width: 74,
                    height: 29,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                ),
            ),
            Positioned(
                left: 32,
                top: 532,
                child: Text(
                    'Vị trí kệ',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 274,
                top: 527,
                child: Container(
                    width: 74,
                    height: 29,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                ),
            ),
            Positioned(
                left: 210,
                top: 532,
                child: Text(
                    'Bản sao',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 275,
                top: 488,
                child: Container(
                    width: 38,
                    height: 29,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                ),
            ),
            Positioned(
                left: 209,
                top: 495,
                child: Text(
                    'Số trang',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 31,
                top: 419,
                child: Text(
                    'Nhà xuất bản',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 121,
                top: 412,
                child: Container(
                    width: 67,
                    height: 29,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                ),
            ),
            Positioned(
                left: 130,
                top: 158,
                child: Container(
                    width: 141,
                    height: 77,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                ),
            ),
            Positioned(
                left: 178,
                top: 174,
                child: Container(width: 41, height: 41, child: Stack()),
            ),
            Positioned(
                left: 143,
                top: 695,
                child: Container(
                    width: 113,
                    height: 51,
                    decoration: ShapeDecoration(
                        color: const Color(0xFF82D1A8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 186,
                top: 713,
                child: Text(
                    'Tạo',
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
);
  }
}