import 'package:flutter/material.dart';

class Fine extends StatelessWidget {
  const Fine({super.key});

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
                left: 25,
                top: 118,
                child: Container(
                    width: 346,
                    height: 730,
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
                left: 8,
                top: 11,
                child: Container(width: 37, height: 37, child: Stack()),
            ),
            Positioned(
                left: 143,
                top: 16,
                child: Text(
                    'Tiền phạt',
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
                top: 139,
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
                left: 52,
                top: 82,
                child: Text(
                    'Danh sách những cuốn sách bị phạt',
                    style: TextStyle(
                        color: const Color(0xFF6F3636),
                        fontSize: 17,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 57,
                top: 147,
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
                top: 162,
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
                top: 181,
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
                left: 174,
                top: 204,
                child: Text(
                    'Lý do: quá hạn',
                    style: TextStyle(
                        color: const Color(0xFF939393),
                        fontSize: 10,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 239,
                top: 258,
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
                left: 253,
                top: 268,
                child: Text(
                    'Trả tiền phạt',
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