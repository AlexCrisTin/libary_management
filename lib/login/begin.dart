import 'package:flutter/material.dart';

class Begin extends StatelessWidget {
  const Begin({super.key});

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
                left: -75,
                top: 0,
                child: Container(
                    width: 5745,
                    height: 2763,
                    decoration: BoxDecoration(color: const Color(0x0AD9D9D9)),
                ),
            ),
            Positioned(
                left: -279,
                top: -15,
                child: Container(
                    width: 960,
                    height: 960,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: NetworkImage("https://placehold.co/960x960"),
                            fit: BoxFit.cover,
                        ),
                    ),
                ),
            ),
            Positioned(
                left: -91,
                top: -36,
                child: Container(
                    width: 565,
                    height: 1006,
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.54),
                    ),
                ),
            ),
            Positioned(
                left: 72,
                top: 758,
                child: Container(
                    width: 257,
                    height: 52,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFE2C5B5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 64,
                top: 125,
                child: Text(
                    'READILY',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 112,
                top: 173,
                child: SizedBox(
                    width: 177,
                    child: Text(
                        'Thư viện với hàng chục nghìn cuốn sách trực tuyến',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                        ),
                    ),
                ),
            ),
            Positioned(
                left: 166,
                top: 775,
                child: Text(
                    'Tiếp theo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                    ),
                ),
            ),
        ],
    ),
),
);
  }
}
