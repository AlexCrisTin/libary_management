import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';

import 'form_addreader.dart';
import 'librarian_nav.dart';
import 'librarian_pagination.dart';
import 'reader_detail.dart';

class ReaderManagement extends StatefulWidget {
  const ReaderManagement({super.key});
  @override
  State<ReaderManagement> createState() => _ReaderManagementState();
}

class _ReaderManagementState extends State<ReaderManagement> {
  static const _pageSize = 20;

  final _search = TextEditingController();
  List<Map<String, dynamic>> _readers = const [];
  bool _loading = true;
  int _page = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  int _requestVersion = 0;
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

  Future<void> _load({int? page}) async {
    final targetPage = page ?? _page;
    final requestVersion = ++_requestVersion;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = apiMap(
        await ApiClient.get(
          '/readers',
          query: {
            'keyword': _search.text.trim(),
            'page': targetPage,
            'limit': _pageSize,
          },
        ),
      );
      if (!mounted || requestVersion != _requestVersion) return;
      final totalPages = int.tryParse('${result['totalPages']}') ?? 1;
      setState(() {
        _readers = apiList(result['items']);
        _page = int.tryParse('${result['page']}') ?? targetPage;
        _totalPages = totalPages < 1 ? 1 : totalPages;
        _totalItems = int.tryParse('${result['total']}') ?? _readers.length;
      });
    } catch (error) {
      if (mounted && requestVersion == _requestVersion) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted && requestVersion == _requestVersion) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Column(
        children: [
          const LibTitleHeader(title: 'Quản lý độc giả'),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 10, 11, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onSubmitted: (_) => _load(page: 1),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm độc giả...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : () => _load(),
                  icon: const Icon(Icons.refresh, color: kLibBrownTitle),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(11, 0, 11, 8),
            child: Row(
              children: [
                if (_error == null)
                  Expanded(
                    child: LibrarianPaginationBar(
                      margin: EdgeInsets.zero,
                      page: _page,
                      totalPages: _totalPages,
                      totalItems: _totalItems,
                      pageSize: _pageSize,
                      onPrevious: !_loading && _page > 1
                          ? () => _load(page: _page - 1)
                          : null,
                      onNext: !_loading && _page < _totalPages
                          ? () => _load(page: _page + 1)
                          : null,
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Thêm độc giả',
                  style: IconButton.styleFrom(backgroundColor: kLibBeigeButton),
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const FormAddReader()),
                    );
                    if (changed == true) _load(page: 1);
                  },
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
                  child: Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text('Mã', style: _header),
                  ),
                ),
                Expanded(flex: 3, child: Text('Họ tên', style: _header)),
                Expanded(flex: 3, child: Text('Số điện thoại', style: _header)),
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
              isEmpty: _readers.isEmpty,
              onRetry: _load,
              emptyMessage: 'Chưa có độc giả trong hệ thống',
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(11, 6, 11, 8),
                  itemCount: _readers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _ReaderRow(
                    reader: _readers[i],
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReaderDetail(
                            readerId: apiText(
                              _readers[i]['reader_id'],
                              fallback: '',
                            ),
                          ),
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
  fontSize: 13,
  fontWeight: FontWeight.w700,
);

class _ReaderRow extends StatelessWidget {
  const _ReaderRow({required this.reader, required this.onTap});
  final Map<String, dynamic> reader;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: kLibBrownTitle,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(apiText(reader['reader_code']), style: style),
          ),
          Expanded(
            flex: 3,
            child: Text(apiText(reader['full_name']), style: style),
          ),
          Expanded(
            flex: 3,
            child: Text(apiText(reader['phone']), style: style),
          ),
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
