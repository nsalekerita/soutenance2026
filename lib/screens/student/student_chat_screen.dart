import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';

/// Cas d'utilisation "Discuter" : chat avec l'assistant IA (Claude côté backend).
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
  String? _conversationId;
  bool _sending = false;

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Message('user', text));
      _input.clear();
      _sending = true;
    });
    try {
      final data = await _api.post('/ia/chat', {'conversationId': _conversationId, 'message': text});
      _conversationId = data['conversationId'];
      setState(() => _messages.add(_Message('assistant', data['reponse'])));
    } catch (e) {
      setState(() => _messages.add(_Message('assistant', 'Désolé, une erreur est survenue: $e')));
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? const Center(child: Text('Pose ta question sur ton orientation, une filière, un stage...', style: TextStyle(color: AppColors.textMuted)))
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final m = _messages[i];
              final isUser = m.role == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: const BoxConstraints(maxWidth: 460),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.darkGreen : AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(m.contenu, style: TextStyle(color: isUser ? AppColors.white : AppColors.textDark)),
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
