import 'package:flutter/foundation.dart';

enum NotificationType {
  downloadComplete,
  favoriteAdded,
  favoriteRemoved,
  error,
  info,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.imageId,
    this.imageUrl,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final int? imageId;
  final String? imageUrl;

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? timestamp,
    int? imageId,
    String? imageUrl,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      imageId: imageId ?? this.imageId,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
