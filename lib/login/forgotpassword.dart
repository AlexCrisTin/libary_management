Container(
    width: 402,
    height: 874,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(color: Colors.white),
    child: Stack(
        children: [
            Positioned(
                left: 144,
                top: 760,
                child: Container(
                    width: 112,
                    height: 57,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFDBB9A0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 161,
                top: 780,
                child: Text(
                    'Đăng nhập',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Arial',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 109,
                top: 736,
                child: Text(
                    'Bạn đã nhớ được  rồi sao?',
                    style: TextStyle(
                        color: const Color(0xFFD76464),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 166,
                top: 321,
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
                left: 108,
                top: 28,
                child: Text(
                    'Quên mật khẩu',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 25,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 78,
                top: 250,
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
        ],
    ),
)