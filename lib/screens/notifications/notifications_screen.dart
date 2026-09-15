import 'package:flutter/material.dart';

import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = ApiClient.instance;
  bool _loading = true;
  String? _error;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.get('/notifications');
      if (!mounted) return;
      setState(() => _notifications = List<dynamic>.from(data));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Une erreur est survenue. Vérifiez votre connexion.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _marquerLue(String id, int index) async {
    setState(
        () => _notifications[index] = {..._notifications[index], 'lue': true});
    try {
      await _api.patch('/notifications/$id/lue', {});
    } catch (_) {
      // L'échec silencieux est acceptable : l'état visuel reste correct
      // localement même si la synchronisation serveur a échoué.
    }
  }

  String _formatDate(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return "il y a ${diff.inMinutes} min";
    if (diff.inHours < 24) return "il y a ${diff.inHours} h";
    if (diff.inDays < 7) return "il y a ${diff.inDays} j";
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.darkGreen,
        foregroundColor: AppColors.white,
        title: const Text('Notifications'),
      ),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Center(
            child: Text(_error!,
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          const SizedBox(height: 12),
          Center(
            child:
                TextButton(onPressed: _charger, child: const Text('Réessayer')),
          ),
        ],
      );
    }
    if (_notifications.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Icon(Icons.notifications_none, size: 56, color: AppColors.textMuted),
          SizedBox(height: 12),
          Center(
            child: Text('Aucune notification pour le moment.',
                style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final n = _notifications[index] as Map;
        final lue = n['lue'] == true;
        return Material(
          color: lue ? AppColors.white : AppColors.sage,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: lue ? null : () => _marquerLue(n['id'].toString(), index),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    lue ? Icons.notifications_none : Icons.notifications_active,
                    color: lue ? AppColors.textMuted : AppColors.darkGreen,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n['titre']?.toString() ?? '',
                            style: TextStyle(
                                fontWeight:
                                    lue ? FontWeight.w500 : FontWeight.w700,
                                color: AppColors.textDark)),
                        if ((n['corps'] as String?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(n['corps'].toString(),
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 13)),
                        ],
                        const SizedBox(height: 6),
                        Text(_formatDate(n['created_at']?.toString() ?? ''),
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
