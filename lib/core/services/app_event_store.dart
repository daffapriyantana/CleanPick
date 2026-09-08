import 'package:flutter/foundation.dart';

class ChatMessage {
  final String orderId;
  final String sender;
  final String text;
  final DateTime sentAt;

  const ChatMessage(
      {required this.orderId,
      required this.sender,
      required this.text,
      required this.sentAt});
}

class AppChatStore extends ChangeNotifier {
  AppChatStore._();
  static final AppChatStore instance = AppChatStore._();

  final List<ChatMessage> _messages = [];

  List<ChatMessage> forOrder(String orderId) => List.unmodifiable(
      _messages.where((message) => message.orderId == orderId));

  void send(
      {required String orderId, required String sender, required String text}) {
    if (text.trim().isEmpty) return;
    _messages.add(ChatMessage(
        orderId: orderId,
        sender: sender,
        text: text.trim(),
        sentAt: DateTime.now()));
    notifyListeners();
  }
}

class AppNotification {
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification(
      {required this.title,
      required this.message,
      required this.createdAt,
      this.isRead = false});
}

class AppNotificationStore extends ChangeNotifier {
  AppNotificationStore._();
  static final AppNotificationStore instance = AppNotificationStore._();

  final List<AppNotification> _items = [
    AppNotification(
        title: 'Selamat datang di CleanPick',
        message: 'Atur penjemputan sampah dengan mudah.',
        createdAt: DateTime.now()),
  ];

  List<AppNotification> get items => List.unmodifiable(_items.reversed);

  void add({required String title, required String message}) {
    _items.add(AppNotification(
        title: title, message: message, createdAt: DateTime.now()));
    notifyListeners();
  }

  void addAdminNotice(String message) =>
      add(title: 'Info CleanPick', message: message);
}
