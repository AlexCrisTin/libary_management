import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/reader/reader_nav.dart';

class ProfileDetail extends StatefulWidget {
  const ProfileDetail({super.key});
  @override
  State<ProfileDetail> createState() => _ProfileDetailState();
}

class _ProfileDetailState extends State<ProfileDetail> {
  Map<String, dynamic> _reader = const {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = AppSession.readerId;
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'Tài khoản chưa liên kết hồ sơ độc giả.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = apiMap(await ApiClient.get('/readers/$id'));
      if (mounted) setState(() => _reader = data);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        const TitleHeader(title: 'Thông tin cá nhân', showBack: true),
        Expanded(
          child: ApiStateView(
            loading: _loading,
            error: _error,
            isEmpty: _reader.isEmpty,
            onRetry: _load,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                SectionCard(
                  title: 'Thông tin',
                  child: Column(
                    children: [
                      MenuRow(
                        label: 'Họ và tên: ${apiText(_reader['full_name'])}',
                      ),
                      MenuRow(
                        label: 'Mã độc giả: ${apiText(_reader['reader_code'])}',
                        icon: Icons.tag,
                      ),
                      MenuRow(
                        label: 'Ngày sinh: ${apiDate(_reader['birth_date'])}',
                        icon: Icons.cake_outlined,
                      ),
                      MenuRow(
                        label: 'Số điện thoại: ${apiText(_reader['phone'])}',
                        icon: Icons.phone_outlined,
                      ),
                      MenuRow(
                        label: 'Email: ${apiText(_reader['email'])}',
                        icon: Icons.email_outlined,
                      ),
                      MenuRow(
                        label: 'Hạn thẻ: ${apiDate(_reader['card_expired'])}',
                        icon: Icons.event,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
