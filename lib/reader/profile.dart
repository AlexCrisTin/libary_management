import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/core/local_image.dart';
import 'package:libary_management/login/login.dart';
import 'package:libary_management/reader/fine.dart';
import 'package:libary_management/reader/history.dart';
import 'package:libary_management/reader/holds.dart';
import 'package:libary_management/reader/profile_detail.dart';
import 'package:libary_management/reader/reader_nav.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Map<String, dynamic> _reader = const {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final readerId = AppSession.readerId;
    if (readerId == null) {
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
      final reader = apiMap(await ApiClient.get('/readers/$readerId'));
      if (mounted) setState(() => _reader = reader);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openProfileDetail() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileDetail()),
    );
    await _load();
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _showLibraryCard() {
    final status = _reader['status']?.toString();
    final statusText = switch (status) {
      'active' => 'Đang hoạt động',
      'suspended' => 'Tạm khóa',
      'expired' => 'Đã hết hạn',
      _ => apiText(status),
    };
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: kCardFill,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Thẻ thư viện',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kBrownTitle,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              _CardInfoRow(
                label: 'Mã độc giả',
                value: apiText(_reader['reader_code']),
              ),
              _CardInfoRow(label: 'Trạng thái', value: statusText),
              _CardInfoRow(
                label: 'Ngày cấp',
                value: apiDate(_reader['card_issued']),
              ),
              _CardInfoRow(
                label: 'Ngày hết hạn',
                value: apiDate(_reader['card_expired']),
              ),
              _CardInfoRow(
                label: 'Số sách tối đa',
                value: apiText(_reader['max_books']),
                last: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    try {
      final preferences = apiMap(
        await ApiClient.get('/readers/me/preferences'),
      );
      final notification = apiMap(preferences['notification_pref']);
      var inApp = notification['app'] != false;
      var email = notification['email'] != false;
      var sms = notification['sms'] == true;
      if (!mounted) return;

      final saved = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: kCardFill,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Cài đặt thông báo',
                    style: TextStyle(
                      color: kBrownTitle,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    activeColor: kBrownTitle,
                    title: const Text('Thông báo trong ứng dụng'),
                    value: inApp,
                    onChanged: (value) => setSheetState(() => inApp = value),
                  ),
                  SwitchListTile(
                    activeColor: kBrownTitle,
                    title: const Text('Thông báo qua email'),
                    value: email,
                    onChanged: (value) => setSheetState(() => email = value),
                  ),
                  SwitchListTile(
                    activeColor: kBrownTitle,
                    title: const Text('Thông báo qua SMS'),
                    value: sms,
                    onChanged: (value) => setSheetState(() => sms = value),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 150,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: kBrownTitle,
                      ),
                      onPressed: () => Navigator.pop(sheetContext, true),
                      child: const Text('Lưu cài đặt'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (saved != true) return;
      await ApiClient.put(
        '/readers/me/preferences',
        body: {
          'preferred_subjects': preferences['preferred_subjects'] ?? const [],
          'preferred_authors': preferences['preferred_authors'] ?? const [],
          'preferred_langs': preferences['preferred_langs'] ?? const ['vi'],
          'reading_pace': preferences['reading_pace'] ?? 'medium',
          'notification_pref': {'app': inApp, 'email': email, 'sms': sms},
        },
      );
      _showMessage('Đã lưu cài đặt thông báo.');
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Readily',
      applicationVersion: '1.0.0',
      applicationIcon: const CircleAvatar(
        backgroundColor: kBeigeSoft,
        child: Icon(Icons.local_library_rounded, color: kBrownTitle),
      ),
      children: const [
        Text(
          'Ứng dụng quản lý thư viện giúp độc giả tìm kiếm sách, theo dõi '
          'lịch mượn trả, nhận thông báo và liên hệ với thủ thư.',
        ),
      ],
    );
  }

  void _logout() {
    AppSession.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Login()),
      (_) => false,
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfileBanner(reader: _reader),
        Expanded(
          child: ApiStateView(
            loading: _loading,
            error: _error,
            isEmpty: _reader.isEmpty,
            onRetry: _load,
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(27, 30, 27, 36),
                children: [
                  _ProfileMenuCard(
                    title: 'Tài khoản',
                    children: [
                      _ProfileMenuRow(
                        label: 'Thông tin cá nhân',
                        icon: Icons.person_rounded,
                        onTap: _openProfileDetail,
                      ),
                      _ProfileMenuRow(
                        label: 'Lịch sử mượn/trả sách',
                        icon: Icons.receipt_long_rounded,
                        onTap: () => _open(const History()),
                      ),
                      _ProfileMenuRow(
                        label: 'Tiền phạt',
                        icon: Icons.warning_rounded,
                        onTap: () => _open(const Fine()),
                      ),
                      _ProfileMenuRow(
                        label: 'Sách đã đặt trước',
                        icon: Icons.bookmark_rounded,
                        onTap: () => _open(const ReaderHolds()),
                      ),
                      _ProfileMenuRow(
                        label: 'Thẻ thư viện',
                        icon: Icons.badge_rounded,
                        onTap: _showLibraryCard,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _ProfileMenuCard(
                    title: 'Cài đặt khác',
                    children: [
                      _ProfileMenuRow(
                        label: 'Cài đặt',
                        icon: Icons.settings_rounded,
                        onTap: _openSettings,
                      ),
                      _ProfileMenuRow(
                        label: 'Thông tin khác',
                        icon: Icons.info_rounded,
                        onTap: _showAbout,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: SizedBox(
                      width: 152,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF26A6D),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: const Text(
                          'Đăng xuất',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
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
    );
  }
}

class _ProfileBanner extends StatelessWidget {
  const _ProfileBanner({required this.reader});

  final Map<String, dynamic> reader;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = reader['avatar_url']?.toString();
    final bytes = decodeDataImage(avatarUrl);
    final hasNetworkImage = avatarUrl != null && avatarUrl.trim().isNotEmpty;
    return BeigeHeader(
      height: 226,
      child: Row(
        children: [
          ClipOval(
            child: Container(
              width: 118,
              height: 118,
              color: kBeigeSoft,
              child: bytes != null
                  ? Image.memory(bytes, fit: BoxFit.cover)
                  : hasNetworkImage
                  ? Image.network(
                      apiAssetUrl(avatarUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _AvatarPlaceholder(),
                    )
                  : const _AvatarPlaceholder(),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  apiText(
                    reader['full_name'],
                    fallback: AppSession.displayName,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  apiText(
                    reader['email'] ?? AppSession.user?['email'],
                    fallback: '',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.person_rounded, color: kBrownTitle, size: 66);
}

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            alignment: Alignment.centerLeft,
            color: kBeigeButton,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            color: kCardFill,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 39,
                child: Icon(icon, color: kBrownTitle, size: 31),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: kBrownTitle,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: kBrownTitle,
                size: 31,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardInfoRow extends StatelessWidget {
  const _CardInfoRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(color: kBrownTitle.withValues(alpha: .2)),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: kBrownTitle,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: kBookTitle,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
