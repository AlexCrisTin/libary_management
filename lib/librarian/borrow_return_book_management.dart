import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';

import 'borrow_return_detail.dart';
import 'librarian_nav.dart';

class BorrowReturnBookManagement extends StatefulWidget {
  const BorrowReturnBookManagement({super.key});
  @override
  State<BorrowReturnBookManagement> createState() =>
      _BorrowReturnBookManagementState();
}

class _BorrowReturnBookManagementState
    extends State<BorrowReturnBookManagement> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _loans = const [];
  bool _loading = true;
  String? _error;
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
          '/circulation/active',
          query: {'keyword': _search.text.trim(), 'limit': 100},
        ),
      );
      if (mounted) setState(() => _loans = apiList(result['data']));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Column(
        children: [
          const LibTitleHeader(title: 'Quản lý mượn / trả'),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onSubmitted: (_) => _load(),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh, color: kLibBrownTitle),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 11),
            height: 44,
            decoration: BoxDecoration(
              color: kLibBeigeButton,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Center(child: Text('Độc giả', style: _header)),
                ),
                Expanded(
                  flex: 2,
                  child: Center(child: Text('Sách', style: _header)),
                ),
                Expanded(
                  flex: 2,
                  child: Center(child: Text('Ngày mượn', style: _header)),
                ),
                Expanded(
                  flex: 2,
                  child: Center(child: Text('Ngày trả', style: _header)),
                ),
                Expanded(
                  flex: 2,
                  child: Center(child: Text('Chi tiết', style: _header)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ApiStateView(
              loading: _loading,
              error: _error,
              isEmpty: _loans.isEmpty,
              onRetry: _load,
              emptyMessage: 'Không có lượt mượn đang hoạt động',
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(11, 6, 11, 8),
                  itemCount: _loans.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _LoanRow(
                    loan: _loans[i],
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BorrowReturnDetail(loan: _loans[i]),
                        ),
                      );
                      _load();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

const _header = TextStyle(
  color: Colors.white,
  fontSize: 11,
  fontWeight: FontWeight.w700,
);

class _LoanRow extends StatelessWidget {
  const _LoanRow({required this.loan, required this.onTap});
  final Map<String, dynamic> loan;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: kLibBrownTitle,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    Widget cell(String text, int flex) => Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          cell(apiText(loan['reader_name']), 2),
          cell(apiText(loan['book_title']), 2),
          cell(apiDate(loan['borrow_date']), 2),
          cell(apiDate(loan['due_date']), 2),
          Expanded(
            flex: 2,
            child: Center(
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: kLibBeigeButton),
                onPressed: onTap,
                icon: const Icon(Icons.chevron_right, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
