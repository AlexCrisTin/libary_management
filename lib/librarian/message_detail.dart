import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/core/local_image.dart';

import 'librarian_nav.dart';
import 'librarian_scanner.dart';
import 'librarian_shell.dart';

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
  Map<String, dynamic> _reader = const {};
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
      final responses = await Future.wait<dynamic>([
        ApiClient.get(
          '/chat/conversations/$readerId/messages',
          query: {'limit': 100},
        ),
        ApiClient.get(
          '/readers/$readerId',
        ).catchError((_) => const <String, dynamic>{}),
      ]);
      if (!mounted) return;
      final result = apiMap(responses.first);
      setState(() {
        _messages = apiList(result['data']);
        _reader = apiMap(responses.last);
      });
      _scrollToBottom(jump: true);
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
    FocusScope.of(context).unfocus();
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

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if (jump) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openTab(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LibrarianShell(initialIndex: index)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final name = apiText(
      _reader['full_name'] ?? widget.readerName,
      fallback: 'Độc giả',
    );
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const LibTitleHeader(
            title: 'Tin nhắn',
            showBack: true,
            color: Colors.white,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Column(
                children: [
                  _ReaderBanner(reader: _reader, fallbackName: name),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: kLibCardFill,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ApiStateView(
                        loading: _loading,
                        error: _error,
                        isEmpty: false,
                        onRetry: _load,
                        child: RefreshIndicator(
                          onRefresh: _load,
                          child: _messages.isEmpty
                              ? const _EmptyConversation()
                              : ListView.builder(
                                  controller: _scroll,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    18,
                                    14,
                                    10,
                                  ),
                                  itemCount: _messages.length,
                                  itemBuilder: (_, index) => _MessageBubble(
                                    message: _messages[index],
                                    mine:
                                        _messages[index]['sender_role'] !=
                                        'reader',
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Composer(
                    controller: _message,
                    sending: _sending,
                    onSend: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: keyboardOpen
          ? null
          : LibrarianBottomBar(
              currentIndex: -1,
              onSelect: _openTab,
              onScan: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LibrarianScanner()),
              ),
            ),
    );
  }
}

class _ReaderBanner extends StatelessWidget {
  const _ReaderBanner({required this.reader, required this.fallbackName});

  final Map<String, dynamic> reader;
  final String fallbackName;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: BoxDecoration(
      color: const Color(0xFFF5A071),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        _ReaderAvatar(url: reader['avatar_url']?.toString()),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                apiText(reader['full_name'], fallback: fallbackName),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Mã độc giả: ${apiText(reader['reader_code'])}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
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

class _ReaderAvatar extends StatelessWidget {
  const _ReaderAvatar({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final value = url?.trim() ?? '';
    final Uint8List? bytes = decodeDataImage(value);
    final image = bytes != null
        ? Image.memory(bytes, fit: BoxFit.cover)
        : value.isNotEmpty
        ? Image.network(
            apiAssetUrl(value),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _AvatarPlaceholder(),
          )
        : const _AvatarPlaceholder();
    return ClipOval(child: SizedBox(width: 76, height: 76, child: image));
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: kLibBeigeSoft,
    child: Icon(Icons.person_rounded, color: kLibBrownTitle, size: 38),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});

  final Map<String, dynamic> message;
  final bool mine;

  @override
  Widget build(BuildContext context) => Align(
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * .7,
      ),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: BoxDecoration(
        color: mine ? kLibBeigeButton : Colors.white,
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

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: constraints.maxHeight,
        child: const Center(
          child: Text(
            'Chưa có tin nhắn.\nHãy bắt đầu cuộc trò chuyện.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kLibBrownTitle,
              fontWeight: FontWeight.w600,
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
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 62),
    padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
    decoration: BoxDecoration(
      color: kLibBeigeButton,
      borderRadius: BorderRadius.circular(15),
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
            decoration: InputDecoration(
              hintText: 'Nhập tin nhắn...',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Gửi tin nhắn',
          onPressed: sending ? null : onSend,
          icon: sending
              ? const SizedBox(
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator(
                    color: kLibBrownTitle,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.send_rounded, color: kLibBrownTitle, size: 34),
        ),
      ],
    ),
  );
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
