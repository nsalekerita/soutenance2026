import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';

/// Fil de discussion simple entre l'entreprise et un étudiant
/// (fonctionnalité "contacter / discuter" liée à une candidature).
class EntrepriseChatScreen extends StatefulWidget {
  final String etudiantId;
  final String etudiantNom;

  const EntrepriseChatScreen({
    super.key,
    required this.etudiantId,
    required this.etudiantNom,
  });

  @override
  State<EntrepriseChatScreen> createState() => _EntrepriseChatScreenState();
}

class _EntrepriseChatScreenState extends State<EntrepriseChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<dynamic> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      // Adapter la route à ton API de messagerie.
      final data = await ApiClient.instance.get('/messages/conversation/${widget.etudiantId}');
      if (!mounted) return;
      setState(() => _messages = data is List<dynamic> ? data : <dynamic>[]);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyApiError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _envoyer() async {
    final texte = _messageCtrl.text.trim();
    if (texte.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ApiClient.instance.post('/messages', {
        'destinataire_id': widget.etudiantId,
        'contenu': texte,
      });
      _messageCtrl.clear();
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyApiError(e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.etudiantNom),
        backgroundColor: AppColors.darkGreen,
        foregroundColor: AppColors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                : _messages.isEmpty
                    ? const Center(child: Text('Aucun message. Lance la discussion !', style: TextStyle(color: AppColors.textMuted)))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final estMoi = m['expediteur_type'] == 'entreprise' || m['is_mine'] == true;
                          return Align(
                            alignment: estMoi ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                              decoration: BoxDecoration(
                                color: estMoi ? AppColors.darkGreen : AppColors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  if (!estMoi) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Text(
                                m['contenu'] ?? '',
                                style: TextStyle(color: estMoi ? AppColors.white : AppColors.textDark),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageCtrl,
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: (_) => _envoyer(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.darkGreen,
                    child: IconButton(
                      onPressed: _sending ? null : _envoyer,
                      icon: _sending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send, color: AppColors.white, size: 18),
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