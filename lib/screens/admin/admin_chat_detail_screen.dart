// lib/screens/admin/admin_chat_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/models/user_model.dart';
import 'package:sipatka/providers/auth_provider.dart';
import 'package:sipatka/utils/app_theme.dart';
import 'package:sipatka/utils/error_dialog.dart';

class AdminChatDetailScreen extends StatefulWidget {
  final UserModel parent;
  const AdminChatDetailScreen({super.key, required this.parent});

  @override
  State<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<AdminChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController(); // Controller untuk auto-scroll
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  late final String _adminId;

  @override
  void initState() {
    super.initState();

    _adminId = context.read<AuthProvider>().userModel!.uid;

    _messagesStream = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('user_id', widget.parent.uid)
        .order('created_at', ascending: true); // Urutan ascending untuk chat
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // Fungsi untuk auto-scroll ke pesan terbaru
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      await supabase.from('messages').insert({
        'user_id': widget.parent.uid,
        'sender_id': _adminId,
        'content': content,
      });
    } catch (e) {
      if (mounted) {
        showErrorDialog(
          context: context,
          title: 'Pengiriman Gagal',
          message:
              'Pesan Anda tidak dapat terkirim. Periksa koneksi internet Anda.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat dengan ${widget.parent.parentName}")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                // Auto-scroll saat ada data baru
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Belum ada percakapan dengan ${widget.parent.parentName}. Mulailah percakapan!",
                      ),
                    ),
                  );
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index];
                    final bool isFromAdmin =
                        messageData['sender_id'] == _adminId;
                    return _buildMessageBubble(
                      text: messageData['content'] ?? '',
                      isFromAdmin: isFromAdmin,
                      timestamp: DateTime.parse(messageData['created_at']),
                    );
                  },
                );
              },
            ),
          ),
          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ketik balasan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: Colors.grey.shade200,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  elevation: 2,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required bool isFromAdmin,
    required DateTime timestamp,
  }) {
    // Kode untuk widget gelembung chat ini sama seperti respons sebelumnya, tidak perlu diubah.
    final alignment =
        isFromAdmin ? MainAxisAlignment.end : MainAxisAlignment.start;
    final color =
        isFromAdmin ? Theme.of(context).primaryColor : Colors.grey[300];
    final textColor = isFromAdmin ? Colors.white : Colors.black87;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft:
          isFromAdmin ? const Radius.circular(16) : const Radius.circular(0),
      bottomRight:
          isFromAdmin ? const Radius.circular(0) : const Radius.circular(16),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: color,
                borderRadius: borderRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: TextStyle(color: textColor, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(timestamp.toLocal()),
                    style: TextStyle(
                      color: isFromAdmin ? Colors.white70 : Colors.black54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
