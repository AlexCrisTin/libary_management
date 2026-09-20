import 'package:flutter/material.dart';

class Report extends StatelessWidget {
  const Report({super.key});

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
                left: 123,
                top: 84,
                child: Container(
                    width: 266,
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
                    'Báo cáo',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 25,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 144,
                top: 787,
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
                left: 181,
                top: 787,
                child: Container(width: 40, height: 40, child: Stack()),
            ),
            Positioned(
                left: 175,
                top: 827,
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
                left: 12,
                top: 17,
                child: Container(width: 37, height: 37, child: Stack()),
            ),
            Positioned(
                left: 16,
                top: 84,
                child: Container(
                    width: 99,
                    height: 99,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFEFE2D9),
                        shape: OvalBorder(),
                    ),
                ),
            ),
            Positioned(
                left: 140,
                top: 100,
                child: Text(
                    'Trần Ngọc An',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 135,
                top: 148,
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
                left: 135,
                top: 179,
                child: Text(
                    'Sách',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 134,
                top: 303,
                child: Text(
                    'Lý do báo cáo',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 20,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 61,
                top: 359,
                child: Text(
                    'Làm mất sách',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 29,
                top: 356,
                child: Container(width: 24, height: 24, child: Stack()),
            ),
            Positioned(
                left: 61,
                top: 394,
                child: Text(
                    'Làm hỏng sách',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 29,
                top: 391,
                child: Container(width: 24, height: 24, child: Stack()),
            ),
            Positioned(
                left: 252,
                top: 359,
                child: Text(
                    'Quá hạn',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 218,
                top: 356,
                child: Container(width: 24, height: 24, child: Stack()),
            ),
            Positioned(
                left: 252,
                top: 394,
                child: Text(
                    'Lý do khác',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 218,
                top: 391,
                child: Container(width: 24, height: 24, child: Stack()),
            ),
            Positioned(
                left: 31,
                top: 429,
                child: Text(
                    'Ghi chú',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 35,
                top: 593,
                child: Text(
                    'Tiền phạt',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 35,
                top: 640,
                child: Text(
                    'Minh chứng',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 189,
                top: 176,
                child: Container(
                    width: 181,
                    height: 24,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                ),
            ),
            Positioned(
                left: 123,
                top: 590,
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
                left: 161,
                top: 640,
                child: Container(
                    width: 196,
                    height: 107,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                ),
            ),
            Positioned(
                left: 135,
                top: 207,
                child: Text(
                    'Ngày mượn',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 135,
                top: 233,
                child: Text(
                    'Ngày trả',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 210,
                top: 233,
                child: SizedBox(
                    width: 87,
                    child: Text(
                        '27/7/2727',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: const Color(0xFF8A6060),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 210,
                top: 207,
                child: SizedBox(
                    width: 87,
                    child: Text(
                        '27/7/2727',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: const Color(0xFF8A6060),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 228,
                top: 662,
                child: Container(width: 57, height: 57, child: Stack()),
            ),
        ],
    ),
);
  }
}