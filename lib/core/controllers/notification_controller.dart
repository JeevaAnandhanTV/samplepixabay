import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/notification.dart';

class NotificationController extends ChangeNotifier {
  NotificationController() {
    _init();
  }

  final List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  Timer? _debounce;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;

  void _init() {
    // Initialize with some sample notifications
    _addNotification(
      AppNotification(
        id: '1',
        type: NotificationType.info,
        title: 'Welcome to Infinite Gallery',
        message: 'Start exploring beautiful images from Pixabay!',
        timestamp: DateTime.now(),
      ),
    );
  }

  void _addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    _unreadCount++;
    notifyListeners();
  }

  void addDownloadComplete(int imageId, String imageUrl) {
    _addNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: NotificationType.downloadComplete,
        title: 'Download Complete',
        message: 'Image saved to your gallery',
        timestamp: DateTime.now(),
        imageId: imageId,
        imageUrl: imageUrl,
      ),
    );
  }

  void addFavoriteAdded(int imageId, String imageUrl) {
    _addNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: NotificationType.favoriteAdded,
        title: 'Added to Favorites',
        message: 'Image saved to your favorites',
        timestamp: DateTime.now(),
        imageId: imageId,
        imageUrl: imageUrl,
      ),
    );
  }

  void addFavoriteRemoved(int imageId) {
    _addNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: NotificationType.favoriteRemoved,
        title: 'Removed from Favorites',
        message: 'Image removed from your favorites',
        timestamp: DateTime.now(),
        imageId: imageId,
      ),
    );
  }

  void addError(String title, String message) {
    _addNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: NotificationType.error,
        title: title,
        message: message,
        timestamp: DateTime.now(),
      ),
    );
  }

  void addInfo(String title, String message) {
    _addNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: NotificationType.info,
        title: title,
        message: message,
        timestamp: DateTime.now(),
      ),
    );
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    _unreadCount = 0;
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    if (_unreadCount > 0) _unreadCount--;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
