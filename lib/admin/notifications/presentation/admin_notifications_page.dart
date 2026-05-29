import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/domain/notification_topics.dart';
import '../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../shared/providers/firebase_providers.dart';
import '../data/notification_broadcast_datasource.dart';

final _broadcastDataSourceProvider = Provider<NotificationBroadcastDataSource>(
  (ref) => NotificationBroadcastDataSource(
    firestore: ref.watch(firestoreProvider),
  ),
);

/// Admin-only page that composes + sends a topic broadcast push.
///
/// The actual send happens server-side: this page writes to
/// `notification_broadcasts/{id}`, which triggers
/// `onNotificationBroadcast` in `functions/src/index.ts`.
class AdminNotificationsPage extends ConsumerStatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  ConsumerState<AdminNotificationsPage> createState() =>
      _AdminNotificationsPageState();
}

class _AdminNotificationsPageState
    extends ConsumerState<AdminNotificationsPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _route = TextEditingController();
  String _topic = NotificationTopics.allUsers;
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _route.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;

    setState(() => _sending = true);
    try {
      await ref.read(_broadcastDataSourceProvider).send(
            topic: _topic,
            title: _title.text.trim(),
            body: _body.text.trim(),
            route: _route.text.trim().isEmpty ? null : _route.text.trim(),
            createdBy: admin.id,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Queued — Cloud Function will fan it out.')),
        );
        _title.clear();
        _body.clear();
        _route.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Send failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = ref.watch(_broadcastDataSourceProvider).watchRecent();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compose
          Expanded(
            flex: 3,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Send notification',
                          style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _topic,
                        decoration:
                            const InputDecoration(labelText: 'Topic'),
                        items: [
                          for (final t in NotificationTopics.broadcastTargets)
                            DropdownMenuItem(value: t, child: Text(t)),
                        ],
                        onChanged: (v) => setState(() => _topic = v!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _title,
                        decoration:
                            const InputDecoration(labelText: 'Title'),
                        maxLength: 80,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _body,
                        decoration:
                            const InputDecoration(labelText: 'Body'),
                        minLines: 3,
                        maxLines: 6,
                        maxLength: 240,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _route,
                        decoration: const InputDecoration(
                          labelText: 'Deep-link route (optional)',
                          hintText: '/courses/<id>  ·  /  ·  /my-courses',
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.send_outlined),
                        label: const Text('Send'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // History
          Expanded(
            flex: 2,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('Recent broadcasts',
                          style: theme.textTheme.titleMedium),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: StreamBuilder<List<BroadcastRecord>>(
                        stream: history,
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final items = snap.data!;
                          if (items.isEmpty) {
                            return Center(
                              child: Text('No broadcasts yet.',
                                  style: theme.textTheme.bodyMedium),
                            );
                          }
                          return ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) => _HistoryTile(rec: items[i]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.rec});
  final BroadcastRecord rec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color statusColor;
    IconData statusIcon;
    switch (rec.status) {
      case 'sent':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'failed':
        statusColor = theme.colorScheme.error;
        statusIcon = Icons.error_outline;
        break;
      default:
        statusColor = theme.colorScheme.primary;
        statusIcon = Icons.hourglass_top_rounded;
    }
    return ListTile(
      leading: Icon(statusIcon, color: statusColor),
      title: Text(rec.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${rec.topic} · ${rec.body}',
          maxLines: 2, overflow: TextOverflow.ellipsis),
      isThreeLine: true,
      trailing: Text(
        rec.status,
        style: TextStyle(color: statusColor, fontSize: 12),
      ),
    );
  }
}
