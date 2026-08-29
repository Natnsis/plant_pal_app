import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

IconData _notifTypeIcon(NotificationType type) {
  switch (type) {
    case NotificationType.reminder:
      return LucideIcons.bell;
    case NotificationType.careTip:
      return LucideIcons.leaf;
    case NotificationType.system:
      return LucideIcons.info;
    case NotificationType.achievement:
      return LucideIcons.trophy;
  }
}

class NotificationInbox extends StatefulWidget {
  const NotificationInbox({super.key});

  @override
  State<NotificationInbox> createState() => _NotificationInboxState();
}

class _NotificationInboxState extends State<NotificationInbox> {
  final ScrollController _scrollController = ScrollController();

  List<NotificationItem> _notifications = [];
  bool _showUnreadOnly = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _offset = 0;
  static const _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _offset = 0;
      _hasMore = true;
    });

    try {
      final items = await AuthService.getNotificationInbox(
        offset: 0,
        limit: _limit,
        unreadOnly: _showUnreadOnly ? true : null,
      );

      if (!mounted) return;

      setState(() {
        _notifications =
            items.map((j) => NotificationItem.fromJson(j)).toList();
        _isLoading = false;
        _hasMore = items.length >= _limit;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load notifications';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      _offset += _limit;
      final items = await AuthService.getNotificationInbox(
        offset: _offset,
        limit: _limit,
        unreadOnly: _showUnreadOnly ? true : null,
      );

      if (!mounted) return;

      setState(() {
        _notifications
            .addAll(items.map((j) => NotificationItem.fromJson(j)));
        _hasMore = items.length >= _limit;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _toggleFilter(bool unreadOnly) async {
    if (_showUnreadOnly == unreadOnly) return;
    setState(() => _showUnreadOnly = unreadOnly);
    await _loadNotifications();
  }

  Future<void> _markAllRead() async {
    try {
      await AuthService.markAllNotificationsRead();
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map((n) => NotificationItem(
                  id: n.id,
                  type: n.type,
                  title: n.title,
                  body: n.body,
                  isRead: true,
                  actionUrl: n.actionUrl,
                  relatedPlantId: n.relatedPlantId,
                  relatedReminderId: n.relatedReminderId,
                  createdAt: n.createdAt,
                ))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark all as read')),
        );
      }
    }
  }

  Future<void> _deleteNotification(NotificationItem item) async {
    // Optimistic removal
    final index = _notifications.indexOf(item);
    setState(() => _notifications.removeAt(index));

    try {
      await AuthService.deleteNotification(item.id);
    } catch (e) {
      // Revert on failure
      if (mounted) {
        setState(() => _notifications.insert(index, item));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't delete notification")),
        );
      }
    }
  }

  Future<void> _handleTap(NotificationItem item) async {
    // Mark as read if unread
    if (!item.isRead) {
      try {
        await AuthService.markNotificationRead(item.id);
        if (mounted) {
          setState(() {
            final idx = _notifications.indexWhere((n) => n.id == item.id);
            if (idx != -1) {
              _notifications[idx] = NotificationItem(
                id: item.id,
                type: item.type,
                title: item.title,
                body: item.body,
                isRead: true,
                actionUrl: item.actionUrl,
                relatedPlantId: item.relatedPlantId,
                relatedReminderId: item.relatedReminderId,
                createdAt: item.createdAt,
              );
            }
          });
        }
      } catch (_) {
        // Optimistic — continue with navigation
      }
    }

    // Navigate based on related data
    if (!mounted) return;
    if (item.relatedPlantId != null) {
      Navigator.of(context).pushNamed('/plant/${item.relatedPlantId}');
    } else if (item.relatedReminderId != null) {
      Navigator.of(context).pushNamed('/reminders');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => !n.isRead);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.sageTop, AppColors.sageBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.cream.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.chevronLeft,
                          color: AppColors.cream,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cream,
                        ),
                      ),
                    ),
                    if (hasUnread)
                      TextButton(
                        onPressed: _markAllRead,
                        child: Text(
                          'Mark all read',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.cream.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Filter pills
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    _FilterPill(
                      label: 'All',
                      isSelected: !_showUnreadOnly,
                      onTap: () => _toggleFilter(false),
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: 'Unread',
                      isSelected: _showUnreadOnly,
                      onTap: () => _toggleFilter(true),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoadingState();
    if (_error != null) return _buildErrorState();
    if (_notifications.isEmpty) return _buildEmptyState();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _notifications.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.cream,
                ),
              ),
            ),
          );
        }
        final item = _notifications[index];
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(LucideIcons.trash2, color: Colors.white),
          ),
          onDismissed: (_) => _deleteNotification(item),
          child: _NotificationRow(
            item: item,
            onTap: () => _handleTap(item),
            onDelete: () => _deleteNotification(item),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (context, idx) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cream.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cream.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.cream.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 200,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.cream.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _error!,
            style: const TextStyle(color: AppColors.cream, fontSize: 15),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: _loadNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBg,
                foregroundColor: AppColors.buttonLabel,
                shape: const StadiumBorder(),
              ),
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.bell, size: 56, color: AppColors.cream),
          const SizedBox(height: 16),
          Text(
            _showUnreadOnly ? "You're all caught up 🎉" : 'No notifications yet',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.cream,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Notification row
// =============================================================================

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final NotificationItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead
              ? AppColors.cream.withValues(alpha: 0.12)
              : AppColors.cream.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.isRead
                    ? AppColors.textPrimary.withValues(alpha: 0.08)
                    : AppColors.accentGreen,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  _notifTypeIcon(item.type),
                  size: 18,
                  color: item.isRead ? AppColors.textPrimary : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!item.isRead) ...[
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.accentGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                item.isRead ? FontWeight.w500 : FontWeight.w700,
                            color: item.isRead
                                ? AppColors.textPrimary.withValues(alpha: 0.6)
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: item.isRead
                          ? AppColors.textPrimary.withValues(alpha: 0.4)
                          : AppColors.textPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Timestamp + delete
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.relativeTime,
                  style: TextStyle(
                    fontSize: 11,
                    color: item.isRead
                        ? AppColors.textPrimary.withValues(alpha: 0.3)
                        : AppColors.textPrimary.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    LucideIcons.x,
                    size: 16,
                    color: AppColors.textPrimary.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Filter pill
// =============================================================================

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentDark : Colors.transparent,
          borderRadius: const BorderRadius.all(AppRadius.pill),
          border: isSelected
              ? null
              : Border.all(
                  color: AppColors.cream.withValues(alpha: 0.3),
                ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? AppColors.cream
                : AppColors.cream.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
