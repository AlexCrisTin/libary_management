import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';

import 'librarian_nav.dart';

class MessageDetail extends StatefulWidget {
  const MessageDetail({super.key, this.readerId, this.readerName});

  final String? readerId;
  final String? readerName;

  @override
  State<MessageDetail> createState() => _MessageDetailState();
}

class _MessageDetailState extends State<MessageDetail> {
  final _message = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final readerId = widget.readerId?.trim() ?? '';
    if (readerId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Không xác định được độc giả của cuộc trò chuyện.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = apiMap(
        await ApiClient.get(
          '/chat/conversations/$readerId/messages',
          query: {'limit': 100},
        ),
      );
      if (mounted) {
        setState(() => _messages = apiList(result['data']));
        _scrollToBottom();
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    final readerId = widget.readerId?.trim() ?? '';
    if (text.isEmpty || readerId.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final sent = apiMap(
        await ApiClient.post(
          '/chat/messages',
          body: {'reader_id': readerId, 'message_text': text},
        ),
      );
      if (!mounted) return;
      _message.clear();
      setState(() => _messages = [..._messages, sent]);
      _scrollToBottom();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          LibTitleHeader(
            title: widget.readerName?.trim().isNotEmpty == true
                ? widget.readerName!.trim()
                : 'Tin nhắn',
            showBack: true,
            color: Colors.white,
          ),
          Expanded(
            child: ApiStateView(
              loading: _loading,
              error: _error,
              isEmpty: _messages.isEmpty,
              onRetry: _load,
              emptyMessage: 'Chưa có tin nhắn. Hãy bắt đầu cuộc trò chuyện.',
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                itemCount: _messages.length,
                itemBuilder: (_, index) => _MessageBubble(
                  message: _messages[index],
                  mine: _messages[index]['sender_role'] != 'reader',
                ),
              ),
            ),
          ),
          _Composer(controller: _message, sending: _sending, onSend: _send),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});

  final Map<String, dynamic> message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: mine ? kLibBeigeButton : kLibCardFill,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 3),
            bottomRight: Radius.circular(mine ? 3 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                apiText(message['message_text']),
                style: const TextStyle(color: kLibBookTitle, fontSize: 15),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _messageTime(message['created_at']),
              style: TextStyle(
                color: kLibBrownTitle.withValues(alpha: .65),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Container(
          padding: const EdgeInsets.only(left: 14, right: 5),
          decoration: BoxDecoration(
            color: kLibCardFill,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: kLibBrownTitle),
                onPressed: sending ? null : onSend,
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _messageTime(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '';
  final now = DateTime.now();
  final time =
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return time;
  }
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')} $time';
}
