import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/core/local_image.dart';
import 'package:libary_management/reader/reader_nav.dart';

class ProfileDetail extends StatefulWidget {
  const ProfileDetail({super.key});

  @override
  State<ProfileDetail> createState() => _ProfileDetailState();
}

class _ProfileDetailState extends State<ProfileDetail> {
  Map<String, dynamic> _reader = const {};
  bool _loading = true;
  bool _uploadingAvatar = false;
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

  Future<void> _editText({
    required String title,
    required String field,
    required dynamic value,
    TextInputType keyboard = TextInputType.text,
  }) async {
    final controller = TextEditingController(
      text: apiText(value, fallback: ''),
    );
    final changed = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kCardFill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          title,
          style: const TextStyle(
            color: kBrownTitle,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: keyboard,
          autofocus: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kBrownTitle),
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (changed == null || changed == apiText(value, fallback: '')) return;
    if (field == 'full_name' && changed.isEmpty) {
      _showMessage('Họ và tên không được để trống.');
      return;
    }
    await _updateReader({field: changed.isEmpty ? null : changed});
  }

  Future<void> _editBirthDate() async {
    final current = DateTime.tryParse(_reader['birth_date']?.toString() ?? '');
    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Chọn ngày sinh',
    );
    if (selected == null) return;
    final value =
        '${selected.year.toString().padLeft(4, '0')}-'
        '${selected.month.toString().padLeft(2, '0')}-'
        '${selected.day.toString().padLeft(2, '0')}';
    await _updateReader({'birth_date': value});
  }

  Future<void> _updateReader(Map<String, dynamic> values) async {
    final id = AppSession.readerId;
    if (id == null) return;
    try {
      await ApiClient.put('/readers/$id', body: values);
      await _load();
      _showMessage('Cập nhật thông tin thành công.');
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _changePassword() async {
    final oldPassword = TextEditingController();
    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kCardFill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Đổi mật khẩu',
          style: TextStyle(color: kBrownTitle, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PasswordField(controller: oldPassword, label: 'Mật khẩu hiện tại'),
            const SizedBox(height: 12),
            _PasswordField(controller: newPassword, label: 'Mật khẩu mới'),
            const SizedBox(height: 12),
            _PasswordField(
              controller: confirmPassword,
              label: 'Nhập lại mật khẩu mới',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kBrownTitle),
            onPressed: () {
              if (newPassword.text.length < 6) {
                _showMessage('Mật khẩu mới phải có ít nhất 6 ký tự.');
                return;
              }
              if (newPassword.text != confirmPassword.text) {
                _showMessage('Mật khẩu nhập lại không khớp.');
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Đổi mật khẩu'),
          ),
        ],
      ),
    );

    if (submitted == true) {
      try {
        await ApiClient.put(
          '/auth/change-password',
          body: {
            'oldPassword': oldPassword.text,
            'newPassword': newPassword.text,
          },
        );
        _showMessage('Đổi mật khẩu thành công.');
      } catch (error) {
        _showMessage(error.toString());
      }
    }
    oldPassword.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
  }

  Future<void> _changeAvatar() async {
    if (_uploadingAvatar) return;
    final id = AppSession.readerId;
    if (id == null) {
      _showMessage('Tài khoản chưa liên kết hồ sơ độc giả.');
      return;
    }

    try {
      final data = await pickLocalImageAsDataUri();
      if (data == null) return;
      final bytes = decodeDataImage(data);
      if (bytes == null) {
        throw const FormatException('Không đọc được ảnh đại diện đã chọn.');
      }

      if (mounted) setState(() => _uploadingAvatar = true);
      final uploaded = apiMap(
        await ApiClient.uploadImage(
          '/uploads/reader-avatar',
          bytes: bytes,
          filename: 'reader-avatar.jpg',
        ),
      );
      final avatarUrl = apiText(uploaded['url'], fallback: '');
      if (avatarUrl.isEmpty) {
        throw const FormatException('Máy chủ không trả về đường dẫn ảnh.');
      }

      await ApiClient.put('/readers/$id', body: {'avatar_url': avatarUrl});
      await _load();
      _showMessage('Đổi ảnh đại diện thành công.');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _ProfileHeader(
            avatarUrl: _reader['avatar_url']?.toString(),
            uploading: _uploadingAvatar,
            onChangeAvatar: _changeAvatar,
          ),
          Expanded(
            child: ApiStateView(
              loading: _loading,
              error: _error,
              isEmpty: _reader.isEmpty,
              onRetry: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(27, 30, 27, 36),
                children: [
                  _InformationCard(
                    children: [
                      _ProfileRow(
                        label: 'Họ và tên',
                        value: apiText(_reader['full_name']),
                        onEdit: () => _editText(
                          title: 'Chỉnh sửa họ và tên',
                          field: 'full_name',
                          value: _reader['full_name'],
                        ),
                      ),
                      _ProfileRow(
                        label: 'Mã độc giả',
                        value: apiText(_reader['reader_code']),
                      ),
                      _ProfileRow(
                        label: 'Ngày sinh',
                        value: apiDate(_reader['birth_date']),
                        onEdit: _editBirthDate,
                      ),
                      _ProfileRow(
                        label: 'Số điện thoại',
                        value: apiText(_reader['phone']),
                        onEdit: () => _editText(
                          title: 'Chỉnh sửa số điện thoại',
                          field: 'phone',
                          value: _reader['phone'],
                          keyboard: TextInputType.phone,
                        ),
                      ),
                      _ProfileRow(
                        label: 'Email',
                        value: apiText(_reader['email']),
                        onEdit: () => _editText(
                          title: 'Chỉnh sửa email',
                          field: 'email',
                          value: _reader['email'],
                          keyboard: TextInputType.emailAddress,
                        ),
                      ),
                      _ProfileRow(
                        label: 'Khoa',
                        value: apiText(_reader['faculty']),
                        onEdit: () => _editText(
                          title: 'Chỉnh sửa khoa',
                          field: 'faculty',
                          value: _reader['faculty'],
                        ),
                      ),
                      _ProfileRow(
                        label: 'Hạn thẻ',
                        value: apiDate(_reader['card_expired']),
                      ),
                      _ProfileRow(
                        label: 'Đổi mật khẩu',
                        onEdit: _changePassword,
                        last: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.avatarUrl,
    required this.uploading,
    required this.onChangeAvatar,
  });

  final String? avatarUrl;
  final bool uploading;
  final VoidCallback onChangeAvatar;

  @override
  Widget build(BuildContext context) {
    final bytes = decodeDataImage(avatarUrl);
    final hasNetworkImage = avatarUrl != null && avatarUrl!.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      height: 226,
      decoration: const BoxDecoration(
        color: kBeige,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              left: 12,
              top: 2,
              child: IconButton(
                tooltip: 'Quay lại',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  const SizedBox(height: 5),
                  ClipOval(
                    child: Container(
                      width: 136,
                      height: 136,
                      color: kBeigeSoft,
                      child: bytes != null
                          ? Image.memory(bytes, fit: BoxFit.cover)
                          : hasNetworkImage
                          ? Image.network(
                              apiAssetUrl(avatarUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const _AvatarIcon(),
                            )
                          : const _AvatarIcon(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: uploading ? null : onChangeAvatar,
                    icon: uploading
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(Icons.image_rounded, color: Colors.white),
                    label: Text(
                      uploading ? 'Đang tải ảnh...' : 'Đổi ảnh',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarIcon extends StatelessWidget {
  const _AvatarIcon();

  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.person_rounded, color: kBrownTitle, size: 76);
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 49,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            color: kBeigeButton,
            alignment: Alignment.centerLeft,
            child: const Text(
              'Thông tin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            color: kCardFill,
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 13),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    this.value,
    this.onEdit,
    this.last = false,
  });

  final String label;
  final String? value;
  final VoidCallback? onEdit;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final text = value == null ? label : '$label: $value';
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(color: kBrownTitle.withValues(alpha: .35)),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: kBrownTitle,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onEdit != null)
            IconButton(
              tooltip: label,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, color: Color(0xFFD96B70)),
            ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: widget.label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
        ),
      ),
    );
  }
}
