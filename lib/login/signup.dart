import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/reader/home.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    for (final controller in [_name, _username, _email, _password, _confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (_name.text.trim().isEmpty ||
        _username.text.trim().isEmpty ||
        _password.text.isEmpty) {
      _show('Vui lòng nhập họ tên, tên đăng nhập và mật khẩu.');
      return;
    }
    if (_password.text != _confirm.text) {
      _show('Mật khẩu xác nhận không khớp.');
      return;
    }
    setState(() => _loading = true);
    try {
      final data = apiMap(
        await ApiClient.post(
          '/auth/register',
          body: {
            'full_name': _name.text.trim(),
            'username': _username.text.trim(),
            'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
            'password': _password.text,
          },
        ),
      );
      AppSession.setAuth(data);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Home()),
        (_) => false,
      );
    } catch (error) {
      _show(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(40, 12, 40, 32),
        child: Column(
          children: [
            const Text(
              'Đăng kí',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 32),
            _field(_name, 'Họ và tên'),
            _field(_username, 'Tên đăng nhập'),
            _field(_email, 'Email', keyboard: TextInputType.emailAddress),
            _field(_password, 'Mật khẩu', obscure: true),
            _field(_confirm, 'Xác nhận mật khẩu', obscure: true),
            const SizedBox(height: 16),
            SizedBox(
              width: 70,
              height: 70,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDBB9A0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: label,
        ),
      ),
    );
  }
}
