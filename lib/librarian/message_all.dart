import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/core/local_image.dart';

import 'librarian_nav.dart';
import 'librarian_ai.dart';
import 'librarian_scanner.dart';
import 'librarian_shell.dart';
import 'message_detail.dart';

class MessageAll extends StatefulWidget {
  const MessageAll({super.key});

  @override
  State<MessageAll> createState() => _MessageAllState();
}

class _MessageAllState extends State<MessageAll> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _conversations = const [];
  bool _loading = true;
  bool _openingNew = false;
  String? _error;

  List<Map<String, dynamic>> get _visibleConversations {
    final keyword = _search.text.trim().toLowerCase();
    if (keyword.isEmpty) return _conversations;
    return _conversations.where((conversation) {
      return apiText(
            conversation['reader_name'],
            fallback: '',
          ).toLowerCase().contains(keyword) ||
          apiText(
            conversation['reader_code'],
            fallback: '',
          ).toLowerCase().contains(keyword) ||
          apiText(
            conversation['last_message'],
            fallback: '',
          ).toLowerCase().contains(keyword);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _search.addListener(_refreshSearch);
    _load();
  }

  @override
  void dispose() {
    _search
      ..removeListener(_refreshSearch)
      ..dispose();
    super.dispose();
  }

  void _refreshSearch() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = apiMap(
        await ApiClient.get('/chat/conversations', query: {'limit': 100}),
      );
      if (mounted) {
        setState(() => _conversations = apiList(result['data']));
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openConversation(Map<String, dynamic> reader) async {
    final readerId = apiText(reader['reader_id'], fallback: '');
    if (readerId.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessageDetail(
          readerId: readerId,
          readerName: apiText(
            reader['reader_name'] ?? reader['full_name'],
            fallback: 'Độc giả',
          ),
        ),
      ),
    );
    await _load();
  }

  Future<void> _startConversation() async {
    if (_openingNew) return;
    setState(() => _openingNew = true);
    try {
      final result = apiMap(
        await ApiClient.get('/readers', query: {'limit': 100}),
      );
      final readers = apiList(result['items']);
      if (!mounted) return;
      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        showDragHandle: true,
        builder: (_) => _ReaderPicker(readers: readers),
      );
      if (selected != null && mounted) await _openConversation(selected);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _openingNew = false);
    }
  }

  void _openTab(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LibrarianShell(initialIndex: index)),
      (_) => false,
    );
  }

  void _openAiAssistant() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LibrarianAiPage()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        const LibTitleHeader(
          title: 'Tin nhắn',
          color: kLibBrownTitle,
          showBack: true,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
              decoration: BoxDecoration(
                color: kLibCardFill,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _SearchRow(
                    controller: _search,
                    loading: _openingNew,
                    onAdd: _startConversation,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ApiStateView(
                      loading: _loading,
                      error: _error,
                      isEmpty: false,
                      onRetry: _load,
                      child: _visibleConversations.isEmpty
                          ? _EmptyConversations(
                              searching: _search.text.isNotEmpty,
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _visibleConversations.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, index) {
                                  final conversation =
                                      _visibleConversations[index];
                                  return _ConversationCard(
                                    conversation: conversation,
                                    onTap: () =>
                                        _openConversation(conversation),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 150,
                    height: 46,
                    child: FilledButton(
                      onPressed: _openAiAssistant,
                      style: FilledButton.styleFrom(
                        backgroundColor: kLibBookTitle,
                        foregroundColor: kLibBeigeSoft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('AI'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
    bottomNavigationBar: LibrarianBottomBar(
      currentIndex: -1,
      onSelect: _openTab,
      onScan: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LibrarianScanner()),
      ),
    ),
  );
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.loading,
    required this.onAdd,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 58,
        height: 58,
        child: FilledButton(
          onPressed: loading ? null : onAdd,
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: kLibBeigeButton,
            disabledBackgroundColor: kLibBeigeButton,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.add, color: Colors.white, size: 38),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: SizedBox(
          height: 58,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Tìm độc giả hoặc tin nhắn...',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18),
              suffixIcon: const Icon(
                Icons.search,
                color: kLibBrownTitle,
                size: 31,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.conversation, required this.onTap});

  final Map<String, dynamic> conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = int.tryParse('${conversation['unread_count'] ?? 0}') ?? 0;
    final fromLibrarian = conversation['last_sender_role'] == 'librarian';
    return Material(
      color: kLibBeigeButton,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 78,
                child: Column(
                  children: [
                    _SmallAvatar(url: conversation['avatar_url']?.toString()),
                    const SizedBox(height: 8),
                    Text(
                      apiText(conversation['reader_name'], fallback: 'Độc giả'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _conversationTime(conversation['last_message_time']),
                          style: const TextStyle(
                            color: kLibBookTitle,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (unread > 0) _UnreadBadge(count: unread),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 72),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${fromLibrarian ? 'Bạn: ' : ''}'
                        '${apiText(conversation['last_message'], fallback: '')}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: kLibBrownTitle.withValues(alpha: .7),
                          fontSize: 13,
                          fontWeight: unread > 0
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
    padding: const EdgeInsets.symmetric(horizontal: 6),
    alignment: Alignment.center,
    decoration: const BoxDecoration(color: kLibRed, shape: BoxShape.circle),
    child: Text(
      count > 99 ? '99+' : '$count',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({required this.url, this.size = 58});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final value = url?.trim() ?? '';
    final bytes = decodeDataImage(value);
    final fallback = Container(
      color: kLibBeigeSoft,
      alignment: Alignment.center,
      child: const Icon(Icons.person, color: kLibBrownTitle),
    );
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: bytes != null
            ? Image.memory(bytes, fit: BoxFit.cover)
            : value.isEmpty
            ? fallback
            : Image.network(
                apiAssetUrl(value),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              ),
      ),
    );
  }
}

class _ReaderPicker extends StatefulWidget {
  const _ReaderPicker({required this.readers});

  final List<Map<String, dynamic>> readers;

  @override
  State<_ReaderPicker> createState() => _ReaderPickerState();
}

class _ReaderPickerState extends State<_ReaderPicker> {
  final _search = TextEditingController();

  List<Map<String, dynamic>> get _visibleReaders {
    final keyword = _search.text.trim().toLowerCase();
    if (keyword.isEmpty) return widget.readers;
    return widget.readers.where((reader) {
      return apiText(
            reader['full_name'],
            fallback: '',
          ).toLowerCase().contains(keyword) ||
          apiText(
            reader['reader_code'],
            fallback: '',
          ).toLowerCase().contains(keyword);
    }).toList();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        0,
        18,
        18 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .68,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tin nhắn mới',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kLibBrownTitle,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tìm tên hoặc mã độc giả',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _visibleReaders.isEmpty
                  ? const Center(child: Text('Không tìm thấy độc giả'))
                  : ListView.separated(
                      itemCount: _visibleReaders.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final reader = _visibleReaders[index];
                        return ListTile(
                          leading: _SmallAvatar(
                            url: reader['avatar_url']?.toString(),
                            size: 44,
                          ),
                          title: Text(apiText(reader['full_name'])),
                          subtitle: Text(apiText(reader['reader_code'])),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pop(context, reader),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyConversations extends StatelessWidget {
  const _EmptyConversations({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      searching
          ? 'Không tìm thấy cuộc trò chuyện'
          : 'Chưa có cuộc trò chuyện. Nhấn + để bắt đầu.',
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: kLibBrownTitle,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

String _conversationTime(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '';
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}';
}
