import 'package:flutter/material.dart';
import 'librarian_nav.dart';
import 'dashboard.dart';
import 'book_management.dart';
import 'borrow_return_book_management.dart';
import 'message_all.dart';
import 'profile_admin.dart';
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
  ///  2 → Borrow/Return Management
  ///  3 → Messages
  ///  4 → Profile
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
        onOpenReaderManagement: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReaderManagement()),
        ),
        onOpenReport: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const Report()),
        ),
      ),
      const _BookManagementPage(),
      const _BorrowReturnPage(),
      const _MessagesPage(),
      const _ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: LibrarianBottomBar(
        currentIndex: _currentIndex,
        onSelect: _onTabSelected,
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
  });

  final ValueChanged<int> onOpenTab;
  final VoidCallback onOpenReaderManagement;
  final VoidCallback onOpenReport;

  @override
  Widget build(BuildContext context) => Dashboard(
    onOpenTab: onOpenTab,
    onOpenReaderManagement: onOpenReaderManagement,
    onOpenReport: onOpenReport,
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

class _MessagesPage extends StatelessWidget {
  const _MessagesPage();
  @override
  Widget build(BuildContext context) => const MessageAll();
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();
  @override
  Widget build(BuildContext context) => const ProfileAdmin();
}
