import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../api/api_exception.dart';
import '../api/plantpal_api.dart';
import '../models/models.dart';
import '../theme/pp_theme.dart';
import '../widgets/async_view.dart';
import '../widgets/pp_common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = PlantPalApi.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PP.bone,
      body: SafeArea(
        child: AsyncView<List<InboxItem>>(
          load: () => _api.inbox(),
          emptyWhen: (l) => l.isEmpty,
          emptyLabel: 'No notifications yet',
          emptyIcon: LucideIcons.bell,
          builder: (context, items, reload) {
            return RefreshIndicator(
              color: PP.forest,
              onRefresh: reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
                children: [
                  Row(
                    children: [
                      SquircleIconButton(
                        icon: LucideIcons.chevronLeft,
                        background: PP.card.withValues(alpha: 0.8),
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text('Notifications',
                              style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          try {
                            await _api.markAllRead();
                            await reload();
                          } on ApiException catch (e) {
                            if (context.mounted) {
                              showPPSnack(context, e.message, error: true);
                            }
                          }
                        },
                        child: Text('Read all',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: PP.forest)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  for (final it in items) ...[
                    Dismissible(
                      key: ValueKey(it.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: PP.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: const Icon(LucideIcons.trash2,
                            color: PP.danger, size: 20),
                      ),
                      onDismissed: (_) => _delete(it, reload),
                      child: GestureDetector(
                        onTap: it.isRead ? null : () => _markRead(it, reload),
                        child: _NotifTile(item: it),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _markRead(InboxItem it, Future<void> Function() reload) async {
    try {
      await _api.markRead(it.id);
      await reload();
    } on ApiException catch (e) {
      if (mounted) showPPSnack(context, e.message, error: true);
    }
  }

  Future<void> _delete(InboxItem it, Future<void> Function() reload) async {
    try {
      await _api.deleteNotification(it.id);
    } on ApiException catch (e) {
      if (mounted) showPPSnack(context, e.message, error: true);
    }
    await reload();
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.item});
  final InboxItem item;

  @override
  Widget build(BuildContext context) {
    final (icon, iconBg, iconFg) = switch (item.type) {
      'reminder' => (LucideIcons.droplet, PP.pale1, PP.forest),
      'achievement' => (LucideIcons.trendingUp, PP.amberBg, PP.amberFg),
      'care_tip' => (LucideIcons.info, const Color(0xFFE1E7D5), PP.inkA(0.6)),
      _ => (LucideIcons.bell, const Color(0xFFE1E7D5), PP.inkA(0.6)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: item.isRead ? PP.card.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: item.isRead
            ? null
            : const Border(left: BorderSide(color: PP.lime, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, size: 19, color: iconFg),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title.isEmpty ? 'Notification' : item.title,
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: PP.track(14.5, -0.01))),
                if (item.body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.body,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: PP.inkA(0.5))),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(_rel(item.createdAt),
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: PP.inkA(0.4))),
        ],
      ),
    );
  }

  static String _rel(DateTime? t) {
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays == 1) return 'Yesterday';
    return '${d.inDays}d';
  }
}
