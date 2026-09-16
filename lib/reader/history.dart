import 'package:flutter/material.dart';

class History extends StatelessWidget {
  const History({super.key});

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
                    height: 63,
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
                left: 39,
                top: 104,
                child: Container(
                    width: 322,
                    height: 40,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFE2C5B5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 25,
                top: 164,
                child: Container(
                    width: 346,
                    height: 651,
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
                left: 98,
                top: 115,
                child: Text(
                    'Mượn',
                    style: TextStyle(
                        color: const Color(0xFFE2C5B5),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 264,
                top: 115,
                child: Text(
                    'Trả',
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
                top: 8,
                child: Container(width: 37, height: 37, child: Stack()),
            ),
            Positioned(
                left: 156,
                top: 15,
                child: Text(
                    'Lịch sử',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 174,
                top: 185,
                child: Text(
                    'Toán cao cấp',
                    style: TextStyle(
                        color: const Color(0xFF6F3636),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 57,
                top: 193,
                child: Container(
                    width: 89,
                    height: 134,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: NetworkImage("https://placehold.co/89x134"),
                            fit: BoxFit.cover,
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 174,
                top: 208,
                child: Text(
                    'Ngày mượn: 27/7/2727',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 174,
                top: 227,
                child: Text(
                    'Ngày trả: 27/7/2727',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 239,
                top: 304,
                child: Container(
                    width: 116,
                    height: 38,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFE2C5B5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 267,
                top: 314,
                child: Text(
                    'Mượn lại',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
        ],
    ),
)
    );
  }
}