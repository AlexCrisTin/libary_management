import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';

import 'librarian_nav.dart';

class LibrarianAiPage extends StatefulWidget {
  const LibrarianAiPage({super.key});

  @override
  State<LibrarianAiPage> createState() => _LibrarianAiPageState();
}

class _LibrarianAiPageState extends State<LibrarianAiPage> {
  static const _suggestions = <String>[
    'Thống kê tổng quan thư viện',
    'Những sách nào đang quá hạn?',
    'Thẻ độc giả nào sắp hết hạn?',
    'Sách nào được mượn nhiều nhất?',
  ];

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = const [];
  String? _conversationId;
  String _title = 'Cuộc trò chuyện mới';
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? suggestedText]) async {
    final text = (suggestedText ?? _messageController.text).trim();
    if (text.isEmpty || _sending) return;

    FocusScope.of(context).unfocus();
    final pendingMessage = <String, dynamic>{
      'role': 'user',
      'content': text,
      'pending': true,
    };
    setState(() {
      _sending = true;
      _messageController.clear();
      _messages = [..._messages, pendingMessage];
      if (_messages.length == 1) _title = text;
    });
    _scrollToBottom();

    try {
      final result = apiMap(
        await ApiClient.post(
          '/ai/librarian/chat',
          body: {
            'message': text,
            if (_conversationId != null) 'conversation_id': _conversationId,
          },
        ),
      );
      if (!mounted) return;
      setState(() {
        _conversationId = apiText(
          result['conversation_id'],
          fallback: _conversationId ?? '',
        );
        _messages = [
          ..._messages.take(_messages.length - 1),
          {...pendingMessage, 'pending': false},
          {
            'role': 'model',
            'content': apiText(
              result['answer'],
              fallback: 'AI không trả về nội dung.',
            ),
            'sources': result['sources'],
          },
        ];
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages = [
          ..._messages.take(_messages.length - 1),
          {...pendingMessage, 'pending': false, 'failed': true},
        ];
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('OPENROUTER_API_KEY')) {
      return 'Backend chưa được cấu hình OPENROUTER_API_KEY.';
    }
    if (message.contains('không đủ credit')) {
      return 'OpenRouter không đủ credit. Hãy chọn model miễn phí hoặc nạp thêm credit.';
    }
    return message;
  }

  void _newConversation() {
    setState(() {
      _conversationId = null;
      _title = 'Cuộc trò chuyện mới';
      _messages = const [];
    });
  }

  Future<void> _openHistory() async {
    try {
      final result = apiMap(
        await ApiClient.get(
          '/ai/librarian/conversations',
          query: {'limit': 50},
        ),
      );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        showDragHandle: true,
        builder: (sheetContext) => _HistorySheet(
          conversations: apiList(result['conversations']),
          selectedId: _conversationId,
          onNew: () {
            Navigator.pop(sheetContext);
            _newConversation();
          },
          onOpen: (conversation) async {
            Navigator.pop(sheetContext);
            await _loadConversation(conversation);
          },
          onDeleted: (id) {
            if (_conversationId == id) _newConversation();
          },
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _loadConversation(Map<String, dynamic> conversation) async {
    final id = apiText(conversation['conversation_id'], fallback: '');
    if (id.isEmpty) return;
    try {
      final result = apiMap(
        await ApiClient.get('/ai/librarian/conversations/$id'),
      );
      if (!mounted) return;
      final loadedConversation = apiMap(result['conversation']);
      setState(() {
        _conversationId = id;
        _title = apiText(
          loadedConversation['title'] ?? conversation['title'],
          fallback: 'Cuộc trò chuyện',
        );
        _messages = apiList(result['messages']);
      });
      _scrollToBottom(jump: true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Column(
        children: [
          LibTitleHeader(
            title: 'Trợ lý AI',
            showBack: true,
            trailing: IconButton(
              tooltip: 'Lịch sử trò chuyện',
              onPressed: _openHistory,
              icon: const Icon(Icons.history_rounded, color: Colors.white),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: kLibCardFill,
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _ConversationHeader(title: _title, onNew: _newConversation),
                    Expanded(
                      child: _messages.isEmpty
                          ? _Welcome(suggestions: _suggestions, onSelect: _send)
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                18,
                                14,
                                12,
                              ),
                              itemCount: _messages.length + (_sending ? 1 : 0),
                              itemBuilder: (_, index) {
                                if (index == _messages.length) {
                                  return const _TypingBubble();
                                }
                                return _AiMessageBubble(
                                  message: _messages[index],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _Composer(
            controller: _messageController,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _ConversationHeader extends StatelessWidget {
  const _ConversationHeader({required this.title, required this.onNew});

  final String title;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
    color: kLibBeigeButton,
    child: Row(
      children: [
        const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Cuộc trò chuyện mới',
          onPressed: onNew,
          icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        ),
      ],
    ),
  );
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.suggestions, required this.onSelect});

  final List<String> suggestions;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        const SizedBox(height: 18),
        Container(
          width: 76,
          height: 76,
          decoration: const BoxDecoration(
            color: kLibBeigeSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: kLibBrownTitle,
            size: 38,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Xin chào, tôi là Trợ lý AI Thủ thư',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kLibBookTitle,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tôi có thể tra cứu sách, độc giả, lượt mượn, tiền phạt và số liệu thư viện.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kLibBrownTitle.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        ...suggestions.map(
          (suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onSelect(suggestion),
                icon: const Icon(Icons.arrow_outward_rounded, size: 18),
                label: Text(suggestion),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kLibBrownTitle,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  side: const BorderSide(color: kLibBeigeButton),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _AiMessageBubble extends StatelessWidget {
  const _AiMessageBubble({required this.message});

  final Map<String, dynamic> message;

  @override
  Widget build(BuildContext context) {
    final mine = message['role'] == 'user';
    final failed = message['failed'] == true;
    final sources = message['sources'] is List
        ? (message['sources'] as List).whereType<Map>().toList()
        : const <Map>[];
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: mine ? kLibBeigeButton : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
          border: failed ? Border.all(color: kLibRed) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine) ...[
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: kLibBrownTitle,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Trợ lý AI',
                    style: TextStyle(
                      color: kLibBrownTitle,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
            ],
            Text(
              apiText(message['content'], fallback: ''),
              style: TextStyle(
                color: failed
                    ? kLibRed
                    : mine
                    ? Colors.white
                    : kLibBookTitle,
                fontSize: 15,
                height: 1.45,
              ),
            ),
            if (failed) ...[
              const SizedBox(height: 5),
              const Text(
                'Chưa gửi được',
                style: TextStyle(
                  color: kLibRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (sources.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: sources.map((source) {
                  final label = apiText(source['label'], fallback: 'Dữ liệu');
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: kLibBeigeSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: kLibBrownTitle,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: kLibBrownTitle,
            ),
          ),
        ),
      ),
    ),
  );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 4, 5, 4),
        decoration: BoxDecoration(
          color: kLibBeigeButton,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Hỏi về dữ liệu thư viện...',
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Gửi',
              onPressed: sending ? null : onSend,
              icon: Icon(
                Icons.send_rounded,
                color: sending
                    ? kLibBrownTitle.withValues(alpha: 0.35)
                    : kLibBrownTitle,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HistorySheet extends StatefulWidget {
  const _HistorySheet({
    required this.conversations,
    required this.selectedId,
    required this.onNew,
    required this.onOpen,
    required this.onDeleted,
  });

  final List<Map<String, dynamic>> conversations;
  final String? selectedId;
  final VoidCallback onNew;
  final ValueChanged<Map<String, dynamic>> onOpen;
  final ValueChanged<String> onDeleted;

  @override
  State<_HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<_HistorySheet> {
  late List<Map<String, dynamic>> _items;
  String? _deletingId;

  @override
  void initState() {
    super.initState();
    _items = [...widget.conversations];
  }

  Future<void> _delete(Map<String, dynamic> conversation) async {
    final id = apiText(conversation['conversation_id'], fallback: '');
    if (id.isEmpty || _deletingId != null) return;
    setState(() => _deletingId = id);
    try {
      await ApiClient.delete('/ai/librarian/conversations/$id');
      if (!mounted) return;
      setState(
        () => _items.removeWhere(
          (item) => item['conversation_id']?.toString() == id,
        ),
      );
      widget.onDeleted(id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.72,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Lịch sử Trợ lý AI',
              style: TextStyle(
                color: kLibBookTitle,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: widget.onNew,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Cuộc trò chuyện mới'),
              style: FilledButton.styleFrom(
                backgroundColor: kLibBeigeButton,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('Chưa có cuộc trò chuyện nào.'))
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final item = _items[index];
                        final id = apiText(
                          item['conversation_id'],
                          fallback: '',
                        );
                        return ListTile(
                          selected: id == widget.selectedId,
                          selectedTileColor: kLibBeigeSoft,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: kLibBrownTitle,
                          ),
                          title: Text(
                            apiText(item['title'], fallback: 'Cuộc trò chuyện'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(apiDate(item['updated_at'])),
                          onTap: () => widget.onOpen(item),
                          trailing: _deletingId == id
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  tooltip: 'Xoá',
                                  onPressed: () => _delete(item),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: kLibRed,
                                  ),
                                ),
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
