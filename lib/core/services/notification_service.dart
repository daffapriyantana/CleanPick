import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';

const cleanPickNotificationChannelId = 'cleanpick_notifications';

@pragma('vm:entry-point')
Future<void> cleanPickFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Notifikasi background diterima: ${message.messageId}');

  if (message.notification != null) return;
  final title = message.data['title']?.toString();
  final body = message.data['body']?.toString();
  if (title == null && body == null) return;

  final localNotifications = FlutterLocalNotificationsPlugin();
  await localNotifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );
  await localNotifications.show(
    message.hashCode,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        cleanPickNotificationChannelId,
        'Notifikasi CleanPick',
        channelDescription: 'Notifikasi status pesanan CleanPick',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
    payload: jsonEncode(message.data),
  );
}

class NotificationRoute {
  final String type;
  final String? orderId;

  const NotificationRoute({required this.type, this.orderId});

  factory NotificationRoute.fromData(Map<String, dynamic> data) {
    return NotificationRoute(
      type: data['type']?.toString() ?? '',
      orderId: data['orderId']?.toString(),
    );
  }

  Map<String, dynamic> toData() => {
    'type': type,
    if (orderId != null) 'orderId': orderId,
  };
}

class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FlutterLocalNotificationsPlugin _localNotifications;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  final StreamController<NotificationRoute> _routeController =
      StreamController<NotificationRoute>.broadcast();
  NotificationRoute? _pendingRoute;
  bool _initialized = false;

  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  Stream<NotificationRoute> get routes => _routeController.stream;

  NotificationRoute? takePendingRoute() {
    final route = _pendingRoute;
    _pendingRoute = null;
    return route;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      FirebaseMessaging.onBackgroundMessage(
        cleanPickFirebaseMessagingBackgroundHandler,
      );

      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload == null || payload.isEmpty) return;
          _emitRoute(
            NotificationRoute.fromData(
              Map<String, dynamic>.from(jsonDecode(payload) as Map),
            ),
          );
        },
      );
      final androidNotifications = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidNotifications?.createNotificationChannel(
        const AndroidNotificationChannel(
          cleanPickNotificationChannelId,
          'Notifikasi CleanPick',
          description: 'Notifikasi status pesanan CleanPick',
          importance: Importance.high,
        ),
      );

      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await _messaging.getToken();
      debugPrint('FCM TOKEN: $token');
      await _saveToken(token);

      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM TOKEN BARU: $newToken');
        unawaited(_saveToken(newToken));
      });

      _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
        debugPrint('Notifikasi diterima saat aplikasi terbuka');
        debugPrint('Judul: ${message.notification?.title}');
        debugPrint('Isi: ${message.notification?.body}');
        unawaited(_showForegroundNotification(message));
      });

      _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        _emitRouteFromMessage,
      );
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) _emitRouteFromMessage(initialMessage);
    } catch (error) {
      _initialized = false;
      debugPrint('FCM gagal diinisialisasi: $error');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final payload = jsonEncode(message.data);
    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          cleanPickNotificationChannelId,
          'Notifikasi CleanPick',
          channelDescription: 'Notifikasi status pesanan CleanPick',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  void _emitRouteFromMessage(RemoteMessage message) {
    _emitRoute(NotificationRoute.fromData(message.data));
  }

  void _emitRoute(NotificationRoute route) {
    if (route.type.isEmpty) return;
    if (_routeController.hasListener) {
      _routeController.add(route);
    } else {
      _pendingRoute = route;
    }
  }

  Future<void> _saveToken(String? token) async {
    if (token == null) return;

    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('User belum login, token belum disimpan');
      return;
    }

    await _firestore.collection('users').doc(user.uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
    debugPrint('FCM Token berhasil disimpan ke Firestore');
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _messageOpenedSubscription?.cancel();
    await _routeController.close();
  }
}
