import 'package:flutter/material.dart';
import 'librarian_nav.dart';
import 'dashboard.dart';
import 'book_management.dart';
import 'borrow_return_book_management.dart';
import 'message_all.dart';
import 'notice.dart';
import 'profile_admin.dart';
import 'librarian_scanner.dart';
import 'reader_management.dart';
import 'report.dart';

/// Root shell for the Librarian role.
/// Hosts the 5-tab bottom nav and swaps the body page accordingly.
class LibrarianShell extends StatefulWidget {
  const LibrarianShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<LibrarianShell> createState() => _LibrarianShellState();
}

class _LibrarianShellState extends State<LibrarianShell> {
  late int _currentIndex;

  /// Pages matched to the 5 bottom-nav tabs:
  ///  0 → Dashboard
  ///  1 → Book Management
  ///  2 → Camera action
  ///  3 → Borrow/Return Management
  ///  4 → Reader Management
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardPage(
        onOpenTab: _onTabSelected,
        onOpenReaderManagement: () => _onTabSelected(4),
        onOpenReport: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Report()),
        ),
        onOpenMessages: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MessageAll()),
        ),
        onOpenProfile: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileAdmin()),
        ),
        onOpenNotice: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Notice()),
        ),
      ),
      const _BookManagementPage(),
      const SizedBox.shrink(),
      const _BorrowReturnPage(),
      const _ReaderManagementPage(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _currentIndex, children: pages),
      floatingActionButton: SizedBox(
        width: 110,
        height: 110,
        child: FloatingActionButton(
          heroTag: 'librarianMessages',
          backgroundColor: kLibBeigeSoft,
          elevation: 0,
          shape: const CircleBorder(),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MessageAll()),
          ),
          child: const Icon(
            Icons.more_horiz_rounded,
            size: 42,
            color: kLibBrownTitle,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: LibrarianBottomBar(
        currentIndex: _currentIndex,
        onSelect: _onTabSelected,
        onScan: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LibrarianScanner()),
        ),
      ),
    );
  }
}

// ─── Tab wrappers ─────────────────────────────────────────────────────────────
// Each wrapper is a thin layer so we can inject the nav callback if needed.
// Currently they just render the plain page widget.

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.onOpenTab,
    required this.onOpenReaderManagement,
    required this.onOpenReport,
    required this.onOpenMessages,
    required this.onOpenProfile,
    required this.onOpenNotice,
  });

  final ValueChanged<int> onOpenTab;
  final VoidCallback onOpenReaderManagement;
  final VoidCallback onOpenReport;
  final VoidCallback onOpenMessages;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenNotice;

  @override
  Widget build(BuildContext context) => Dashboard(
    onOpenTab: onOpenTab,
    onOpenReaderManagement: onOpenReaderManagement,
    onOpenReport: onOpenReport,
    onOpenMessages: onOpenMessages,
    onOpenProfile: onOpenProfile,
    onOpenNotice: onOpenNotice,
  );
}

class _BookManagementPage extends StatelessWidget {
  const _BookManagementPage();
  @override
  Widget build(BuildContext context) => const BookManagement();
}

class _BorrowReturnPage extends StatelessWidget {
  const _BorrowReturnPage();
  @override
  Widget build(BuildContext context) => const BorrowReturnBookManagement();
}

class _ReaderManagementPage extends StatelessWidget {
  const _ReaderManagementPage();
  @override
  Widget build(BuildContext context) => const ReaderManagement();
}
