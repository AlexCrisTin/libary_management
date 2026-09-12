import 'package:flutter/material.dart';

class Signup extends StatelessWidget {
  const Signup({super.key});

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
                left: 162,
                top: 777,
                child: Text(
                    'Đăng nhập',
                    style: TextStyle(
                        color: const Color(0xFFE9BCB9),
                        fontSize: 15,
                        fontFamily: 'Arial',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 86,
                top: 638,
                child: Text(
                    'Đăng kí bằng phương thức khác',
                    style: TextStyle(
                        color: const Color(0xFFBDBDBD),
                        fontSize: 15,
                        fontFamily: 'Arial',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 168,
                top: 537,
                child: Container(
                    width: 70,
                    height: 70,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFDBB9A0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 53,
                top: 228,
                child: Container(
                width: 296,
                height: 61,
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                  ),
                ),
              ),
            ),
            Positioned(
                left: 53,
                top: 318,
                child: Container(
                width: 296,
                height: 61,
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Nhập mật khẩu',
                  ),
                ),
              ),
            ),
            Positioned(
                left: 53,
                top: 407,
                child: Container(
                width: 296,
                height: 61,
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Xác nhận mật khẩu',
                  ),
                ),
              ),
            ),
            Positioned(
                left: 178,
                top: 676,
                child: Container(
                    width: 50,
                    height: 50,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFD9D9D9),
                        shape: OvalBorder(),
                    ),
                ),
            ),
            Positioned(
                left: 186,
                top: 684,
                child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: NetworkImage("https://placehold.co/34x34"),
                            fit: BoxFit.cover,
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 137,
                top: 144,
                child: Text(
                    'Đăng kí',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 36,
                        fontFamily: 'Arial',
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
