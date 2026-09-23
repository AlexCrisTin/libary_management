import 'package:flutter/material.dart';

class FormAddReader extends StatelessWidget {
  const FormAddReader({super.key});

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
                left: 112,
                top: 20,
                child: Text(
                    'Thêm độc giả',
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
                left: 141,
                top: 108,
                child: Text(
                    'Thông tin độc giả',
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
                    'Họ và tên',
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
                    'Ngày sinh',
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
                    'Số điện thoại',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 127,
                top: 335,
                child: Container(
                    width: 210,
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
                    'Loại độc giả',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 32,
                top: 419,
                child: Text(
                    'Ngày hết hạn thẻ',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 146,
                top: 412,
                child: Container(
                    width: 79,
                    height: 29,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                ),
            ),
            Positioned(
                left: 171,
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
                    'Số sách tối đa mượn',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 107,
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
                    'Trạng thái',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 223,
                top: 381,
                child: Text(
                    'Khoa',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 272,
                top: 375,
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
            Positioned(
                left: 151,
                top: 146,
                child: Container(
                    width: 94,
                    height: 94,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFEFE2D9),
                        shape: OvalBorder(),
                    ),
                ),
            ),
            Positioned(
                left: 177,
                top: 172,
                child: Container(width: 41, height: 41, child: Stack()),
            ),
        ],
    ),
);
  }
}