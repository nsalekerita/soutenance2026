import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';

/// Cas d'utilisation "Discuter" : chat avec l'assistant IA (Gemini côté backend).
class StudentChatScreen extends StatefulWidget {
  const StudentChatScreen({super.key});

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _Message {
  final String role;
  final String contenu;
  _Message(this.role, this.contenu);
}

class _StudentChatScreenState extends State<StudentChatScreen> {
  final _api = ApiClient.instance;
  final _input = TextEditingController();
  final _messages = <_Message>[];
  final _scrollController = ScrollController();
  String? _conversationId;
  bool _sending = false;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startConversation() async {
    setState(() => _initializing = true);
    try {
      final data = await _api.post('/ia/chat', {
        'message': "Bonjour, je souhaite des conseils d'orientation basés sur mon profil."
      });
      _conversationId = data['conversationId'];
      setState(() => _messages.add(_Message('assistant', data['reponse'])));
      _scrollToBottom();
    } catch (e) {
      debugPrint("Erreur init chat: $e");
    } finally {
      setState(() => _initializing = false);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Message('user', text));
      _input.clear();
      _sending = true;
    });
    _scrollToBottom();
    try {
      final data = await _api.post('/ia/chat', {'conversationId': _conversationId, 'message': text});
      _conversationId = data['conversationId'];
      setState(() => _messages.add(_Message('assistant', data['reponse'])));
      _scrollToBottom();
    } catch (e) {
      setState(() => _messages.add(_Message('assistant', 'Désolé, ${friendlyApiError(e)}')));
      _scrollToBottom();
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _initializing
              ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
              : _messages.isEmpty
                  ? const Center(child: Text('Pose ta question sur ton orientation...', style: TextStyle(color: AppColors.textMuted)))
                  : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final m = _messages[i];
              final isUser = m.role == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(14),
                  constraints: const BoxConstraints(maxWidth: 600),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.darkGreen : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (!isUser) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                    ],
                  ),
                  child: SelectableText(
                    m.contenu,
                    style: TextStyle(
                      color: isUser ? AppColors.white : AppColors.textDark,
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_sending) const LinearProgressIndicator(minHeight: 2, color: AppColors.gold),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  decoration: InputDecoration(
                    hintText: 'Écris ton message...',
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppColors.darkGreen,
                child: IconButton(icon: const Icon(Icons.send, color: AppColors.white, size: 18), onPressed: _send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
