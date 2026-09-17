import 'package:flutter/material.dart';

class Signup extends StatelessWidget {
  const Signup({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const SizedBox(height: 80),
              const Text(
                'Đăng kí',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 36,
                  fontFamily: 'Arial',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 48),
              const TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Email',
                ),
              ),
              const SizedBox(height: 20),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Nhập mật khẩu',
                ),
              ),
              const SizedBox(height: 20),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Xác nhận mật khẩu',
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 70,
                height: 70,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDBB9A0),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white),
                ),
              ),
              const Spacer(),
              const Text(
                'Đăng kí bằng phương thức khác',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFBDBDBD),
                  fontSize: 15,
                  fontFamily: 'Arial',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFFD9D9D9),
                backgroundImage: const NetworkImage(
                  'https://placehold.co/34x34',
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Đăng nhập',
                  style: TextStyle(
                    color: Color(0xFFE9BCB9),
                    fontSize: 15,
                    fontFamily: 'Arial',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
