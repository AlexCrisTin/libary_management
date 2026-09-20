import 'package:flutter/material.dart';

class MessageAll extends StatelessWidget {
  const MessageAll({super.key});

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
                left: 46,
                top: 806,
                child: Container(width: 45, height: 45, child: Stack()),
            ),
            Positioned(
                left: 20,
                top: 20,
                child: Text(
                    'Chào mừng',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 25,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 339,
                top: 10,
                child: Container(width: 49, height: 49, child: Stack()),
            ),
            Positioned(
                left: 10,
                top: 81,
                child: Container(
                    width: 381,
                    height: 689,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFF7F0EA),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 28,
                top: 177,
                child: Container(
                    width: 345,
                    height: 89,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFE2C5B5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 91,
                top: 104,
                child: Container(
                    width: 282,
                    height: 37,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 133,
                top: 196,
                child: Container(
                    width: 231,
                    height: 61,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 59,
                top: 188,
                child: Container(
                    width: 44,
                    height: 44,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFEFE2D9),
                        shape: OvalBorder(),
                    ),
                ),
            ),
            Positioned(
                left: 38,
                top: 240,
                child: Text(
                    'Trần Ngọc An',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 145,
                top: 202,
                child: SizedBox(
                    width: 214,
                    child: Text(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut...',
                        style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.40),
                            fontSize: 10,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 133,
                top: 182,
                child: SizedBox(
                    width: 179,
                    child: Text(
                        '10:10',
                        style: TextStyle(
                            color: const Color(0xFF6F3636),
                            fontSize: 10,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 337,
                top: 111,
                child: Container(width: 24, height: 24, child: Stack()),
            ),
            Positioned(
                left: 35,
                top: 104,
                child: Container(width: 37, height: 37, child: Stack()),
            ),
            Positioned(
                left: 195,
                top: 726,
                child: Text(
                    'AI',
                    style: TextStyle(
                        color: const Color(0xFFE2C5B5),
                        fontSize: 15,
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