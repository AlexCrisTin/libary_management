import 'package:flutter/material.dart';

class Login extends StatelessWidget {
  const Login({super.key});

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
                left: 107,
                top: 142,
                child: Text(
                    'Đăng nhập',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 36,
                        fontFamily: 'Arial',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 53,
                top: 283,
                child: Container(
                    width: 296,
                    height: 61,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            side: BorderSide(
                                width: 3,
                                color: const Color(0xFFDDDDDD),
                            ),
                            borderRadius: BorderRadius.circular(20),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 53,
                top: 365,
                child: Container(
                    width: 296,
                    height: 61,
                    decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            side: BorderSide(
                                width: 3,
                                color: const Color(0xFFDDDDDD),
                            ),
                            borderRadius: BorderRadius.circular(20),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 71,
                top: 305,
                child: Text(
                    'Email',
                    style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.20),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 71,
                top: 387,
                child: Text(
                    'Mật khẩu',
                    style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.20),
                        fontSize: 15,
                        fontFamily: 'Arial',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 142,
                top: 463,
                child: Text(
                    'Quên mật khẩu?',
                    style: TextStyle(
                        color: const Color(0xFFE9BCB9),
                        fontSize: 15,
                        fontFamily: 'Arial',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 152,
                top: 780,
                child: Text(
                    'Tạo tài khoản',
                    style: TextStyle(
                        color: const Color(0xFFE9BCB9),
                        fontSize: 15,
                        fontFamily: 'Arial',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 73,
                top: 641,
                child: Text(
                    'Đăng nhập bằng phương thức khác',
                    style: TextStyle(
                        color: const Color(0xFFBDBDBD),
                        fontSize: 15,
                        fontFamily: 'Arial',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 166,
                top: 540,
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
                left: 176,
                top: 679,
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
                left: 184,
                top: 687,
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
        ],
    ),
)
    );
  }
}