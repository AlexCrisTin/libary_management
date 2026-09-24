import 'package:flutter/material.dart';

class Notice extends StatelessWidget {
  const Notice({super.key});

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
                    height: 77,
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
                left: 25,
                top: 104,
                child: Container(
                    width: 346,
                    height: 40,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFE2C5B5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                            ),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 25,
                top: 144,
                child: Container(
                    width: 346,
                    height: 80,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFF7F0EA),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(5),
                                bottomRight: Radius.circular(5),
                            ),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 36,
                top: 115,
                child: Text(
                    'Ngày 27/7/2727',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 8,
                top: 20,
                child: Container(width: 37, height: 37, child: Stack()),
            ),
            Positioned(
                left: 135,
                top: 27,
                child: Text(
                    'Thông báo',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 25,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 263,
                top: 105,
                child: Container(width: 38, height: 38, child: Stack()),
            ),
            Positioned(
                left: 301,
                top: 115,
                child: Text(
                    'Quản lý',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 181,
                top: 115,
                child: Text(
                    '10:21',
                    style: TextStyle(
                        color: const Color(0x7F8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 41,
                top: 152,
                child: SizedBox(
                    width: 318,
                    child: Text(
                        'Thông báo:Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut...',
                        style: TextStyle(
                            color: const Color(0xFF6F3636),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                        ),
                    ),
                ),
            ),
        ],
    ),
);
  }
}