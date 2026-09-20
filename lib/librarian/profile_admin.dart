import 'package:flutter/material.dart';

class ProfileAdmin extends StatelessWidget {
  const ProfileAdmin({super.key});

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
                    height: 226,
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
                left: 27,
                top: 54,
                child: Container(
                    width: 118,
                    height: 118,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFEFE2D9),
                        shape: OvalBorder(),
                    ),
                ),
            ),
            Positioned(
                left: 150,
                top: 54,
                child: Text(
                    'Lê Văn Lê',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 155,
                top: 89,
                child: Text(
                    '@st.phenikaa-uni.edu.vn',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 27,
                top: 256,
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
                left: 27,
                top: 296,
                child: Container(
                    width: 346,
                    height: 197,
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
                left: 33,
                top: 300,
                child: Container(width: 45, height: 45, child: Stack()),
            ),
            Positioned(
                left: 27,
                top: 527,
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
                left: 27,
                top: 567,
                child: Container(
                    width: 346,
                    height: 204,
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
                left: 38,
                top: 267,
                child: Text(
                    'Tài khoản',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 89,
                top: 314,
                child: Text(
                    'Thông tin cá nhân',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 125,
                top: 748,
                child: Container(
                    width: 151,
                    height: 46,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFF16F6F),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 89,
                top: 585,
                child: Text(
                    'Cài đặt',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 165,
                top: 762,
                child: Text(
                    'Đăng xuất',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 89,
                top: 632,
                child: Text(
                    'Thông tin khác',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 38,
                top: 538,
                child: Text(
                    'Cài đặt khác',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 337,
                top: 311,
                child: Container(width: 24, height: 24, child: Stack()),
            ),
            Positioned(
                left: 336,
                top: 582,
                child: Container(width: 24, height: 24, child: Stack()),
            ),
            Positioned(
                left: 336,
                top: 629,
                child: Container(width: 24, height: 24, child: Stack()),
            ),
            Positioned(
                left: 32,
                top: 571,
                child: Container(width: 45, height: 45, child: Stack()),
            ),
            Positioned(
                left: 32,
                top: 617,
                child: Container(width: 45, height: 45, child: Stack()),
            ),
        ],
    ),
);
  }
}