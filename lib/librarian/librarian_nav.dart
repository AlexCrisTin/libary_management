import 'package:flutter/material.dart';

// ─── Color constants (same palette as reader) ────────────────────────────────
const kLibBeige = Color(0xFFDBB9A0);
const kLibBeigeSoft = Color(0xFFEFE2D9);
const kLibBeigeButton = Color(0xFFE2C5B5);
const kLibBrownTitle = Color(0xFF8A6060);
const kLibBookTitle = Color(0xFF6F3636);
const kLibGreen = Color(0xFF82D1A8);
const kLibRed = Color(0xFFD18282);
const kLibCardFill = Color(0xFFF7F0EA);

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────
/// Tabs: 0=Dashboard, 1=Books, 2=Borrow/Return, 3=Messages, 4=Profile
class LibrarianBottomBar extends StatelessWidget {
  const LibrarianBottomBar({
    super.key,
    required this.currentIndex,
    this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: kLibBeigeSoft,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(0, Icons.dashboard_rounded),
              _item(1, Icons.menu_book_rounded),
              _item(2, Icons.swap_horiz_rounded),
              _item(3, Icons.chat_bubble_outline_rounded),
              _item(4, Icons.person_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int index, IconData icon) {
    final selected = currentIndex == index;
    return IconButton(
      tooltip: _tooltip(index),
      onPressed: () => onSelect?.call(index),
      icon: Icon(
        icon,
        size: 28,
        color: selected ? kLibBookTitle : kLibBrownTitle.withValues(alpha: 0.6),
      ),
    );
  }

  String _tooltip(int index) {
    switch (index) {
      case 0:
        return 'Trang chủ';
      case 1:
        return 'Quản lý sách';
      case 2:
        return 'Mượn / Trả';
      case 3:
        return 'Tin nhắn';
      case 4:
        return 'Hồ sơ';
      default:
        return '';
    }
  }
}

// ─── Shared Beige Header ──────────────────────────────────────────────────────
class LibBeigeHeader extends StatelessWidget {
  const LibBeigeHeader({super.key, required this.child, this.height});

  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: kLibBeige,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: SafeArea(bottom: false, child: child),
    );
  }
}

// ─── Title Header (with optional back button) ─────────────────────────────────
class LibTitleHeader extends StatelessWidget {
  const LibTitleHeader({
    super.key,
    required this.title,
    this.showBack = false,
    this.trailing,
    this.color = kLibBrownTitle,
  });

  final String title;
  final bool showBack;
  final Widget? trailing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LibBeigeHeader(
      child: Row(
        children: [
          if (showBack)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            )
          else
            const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          trailing ?? const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ─── Search Header ────────────────────────────────────────────────────────────
class LibSearchHeader extends StatelessWidget {
  const LibSearchHeader({
    super.key,
    this.hint = 'Tìm kiếm...',
    this.onSubmitted,
    this.trailing,
  });

  final String hint;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LibBeigeHeader(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.black.withValues(alpha: 0.25),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                suffixIcon: const Icon(Icons.search, color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    width: 3,
                    color: Color(0xFFDDDDDD),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    width: 3,
                    color: Color(0xFFDDDDDD),
                  ),
                ),
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

// ─── Section Card (header + body) ────────────────────────────────────────────
class LibSectionCard extends StatelessWidget {
  const LibSectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: kLibBeigeButton,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: kLibCardFill,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(5),
              bottomRight: Radius.circular(5),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

// ─── Menu Row (settings list item) ───────────────────────────────────────────
class LibMenuRow extends StatelessWidget {
  const LibMenuRow({
    super.key,
    required this.label,
    this.icon = Icons.person_outline,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: kLibBrownTitle, size: 28),
      title: Text(
        label,
        style: const TextStyle(
          color: kLibBrownTitle,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: kLibBrownTitle),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
