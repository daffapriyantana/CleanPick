import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  bool _initialized = false;

  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

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
      });
    } catch (error) {
      _initialized = false;
      debugPrint('FCM gagal diinisialisasi: $error');
    }
  }

  Future<void> _saveToken(String? token) async {
    if (token == null) return;

    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('User belum login, token belum disimpan');
      return;
    }

    await _firestore.collection('users').doc(user.uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
    debugPrint('FCM Token berhasil disimpan ke Firestore');
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _messageSubscription?.cancel();
  }
}
