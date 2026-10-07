import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/librarian/librarian_shell.dart';
import 'package:libary_management/login/forgotpassword.dart';
import 'package:libary_management/login/signup.dart';
import 'package:libary_management/reader/home.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  Timer? _developerModeTimer;
  bool _openingDeveloperMode = false;

  @override
  void dispose() {
    _developerModeTimer?.cancel();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _startDeveloperModeTimer() {
    _developerModeTimer?.cancel();
    _developerModeTimer = Timer(const Duration(seconds: 10), () async {
      if (!mounted || _openingDeveloperMode) return;
      _openingDeveloperMode = true;
      await HapticFeedback.mediumImpact();
      if (mounted) await _showDeveloperMode();
      _openingDeveloperMode = false;
    });
  }

  void _cancelDeveloperModeTimer() {
    _developerModeTimer?.cancel();
    _developerModeTimer = null;
  }

  Future<void> _showDeveloperMode() async {
    final server = TextEditingController(text: ApiClient.baseUrl);
    var checking = false;
    String? error;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.developer_mode_rounded),
              SizedBox(width: 10),
              Text('Developer Mode'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Nhập IP Wi-Fi của máy chạy backend. Có thể nhập IP hoặc toàn bộ địa chỉ API.',
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: server,
                  enabled: !checking,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ máy chủ',
                    hintText: '192.168.1.10',
                    border: const OutlineInputBorder(),
                    errorText: error,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ứng dụng sẽ tự thêm http://, cổng 3000 và /api nếu bạn chỉ nhập IP.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: checking
                  ? null
                  : () async {
                      await ApiClient.resetBaseUrl();
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      _show('Đã chuyển về địa chỉ máy chủ mặc định.');
                    },
              child: const Text('Mặc định'),
            ),
            TextButton(
              onPressed: checking ? null : () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: checking
                  ? null
                  : () async {
                      setDialogState(() {
                        checking = true;
                        error = null;
                      });
                      try {
                        await ApiClient.testServer(server.text);
                        final saved = await ApiClient.saveBaseUrl(server.text);
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        _show('Đã kết nối và lưu máy chủ: $saved');
                      } catch (exception) {
                        setDialogState(() {
                          checking = false;
                          error = exception is FormatException
                              ? exception.message
                              : 'Không kết nối được. Kiểm tra IP, Wi-Fi và backend.';
                        });
                      }
                    },
              child: checking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kiểm tra & lưu'),
            ),
          ],
        ),
      ),
    );
    server.dispose();
  }

  Future<void> _login() async {
    if (_username.text.trim().isEmpty || _password.text.isEmpty) {
      _show('Vui lòng nhập tên đăng nhập và mật khẩu.');
      return;
    }
    setState(() => _loading = true);
    try {
      final data = apiMap(
        await ApiClient.post(
          '/auth/login',
          body: {'username': _username.text.trim(), 'password': _password.text},
        ),
      );
      AppSession.setAuth(data);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              AppSession.isReader ? const Home() : const LibrarianShell(),
        ),
        (_) => false,
      );
    } catch (error) {
      _show(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const SizedBox(height: 80),
              const Text(
                'Đăng nhập',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 56),
              TextField(
                controller: _username,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Tên đăng nhập',
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _password,
                obscureText: true,
                onSubmitted: (_) => _login(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Mật khẩu',
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPassword()),
                ),
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
                    color: Color(0xFFE9BCB9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 70,
                height: 70,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDBB9A0),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_forward, color: Colors.white),
                ),
              ),
              const SizedBox(height: 48),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Signup()),
                ),
                child: const Text(
                  'Tạo tài khoản',
                  style: TextStyle(
                    color: Color(0xFFE9BCB9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 52),
              Tooltip(
                message: 'Giữ 10 giây',
                child: Listener(
                  onPointerDown: (_) => _startDeveloperModeTimer(),
                  onPointerUp: (_) => _cancelDeveloperModeTimer(),
                  onPointerCancel: (_) => _cancelDeveloperModeTimer(),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'Readily • kết nối',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: .16),
                        fontSize: 11,
                        letterSpacing: .4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
