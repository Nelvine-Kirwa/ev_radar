import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_item.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final auth = context.read<AuthProvider>();
    final items = provider.items;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
        actions: [
          if (provider.hasUnread)
            TextButton(
              onPressed: () {
                final uid = auth.user?.uid;
                if (uid != null) provider.markAllAsRead(uid);
              },
              child: const Text(
                'Mark all read',
                style: TextStyle(
                    color: Color(0xFF00C853),
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: provider.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00C853)))
            : items.isEmpty
                ? _buildEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, i) => _notificationCard(
                      context,
                      items[i],
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none,
              color: Color(0xFF4A5568), size: 56),
          SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
                color: Color(0xFF8892B0),
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            "You'll see booking requests and updates here",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF4A5568), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _notificationCard(BuildContext context, NotificationItem n) {
    final isNewBooking = n.type == 'NEW_BOOKING';
    final isCancelled = n.type == 'BOOKING_CANCELLED' ||
        n.type == 'BOOKING_CANCELLED_BY_USER';
    final isConfirmed = n.type == 'BOOKING_CONFIRMED';
    final isApproved = n.type == 'APPLICATION_APPROVED';
    final isRejected = n.type == 'APPLICATION_REJECTED';

    final IconData icon;
    final Color iconColor;

    if (isNewBooking) {
      icon = Icons.bolt;
      iconColor = const Color(0xFF00C853);
    } else if (isConfirmed) {
      icon = Icons.check_circle_outline;
      iconColor = const Color(0xFF00C853);
    } else if (isCancelled) {
      icon = Icons.cancel_outlined;
      iconColor = const Color(0xFFD32F2F);
    } else if (isApproved) {
      icon = Icons.verified_outlined;
      iconColor = const Color(0xFF00C853);
    } else if (isRejected) {
      icon = Icons.highlight_off;
      iconColor = const Color(0xFFD32F2F);
    } else {
      icon = Icons.notifications_active;
      iconColor = const Color(0xFFFFA000);
    }

    return GestureDetector(
      onTap: () {
        if (!n.read) {
          context.read<NotificationProvider>().markAsRead(n.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: n.read
                ? const Color(0xFF1F2937)
                : const Color(0x6600C853),
            width: n.read ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: iconColor.withOpacity(0.4)),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (!n.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00C853),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.body,
                    style: const TextStyle(
                        color: Color(0xFF8892B0), fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _timeAgo(n.createdAt),
                    style: const TextStyle(
                        color: Color(0xFF4A5568), fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime? d) {
    if (d == null) return 'just now';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
