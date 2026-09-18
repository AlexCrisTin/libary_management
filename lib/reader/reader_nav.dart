import 'package:flutter/material.dart';

const kBeige = Color(0xFFDBB9A0);
const kBeigeSoft = Color(0xFFEFE2D9);
const kBeigeButton = Color(0xFFE2C5B5);
const kBrownTitle = Color(0xFF8A6060);
const kBookTitle = Color(0xFF6F3636);
const kMuted = Color(0xFF939393);
const kCardFill = Color(0xFFF7F0EA);
const kCoverAsset = 'assets/img/F4bfd9e1649e82dcfdbe.jpg';

class ReaderBottomBar extends StatelessWidget {
  const ReaderBottomBar({
    super.key,
    required this.currentIndex,
    this.onSelect,
    this.onScan,
  });

  final int currentIndex;
  final ValueChanged<int>? onSelect;
  final VoidCallback? onScan;

  void _open(BuildContext context, int index) {
    onSelect?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: kBeigeSoft,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(context, 0, Icons.home_rounded),
              _item(context, 1, Icons.auto_stories_rounded),
              IconButton(
                tooltip: 'Quét mã QR sách',
                onPressed: onScan,
                icon: Icon(
                  Icons.camera_alt_rounded,
                  size: 28,
                  color: kBrownTitle.withValues(alpha: 0.6),
                ),
              ),
              _item(context, 3, Icons.menu_book_rounded),
              _item(context, 4, Icons.person_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int index, IconData icon) {
    final selected = currentIndex == index;
    return IconButton(
      onPressed: () => _open(context, index),
      icon: Icon(
        icon,
        size: 28,
        color: selected ? kBookTitle : kBrownTitle.withValues(alpha: 0.6),
      ),
    );
  }
}

class ChatFab extends StatelessWidget {
  const ChatFab({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: kBeigeSoft,
      onPressed: onPressed,
      child: const Icon(Icons.smart_toy_outlined, color: kBookTitle),
    );
  }
}

class BeigeHeader extends StatelessWidget {
  const BeigeHeader({super.key, required this.child, this.height});

  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: kBeige,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: SafeArea(bottom: false, child: child),
    );
  }
}

class SearchHeaderBar extends StatelessWidget {
  const SearchHeaderBar({
    super.key,
    this.initialText,
    this.readOnly = false,
    this.onTap,
    this.onSubmitted,
    this.trailing,
  });

  final String? initialText;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return BeigeHeader(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              readOnly: readOnly,
              onTap: onTap,
              controller: initialText == null
                  ? null
                  : TextEditingController(text: initialText),
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: 'Bạn muốn đọc gì................',
                hintStyle: TextStyle(
                  color: Colors.black.withValues(alpha: 0.20),
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

class TitleHeader extends StatelessWidget {
  const TitleHeader({
    super.key,
    required this.title,
    this.showBack = false,
    this.trailing,
    this.color = kBrownTitle,
  });

  final String title;
  final bool showBack;
  final Widget? trailing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return BeigeHeader(
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

class BookCover extends StatelessWidget {
  const BookCover({super.key, this.width = 89, this.height = 134});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        kCoverAsset,
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child});

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
            color: kBeigeButton,
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
            color: kCardFill,
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

class MenuRow extends StatelessWidget {
  const MenuRow({
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
      leading: Icon(icon, color: kBrownTitle, size: 28),
      title: Text(
        label,
        style: const TextStyle(
          color: kBrownTitle,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: kBrownTitle),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
