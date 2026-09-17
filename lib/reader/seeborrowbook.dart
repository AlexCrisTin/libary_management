import 'package:flutter/material.dart';
class SeeBorrowBook extends StatelessWidget {
  const SeeBorrowBook({super.key});

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
                left: 15,
                top: 12,
                child: Container(
                    width: 322,
                    height: 45,
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
                left: 36,
                top: 26,
                child: Text(
                    'Bạn muốn đọc gì................',
                    style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.20),
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 344,
                top: 12,
                child: Container(width: 49, height: 49, child: Stack()),
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
                left: 299,
                top: 23,
                child: Container(width: 24, height: 24, child: Stack()),
            ),
            Positioned(
                left: 26,
                top: 410,
                child: Text(
                    'Sách đang mượn',
                    style: TextStyle(
                        color: const Color(0xFF8A6060),
                        fontSize: 25,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 161,
                top: 452,
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
                left: 44,
                top: 460,
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
                left: 308,
                top: 710,
                child: Container(
                    width: 67,
                    height: 67,
                    decoration: ShapeDecoration(
                        color: const Color(0xFFEFE2D9),
                        shape: OvalBorder(),
                    ),
                ),
            ),
            Positioned(
                left: 318,
                top: 721,
                child: Container(width: 45, height: 45, child: Stack()),
            ),
            Positioned(
                left: 161,
                top: 475,
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
                left: 161,
                top: 494,
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
                left: 157,
                top: 518,
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
                left: 186,
                top: 528,
                child: Text(
                    'Trả sách',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 158,
                top: 568,
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
                left: 190,
                top: 578,
                child: Text(
                    'Gia hạn',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                    ),
                ),
            ),
            Positioned(
                left: 5,
                top: 81,
                child: Container(
                    width: 388,
                    height: 324,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(),
                    child: Stack(
                        children: [
                            Positioned(
                                left: 0.21,
                                top: 0.95,
                                child: Container(
                                    width: 387,
                                    height: 323,
                                    decoration: ShapeDecoration(
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        shadows: [
                                            BoxShadow(
                                                color: Color(0xFFECECEC),
                                                blurRadius: 23,
                                                offset: Offset(0, 2),
                                                spreadRadius: 0,
                                            )
                                        ],
                                    ),
                                ),
                            ),
                            Positioned(
                                left: 39.93,
                                top: 27.48,
                                child: Text(
                                    'October 2025',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: const Color(0xFF6B7897),
                                        fontSize: 15,
                                        fontFamily: 'Lato',
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.59,
                                    ),
                                ),
                            ),
                            Positioned(
                                left: 122.62,
                                top: 144.40,
                                child: Container(
                                    width: 39.14,
                                    height: 39.14,
                                    decoration: ShapeDecoration(
                                        gradient: LinearGradient(
                                            begin: Alignment(1.00, 1.00),
                                            end: Alignment(1.00, 0.00),
                                            colors: [const Color(0xFF7ED5FC), const Color(0xFF90D9FA)],
                                        ),
                                        shape: OvalBorder(),
                                    ),
                                ),
                            ),
                            Positioned(
                                left: 274,
                                top: 144,
                                child: Container(
                                    width: 39.14,
                                    height: 39.14,
                                    decoration: ShapeDecoration(
                                        color: const Color(0xFFB3261E) /* Schemes-Error */,
                                        shape: OvalBorder(),
                                    ),
                                ),
                            ),
                            Positioned(
                                left: 32.05,
                                top: 73.95,
                                child: Container(
                                    width: 323,
                                    height: 201,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(),
                                    child: Stack(
                                        children: [
                                            Positioned(
                                                left: 0.23,
                                                top: 0.26,
                                                child: Container(
                                                    width: 322,
                                                    height: 200,
                                                    clipBehavior: Clip.antiAlias,
                                                    decoration: BoxDecoration(),
                                                    child: Stack(
                                                        children: [
                                                            Positioned(
                                                                left: 0,
                                                                top: 43.93,
                                                                child: Container(
                                                                    width: 322,
                                                                    height: 156,
                                                                    clipBehavior: Clip.antiAlias,
                                                                    decoration: BoxDecoration(),
                                                                    child: Stack(
                                                                        children: [
                                                                            Positioned(
                                                                                left: -0.90,
                                                                                top: 0,
                                                                                child: Text(
                                                                                    '27',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFFE1E4E7),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 4.10,
                                                                                top: 35.63,
                                                                                child: SizedBox(
                                                                                    width: 9,
                                                                                    child: Text(
                                                                                        '4',
                                                                                        textAlign: TextAlign.center,
                                                                                        style: TextStyle(
                                                                                            color: const Color(0xFF7C86A2),
                                                                                            fontSize: 14.54,
                                                                                            fontFamily: 'Nunito',
                                                                                            fontWeight: FontWeight.w500,
                                                                                        ),
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: -0.90,
                                                                                top: 70.55,
                                                                                child: Text(
                                                                                    '11',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: -0.90,
                                                                                top: 105.48,
                                                                                child: Text(
                                                                                    '18',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: -0.90,
                                                                                top: 138.26,
                                                                                child: Text(
                                                                                    '25',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 49.67,
                                                                                top: 138.26,
                                                                                child: Text(
                                                                                    '26',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 49.67,
                                                                                top: 104.76,
                                                                                child: Text(
                                                                                    '19',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 49.67,
                                                                                top: 70.55,
                                                                                child: Text(
                                                                                    '12',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 54.67,
                                                                                top: 35.63,
                                                                                child: SizedBox(
                                                                                    width: 9,
                                                                                    child: Text(
                                                                                        '5',
                                                                                        textAlign: TextAlign.center,
                                                                                        style: TextStyle(
                                                                                            color: const Color(0xFF7C86A2),
                                                                                            fontSize: 14.54,
                                                                                            fontFamily: 'Nunito',
                                                                                            fontWeight: FontWeight.w500,
                                                                                        ),
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 49.67,
                                                                                top: 0,
                                                                                child: Text(
                                                                                    '28',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFFE1E4E7),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 100.24,
                                                                                top: 138.26,
                                                                                child: Text(
                                                                                    '27',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 100.24,
                                                                                top: 104.76,
                                                                                child: Text(
                                                                                    '20',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 100.24,
                                                                                top: 69.84,
                                                                                child: Text(
                                                                                    '13',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 105.24,
                                                                                top: 35.63,
                                                                                child: Text(
                                                                                    '6',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: Colors.white,
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 101.24,
                                                                                top: 0,
                                                                                child: Text(
                                                                                    '29\n',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFFE1E4E7),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 150.81,
                                                                                top: 138.26,
                                                                                child: Text(
                                                                                    '28',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 150.81,
                                                                                top: 104.76,
                                                                                child: Text(
                                                                                    '21',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 150.81,
                                                                                top: 69.84,
                                                                                child: Text(
                                                                                    '14',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 151.81,
                                                                                top: 35.63,
                                                                                child: SizedBox(
                                                                                    width: 17,
                                                                                    child: Text(
                                                                                        '7',
                                                                                        textAlign: TextAlign.center,
                                                                                        style: TextStyle(
                                                                                            color: const Color(0xFF7C86A2),
                                                                                            fontSize: 14.54,
                                                                                            fontFamily: 'Nunito',
                                                                                            fontWeight: FontWeight.w500,
                                                                                        ),
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 150.81,
                                                                                top: 1.43,
                                                                                child: Text(
                                                                                    '30',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFFE1E4E7),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 201.38,
                                                                                top: 138.26,
                                                                                child: Text(
                                                                                    '29',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 201.38,
                                                                                top: 104.76,
                                                                                child: Text(
                                                                                    '22',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 201.38,
                                                                                top: 69.84,
                                                                                child: Text(
                                                                                    '15',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 202.38,
                                                                                top: 35.63,
                                                                                child: SizedBox(
                                                                                    width: 17,
                                                                                    child: Text(
                                                                                        '8',
                                                                                        textAlign: TextAlign.center,
                                                                                        style: TextStyle(
                                                                                            color: const Color(0xFF7C86A2),
                                                                                            fontSize: 14.54,
                                                                                            fontFamily: 'Nunito',
                                                                                            fontWeight: FontWeight.w500,
                                                                                        ),
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 206.38,
                                                                                top: 1.43,
                                                                                child: Text(
                                                                                    '1',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 252.95,
                                                                                top: 138.26,
                                                                                child: Text(
                                                                                    '30',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 251.95,
                                                                                top: 104.76,
                                                                                child: Text(
                                                                                    '23',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 251.95,
                                                                                top: 69.84,
                                                                                child: Text(
                                                                                    '16',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 252.95,
                                                                                top: 35.63,
                                                                                child: SizedBox(
                                                                                    width: 17,
                                                                                    child: Text(
                                                                                        '9',
                                                                                        textAlign: TextAlign.center,
                                                                                        style: TextStyle(
                                                                                            color: Colors.white,
                                                                                            fontSize: 14.54,
                                                                                            fontFamily: 'Nunito',
                                                                                            fontWeight: FontWeight.w500,
                                                                                        ),
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 256.95,
                                                                                top: 1.43,
                                                                                child: Text(
                                                                                    '2',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 303.52,
                                                                                top: 138.26,
                                                                                child: Text(
                                                                                    '31',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 302.52,
                                                                                top: 104.76,
                                                                                child: Text(
                                                                                    '24',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 302.52,
                                                                                top: 69.84,
                                                                                child: Text(
                                                                                    '17',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 302.52,
                                                                                top: 35.63,
                                                                                child: Text(
                                                                                    '10',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                            Positioned(
                                                                                left: 307.52,
                                                                                top: 1.43,
                                                                                child: Text(
                                                                                    '3',
                                                                                    textAlign: TextAlign.center,
                                                                                    style: TextStyle(
                                                                                        color: const Color(0xFF7C86A2),
                                                                                        fontSize: 14.54,
                                                                                        fontFamily: 'Nunito',
                                                                                        fontWeight: FontWeight.w500,
                                                                                    ),
                                                                                ),
                                                                            ),
                                                                        ],
                                                                    ),
                                                                ),
                                                            ),
                                                            Positioned(
                                                                left: 3.41,
                                                                top: 0,
                                                                child: Opacity(
                                                                    opacity: 0.65,
                                                                    child: Container(
                                                                        width: 315,
                                                                        height: 20,
                                                                        clipBehavior: Clip.antiAlias,
                                                                        decoration: BoxDecoration(),
                                                                        child: Stack(
                                                                            children: [
                                                                                Positioned(
                                                                                    left: 0.04,
                                                                                    top: 0,
                                                                                    child: SizedBox(
                                                                                        width: 11,
                                                                                        height: 19.46,
                                                                                        child: Text(
                                                                                            'S',
                                                                                            textAlign: TextAlign.center,
                                                                                            style: TextStyle(
                                                                                                color: const Color(0x8834485E),
                                                                                                fontSize: 15.65,
                                                                                                fontFamily: 'Nunito',
                                                                                                fontWeight: FontWeight.w500,
                                                                                                height: 1.21,
                                                                                            ),
                                                                                        ),
                                                                                    ),
                                                                                ),
                                                                                Positioned(
                                                                                    left: 48.40,
                                                                                    top: 0,
                                                                                    child: SizedBox(
                                                                                        width: 14,
                                                                                        height: 19.46,
                                                                                        child: Text(
                                                                                            'M',
                                                                                            textAlign: TextAlign.center,
                                                                                            style: TextStyle(
                                                                                                color: const Color(0x8834485E),
                                                                                                fontSize: 15.65,
                                                                                                fontFamily: 'Nunito',
                                                                                                fontWeight: FontWeight.w500,
                                                                                                height: 1.21,
                                                                                            ),
                                                                                        ),
                                                                                    ),
                                                                                ),
                                                                                Positioned(
                                                                                    left: 101.69,
                                                                                    top: 0,
                                                                                    child: SizedBox(
                                                                                        width: 10,
                                                                                        height: 19.46,
                                                                                        child: Text(
                                                                                            'T',
                                                                                            textAlign: TextAlign.center,
                                                                                            style: TextStyle(
                                                                                                color: const Color(0x8834485E),
                                                                                                fontSize: 15.65,
                                                                                                fontFamily: 'Nunito',
                                                                                                fontWeight: FontWeight.w500,
                                                                                                height: 1.21,
                                                                                            ),
                                                                                        ),
                                                                                    ),
                                                                                ),
                                                                                Positioned(
                                                                                    left: 149.04,
                                                                                    top: 0,
                                                                                    child: SizedBox(
                                                                                        width: 15,
                                                                                        height: 19.46,
                                                                                        child: Text(
                                                                                            'W',
                                                                                            textAlign: TextAlign.center,
                                                                                            style: TextStyle(
                                                                                                color: const Color(0x8834485E),
                                                                                                fontSize: 15.65,
                                                                                                fontFamily: 'Nunito',
                                                                                                fontWeight: FontWeight.w500,
                                                                                                height: 1.21,
                                                                                            ),
                                                                                        ),
                                                                                    ),
                                                                                ),
                                                                                Positioned(
                                                                                    left: 202.83,
                                                                                    top: 0,
                                                                                    child: SizedBox(
                                                                                        width: 10,
                                                                                        height: 19.46,
                                                                                        child: Text(
                                                                                            'T',
                                                                                            textAlign: TextAlign.center,
                                                                                            style: TextStyle(
                                                                                                color: const Color(0x8834485E),
                                                                                                fontSize: 15.65,
                                                                                                fontFamily: 'Nunito',
                                                                                                fontWeight: FontWeight.w500,
                                                                                                height: 1.21,
                                                                                            ),
                                                                                        ),
                                                                                    ),
                                                                                ),
                                                                                Positioned(
                                                                                    left: 253.04,
                                                                                    top: 0,
                                                                                    child: SizedBox(
                                                                                        width: 10,
                                                                                        height: 19.46,
                                                                                        child: Text(
                                                                                            'F',
                                                                                            textAlign: TextAlign.center,
                                                                                            style: TextStyle(
                                                                                                color: const Color(0x8834485E),
                                                                                                fontSize: 15.65,
                                                                                                fontFamily: 'Nunito',
                                                                                                fontWeight: FontWeight.w500,
                                                                                                height: 1.21,
                                                                                            ),
                                                                                        ),
                                                                                    ),
                                                                                ),
                                                                                Positioned(
                                                                                    left: 303.47,
                                                                                    top: 0,
                                                                                    child: SizedBox(
                                                                                        width: 11,
                                                                                        height: 19.46,
                                                                                        child: Text(
                                                                                            'S',
                                                                                            textAlign: TextAlign.center,
                                                                                            style: TextStyle(
                                                                                                color: const Color(0x8834485E),
                                                                                                fontSize: 15.65,
                                                                                                fontFamily: 'Nunito',
                                                                                                fontWeight: FontWeight.w500,
                                                                                                height: 1.21,
                                                                                            ),
                                                                                        ),
                                                                                    ),
                                                                                ),
                                                                            ],
                                                                        ),
                                                                    ),
                                                                ),
                                                            ),
                                                        ],
                                                    ),
                                                ),
                                            ),
                                        ],
                                    ),
                                ),
                            ),
                            Positioned(
                                left: 298.37,
                                top: 27.71,
                                child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: ShapeDecoration(
                                        color: const Color(0xFFF7F8FC),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(11.29),
                                        ),
                                    ),
                                ),
                            ),
                            Positioned(
                                left: 332.37,
                                top: 27.71,
                                child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: ShapeDecoration(
                                        color: const Color(0xFFF7F8FC),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(11.29),
                                        ),
                                    ),
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        ],
    ),
)
    );
  }
}