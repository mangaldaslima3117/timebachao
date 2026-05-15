import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static StreamSubscription<String>? _tokenSub;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // iOS permissions
    await _messaging.requestPermission();

    // Handle foreground notification
    FirebaseMessaging.onMessage.listen(_handleForegroundNotification);

    // Setup local notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);
  }

  static Future<void> saveAndSubscribeToken({
    required String userId,
    required String collection, // e.g., 'maids', 'admins'
  }) async {
    final token = await _messaging.getToken();
    debugPrint('saveAndSubscribeToken FCM Token: $token');
    debugPrint('saveAndSubscribeToken User ID: $userId');
    if (token != null) {
      await _saveTokenToFirestore(userId, collection, token);
    }

    // Prevent multiple subscriptions
    _tokenSub?.cancel();
    _tokenSub = _messaging.onTokenRefresh.listen((newToken) async {
      await _saveTokenToFirestore(userId, collection, newToken);
    });
  }

  static Future<void> _saveTokenToFirestore(
      String userId, String userType, String token) async {
    await FirebaseFirestore.instance.collection(userType).doc(userId).update({
      'fcmToken': token,
    });
  }

  static void dispose() {
    _tokenSub?.cancel();
  }

  static Future<void> _handleForegroundNotification(
      RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      const androidDetails = AndroidNotificationDetails(
        'maid_channel',
        'Maid Notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alert_sound'), // Optional
        icon: '@mipmap/launcher_icon', // Notification icon
      );

      const details = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        details,
      );
    }
  }
}
