import 'package:flutter/material.dart';

class ProfileDetail extends StatelessWidget {
  const ProfileDetail({super.key});

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
                left: 129,
                top: 27,
                child: Container(
                    width: 135,
                    height: 135,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFEFE2D9),
                        shape: OvalBorder(),
                    ),
                ),
            ),
            Positioned(
                left: 143,
                top: 171,
                child: Container(width: 45, height: 45, child: Stack()),
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
                    height: 378,
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
                    'Thông tin',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 188,
                top: 185,
                child: Text(
                    'Đổi ảnh',
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
                left: 51,
                top: 312,
                child: Text(
                    'Họ và tên: Trần Ngọc An',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 51,
                top: 364,
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
                left: 332,
                top: 307,
                child: Container(width: 24, height: 24, child: Stack()),
            ),
            Positioned(
                left: 332,
                top: 413,
                child: Container(width: 24, height: 24, child: Stack()),
            ),
            Positioned(
                left: 332,
                top: 465,
                child: Container(width: 24, height: 24, child: Stack()),
            ),
            Positioned(
                left: 332,
                top: 523,
                child: Container(width: 24, height: 24, child: Stack()),
            ),
            Positioned(
                left: 331,
                top: 629,
                child: Container(width: 24, height: 24, child: Stack()),
            ),
            Positioned(
                left: 50,
                top: 416,
                child: Text(
                    'Ngày sinh: 27/7/2727',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 50,
                top: 468,
                child: Text(
                    'Số điện thoại: 02727272727',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 50,
                top: 526,
                child: Text(
                    'Địa chỉ: 27 trần văn phú',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 49,
                top: 632,
                child: Text(
                    'Đổi mật khẩu',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 331,
                top: 576,
                child: Container(width: 24, height: 24, child: Stack()),
            ),
            Positioned(
                left: 49,
                top: 579,
                child: Text(
                    'Email:2727@gmail.com',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 15,
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