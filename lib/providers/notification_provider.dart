import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';
import '../services/push_notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  StreamSubscription<QuerySnapshot>? _subscription;

  List<NotificationItem> _items = [];
  final Set<String> _seenIds = {};
  bool _firstSnapshotDone = false;
  bool _isLoading = false;
  String _lastUserId = '';

  List<NotificationItem> get items => _items;
  bool get isLoading => _isLoading;
  int get unreadCount => _items.where((n) => !n.read).length;
  bool get hasUnread => unreadCount > 0;
  String get lastUserId => _lastUserId;

  void listenForUser(String userId) {
    if (userId.isEmpty) {
      debugPrint('[NotifProvider] listenForUser aborted: empty userId');
      return;
    }

    _subscription?.cancel();
    _isLoading = true;
    _lastUserId = userId;
    notifyListeners();

    debugPrint('[NotifProvider] Starting listener for: ' + userId);

    _subscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
      (snap) {
        _items = snap.docs
            .map((d) => NotificationItem.fromFirestore(d))
            .toList();
        debugPrint(
            '[NotifProvider] Snapshot received: ' + _items.length.toString() + ' items');

        // On first snapshot, remember everything we already had.
        // After that, push a system notification for each new item.
        if (!_firstSnapshotDone) {
          for (final n in _items) {
            _seenIds.add(n.id);
          }
          _firstSnapshotDone = true;
        } else {
          for (final n in _items) {
            if (!_seenIds.contains(n.id)) {
              _seenIds.add(n.id);
              if (!n.read) {
                PushNotificationService().show(
                  title: n.title,
                  body: n.body,
                  payload: n.id,
                );
              }
            }
          }
        }

        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[NotifProvider] Listener error: ' + e.toString());
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Manual one-shot refresh used by pull-to-refresh on NotificationsScreen.
  /// Fetches once, replaces _items, and notifies listeners.
  Future<void> refreshForUser(String userId) async {
    if (userId.isEmpty) return;
    try {
      final fetched = await _service.getForUser(userId);
      _items = fetched;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[NotifProvider] refreshForUser ERROR: $e');
    }
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _items = [];
    _lastUserId = '';
    _seenIds.clear();
    _firstSnapshotDone = false;
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _service.markAllAsRead(userId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}