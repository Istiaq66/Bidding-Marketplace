import 'package:app/features/notifications/domain/app_notification.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/notifications/data/notification_repository.dart';
import 'package:app/features/auctions/presentation/product_details_page.dart';
import 'package:app/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final userId = AuthRepository.currentUserId;

    return Scaffold(
      backgroundColor: colorToken.background,
      appBar: AppBar(
        backgroundColor: colorToken.surface,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: colorToken.textPrimary,
            fontWeight: FontWeight.bold,
            fontFamily: 'SourceSans3',
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorToken.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (userId != null)
            TextButton(
              onPressed: () => _markAllRead(context, userId),
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: colorToken.primary,
                  fontFamily: 'SourceSans3',
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: userId == null
          ? Center(
              child: Text(
                'Sign in to view notifications',
                style: TextStyle(
                  color: colorToken.textSecondary,
                  fontFamily: 'SourceSans3',
                ),
              ),
            )
          : StreamBuilder<List<AppNotification>>(
              stream: NotificationRepository.watchByUser(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child:
                        CircularProgressIndicator(color: colorToken.primary),
                  );
                }

                final notifications =
                    snapshot.data ?? const <AppNotification>[];

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_outlined,
                          size: 72,
                          color: colorToken.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorToken.textPrimary,
                            fontFamily: 'SourceSans3',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'ll be notified about bids and auctions',
                          style: TextStyle(
                            color: colorToken.textSecondary,
                            fontFamily: 'SourceSans3',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: colorToken.divider),
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return _buildTile(context, n, userId, colorToken);
                  },
                );
              },
            ),
    );
  }

  Future<void> _markAllRead(BuildContext context, String userId) async {
    final stream = NotificationRepository.watchByUser(userId);
    final notifications = await stream.first;
    for (final n in notifications.where((n) => !n.read)) {
      await NotificationRepository.markRead(userId, n.id);
    }
  }

  Widget _buildTile(
    BuildContext context,
    AppNotification n,
    String userId,
    colorToken,
  ) {
    final (icon, iconColor) = _iconFor(n.type, colorToken);
    final title = _titleFor(n);
    final subtitle = _subtitleFor(n);

    return Material(
      color: n.read
          ? colorToken.background
          : colorToken.primary.withValues(alpha: 0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.12),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: colorToken.textPrimary,
            fontWeight: n.read ? FontWeight.normal : FontWeight.bold,
            fontFamily: 'SourceSans3',
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: colorToken.textSecondary,
            fontSize: 12,
            fontFamily: 'SourceSans3',
          ),
        ),
        trailing: n.read
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorToken.primary,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () async {
          if (!n.read) await NotificationRepository.markRead(userId, n.id);
          if (n.productId.isNotEmpty && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetails(docId: n.productId),
              ),
            );
          }
        },
      ),
    );
  }

  (IconData, Color) _iconFor(NotificationType type, colorToken) {
    switch (type) {
      case NotificationType.bidPlaced:
        return (Icons.gavel, colorToken.primary as Color);
      case NotificationType.outbid:
        return (Icons.trending_down, colorToken.error as Color);
      case NotificationType.auctionWon:
        return (Icons.emoji_events, colorToken.success as Color);
      case NotificationType.auctionLost:
        return (Icons.sentiment_dissatisfied, colorToken.error as Color);
      case NotificationType.auctionEndedSeller:
        return (Icons.flag, colorToken.warning as Color);
      case NotificationType.auctionEndingSoon:
        return (Icons.timer_outlined, colorToken.warning as Color);
      case NotificationType.newAuction:
        return (Icons.new_releases_outlined, colorToken.primary as Color);
      case NotificationType.unknown:
        return (Icons.notifications, colorToken.textSecondary as Color);
    }
  }

  String _titleFor(AppNotification n) {
    switch (n.type) {
      case NotificationType.bidPlaced:
        return 'New bid on ${n.productName}';
      case NotificationType.outbid:
        return "You've been outbid on ${n.productName}";
      case NotificationType.auctionWon:
        return 'You won ${n.productName}!';
      case NotificationType.auctionLost:
        return 'Auction ended — ${n.productName}';
      case NotificationType.auctionEndedSeller:
        return 'Your auction ended — ${n.productName}';
      case NotificationType.auctionEndingSoon:
        return '${n.productName} is ending soon';
      case NotificationType.newAuction:
        return 'New auction: ${n.productName}';
      case NotificationType.unknown:
        return n.productName.isNotEmpty ? n.productName : 'Notification';
    }
  }

  String _subtitleFor(AppNotification n) {
    final amount = n.amount != null ? ' • \$${n.amount}' : '';
    final time = n.createdAt != null
        ? _formatTime(n.createdAt!)
        : '';
    return '$time$amount'.trim();
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}