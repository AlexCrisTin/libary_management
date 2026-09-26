import 'package:flutter/material.dart';
import 'package:libary_management/core/api_client.dart';
import 'package:libary_management/core/api_state.dart';
import 'package:libary_management/core/local_image.dart';

import 'librarian_nav.dart';
import 'message_detail.dart';

class MessageAll extends StatefulWidget {
  const MessageAll({super.key});

  @override
  State<MessageAll> createState() => _MessageAllState();
}

class _MessageAllState extends State<MessageAll> {
  List<Map<String, dynamic>> _conversations = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const LibTitleHeader(
            title: 'Tin nhắn',
            color: Colors.white,
            showBack: true,
          ),
          Expanded(
            child: ApiStateView(
              loading: _loading,
              error: _error,
              isEmpty: _conversations.isEmpty,
              onRetry: _load,
              emptyMessage: 'Chưa có cuộc trò chuyện nào',
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: _conversations.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 82, endIndent: 18),
                  itemBuilder: (_, index) {
                    final conversation = _conversations[index];
                    return _ConversationTile(
                      conversation: conversation,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MessageDetail(
                              readerId: apiText(
                                conversation['reader_id'],
                                fallback: '',
                              ),
                              readerName: apiText(
                                conversation['reader_name'],
                                fallback: 'Độc giả',
                              ),
                            ),
                          ),
                        );
                        _load();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final Map<String, dynamic> conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = int.tryParse('${conversation['unread_count'] ?? 0}') ?? 0;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: _SmallAvatar(url: conversation['avatar_url']?.toString()),
      title: Row(
        children: [
          Expanded(
            child: Text(
              apiText(conversation['reader_name'], fallback: 'Độc giả'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kLibBookTitle,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            _conversationTime(conversation['last_message_time']),
            style: TextStyle(
              color: kLibBrownTitle.withValues(alpha: .65),
              fontSize: 11,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${conversation['last_sender_role'] == 'librarian' ? 'Bạn: ' : ''}'
                '${apiText(conversation['last_message'], fallback: '')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unread > 0)
              Container(
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: kLibRed,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unread > 99 ? '99+' : '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
      onTap: onTap,
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({required this.url});

  final String? url;

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
        width: 52,
        height: 52,
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
