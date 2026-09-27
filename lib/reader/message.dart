import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/reader/qr_scanner.dart';
import 'package:libary_management/reader/reader_nav.dart';

class Message extends StatefulWidget {
  const Message({super.key, this.onSelectTab});

  final ValueChanged<int>? onSelectTab;

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {
  final _controller = TextEditingController();
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
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = apiMap(
        await ApiClient.get('/chat/messages', query: {'limit': 100}),
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
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final sent = apiMap(
        await ApiClient.post('/chat/messages', body: {'message_text': text}),
      );
      if (!mounted) return;
      _controller.clear();
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

  void _selectTab(int index) {
    Navigator.pop(context);
    widget.onSelectTab?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const BeigeHeader(
            height: 112,
            child: Center(
              child: Text(
                'Tin nhắn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 54,
            margin: const EdgeInsets.fromLTRB(28, 16, 28, 12),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: kBeigeButton,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
            child: const Text(
              'Thủ thư',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(28, 0, 28, 12),
              decoration: BoxDecoration(
                color: kCardFill,
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: ApiStateView(
                loading: _loading,
                error: _error,
                isEmpty: _messages.isEmpty,
                onRetry: _load,
                emptyMessage: 'Chưa có tin nhắn. Hãy gửi lời chào tới thủ thư.',
                child: RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    itemCount: _messages.length,
                    itemBuilder: (_, index) {
                      final message = _messages[index];
                      return _ReaderMessageBubble(
                        message: message,
                        mine: message['sender_role'] == 'reader',
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            bottom: false,
            child: Container(
              height: 54,
              margin: const EdgeInsets.fromLTRB(28, 0, 28, 14),
              padding: const EdgeInsets.fromLTRB(9, 6, 7, 6),
              decoration: BoxDecoration(
                color: kBeigeButton,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  IconButton(
                    tooltip: 'Gửi tin nhắn',
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: kBrownTitle,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: kBrownTitle,
                            size: 31,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ReaderBottomBar(
        currentIndex: 0,
        onSelect: _selectTab,
        onScan: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QrScanner()),
        ),
      ),
    );
  }
}

class _ReaderMessageBubble extends StatelessWidget {
  const _ReaderMessageBubble({required this.message, required this.mine});

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
          color: mine ? kBeigeButton : kCardFill,
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
                style: const TextStyle(color: kBookTitle, fontSize: 15),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _time(message['created_at']),
              style: TextStyle(
                color: kBrownTitle.withValues(alpha: .65),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _time(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}
