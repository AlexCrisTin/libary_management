import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';

import 'librarian_nav.dart';

class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _error;
  String _role = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = apiMap(
        await ApiClient.get(
          '/users',
          query: {
            'limit': 100,
            'keyword': _search.text.trim(),
            if (_role.isNotEmpty) 'role': _role,
          },
        ),
      );
      if (mounted) setState(() => _items = apiList(result['items']));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final username = TextEditingController();
    final password = TextEditingController();
    final fullName = TextEditingController();
    final email = TextEditingController();
    var role = 'librarian';
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tạo tài khoản'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(username, 'Tên đăng nhập'),
                _field(password, 'Mật khẩu', obscure: true),
                _field(fullName, 'Họ và tên'),
                _field(email, 'Email'),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(
                    labelText: 'Vai trò',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'librarian',
                      child: Text('Thủ thư'),
                    ),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => role = value ?? role),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
    if (submit == true && mounted) {
      try {
        await ApiClient.post(
          '/users',
          body: {
            'username': username.text.trim(),
            'password': password.text,
            'full_name': fullName.text.trim(),
            'email': email.text.trim(),
            'role': role,
          },
        );
        _show('Tạo tài khoản thành công.');
        await _load();
      } catch (error) {
        _show(error.toString());
      }
    }
    username.dispose();
    password.dispose();
    fullName.dispose();
    email.dispose();
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Future<void> _changeRole(Map<String, dynamic> user) async {
    var role = apiText(user['role'], fallback: 'librarian');
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Chọn vai trò'),
        children: ['reader', 'librarian', 'admin']
            .map(
              (value) => RadioListTile<String>(
                value: value,
                groupValue: role,
                title: Text(_roleLabel(value)),
                onChanged: (next) => Navigator.pop(context, next),
              ),
            )
            .toList(),
      ),
    );
    if (selected == null || selected == role) return;
    await _mutate('/users/${user['user_id']}/role', {
      'role': selected,
    }, 'Đã đổi vai trò.');
  }

  Future<void> _toggleStatus(Map<String, dynamic> user) async {
    final active = _isActive(user['is_active']);
    await _mutate(
      '/users/${user['user_id']}/status',
      {'is_active': !active},
      active ? 'Đã khóa tài khoản.' : 'Đã mở khóa tài khoản.',
    );
  }

  Future<void> _resetPassword(Map<String, dynamic> user) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đặt lại mật khẩu'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Mật khẩu mới (ít nhất 6 ký tự)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    final password = controller.text;
    controller.dispose();
    if (confirmed != true) return;
    await _mutate('/users/${user['user_id']}/reset-password', {
      'newPassword': password,
    }, 'Đã đặt lại mật khẩu.');
  }

  Future<void> _delete(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tài khoản?'),
        content: Text(
          'Tài khoản “${apiText(user['username'])}” sẽ bị xóa khỏi hệ thống.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kLibRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiClient.delete('/users/${user['user_id']}');
      _show('Đã xóa tài khoản.');
      await _load();
    } catch (error) {
      _show(error.toString());
    }
  }

  Future<void> _mutate(
    String path,
    Map<String, dynamic> body,
    String success,
  ) async {
    try {
      await ApiClient.put(path, body: body);
      _show(success);
      await _load();
    } catch (error) {
      _show(error.toString());
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isActive(dynamic value) =>
      value == true || value == 1 || value?.toString() == '1';

  String _roleLabel(String role) => switch (role) {
    'admin' => 'Quản trị viên',
    'librarian' => 'Thủ thư',
    'reader' => 'Độc giả',
    _ => role,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        LibTitleHeader(
          title: 'Quản lý tài khoản',
          showBack: true,
          trailing: IconButton(
            tooltip: 'Tạo tài khoản',
            onPressed: _create,
            icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onSubmitted: (_) => _load(),
                  decoration: const InputDecoration(
                    hintText: 'Tên, email, tài khoản...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _role,
                items: const [
                  DropdownMenuItem(value: '', child: Text('Tất cả')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'librarian', child: Text('Thủ thư')),
                  DropdownMenuItem(value: 'reader', child: Text('Độc giả')),
                ],
                onChanged: (value) {
                  setState(() => _role = value ?? '');
                  _load();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ApiStateView(
            loading: _loading,
            error: _error,
            isEmpty: _items.isEmpty,
            onRetry: _load,
            emptyMessage: 'Không tìm thấy tài khoản',
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final user = _items[index];
                  final active = _isActive(user['is_active']);
                  final self =
                      user['user_id']?.toString() ==
                      AppSession.user?['user_id']?.toString();
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kLibCardFill,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: active ? kLibBeigeButton : kLibRed,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                apiText(
                                  user['full_name'],
                                  fallback: apiText(user['username']),
                                ),
                                style: const TextStyle(
                                  color: kLibBookTitle,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text('@${apiText(user['username'])}'),
                              Text(
                                '${_roleLabel(apiText(user['role'], fallback: ''))} • ${active ? 'Đang hoạt động' : 'Đã khóa'}',
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'role') _changeRole(user);
                            if (action == 'status') _toggleStatus(user);
                            if (action == 'password') _resetPassword(user);
                            if (action == 'delete') _delete(user);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'role',
                              child: Text('Đổi vai trò'),
                            ),
                            PopupMenuItem(
                              value: 'status',
                              enabled: !self,
                              child: Text(active ? 'Khóa' : 'Mở khóa'),
                            ),
                            const PopupMenuItem(
                              value: 'password',
                              child: Text('Đặt lại mật khẩu'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              enabled: !self,
                              child: const Text('Xóa tài khoản'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
