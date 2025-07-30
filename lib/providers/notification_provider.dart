// lib/providers/notification_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/providers/auth_provider.dart';

class NotificationProvider with ChangeNotifier {
  final AuthProvider authProvider;
  StreamSubscription<dynamic>? _paymentSubscription;
  StreamSubscription<dynamic>? _chatSubscription;

  DateTime? _lastPaymentCheck;
  DateTime? _lastMessageCheck;
  DateTime? _lastPaymentUpdateCheck;
  DateTime? _lastAdminMessageCheck;

  bool _hasNewPayment = false;
  final Map<String, bool> _unreadMessages = {};

  bool get hasNewPayment => _hasNewPayment;
  bool hasUnreadMessagesFrom(String userId) => _unreadMessages[userId] ?? false;
  bool get hasAnyUnreadMessages => _unreadMessages.containsValue(true);

  bool _hasPaymentStatusUpdate = false;
  bool _hasNewAdminMessage = false;

  bool get hasPaymentStatusUpdate => _hasPaymentStatusUpdate;
  bool get hasNewAdminMessage => _hasNewAdminMessage;

  NotificationProvider(this.authProvider) {
    authProvider.addListener(_onAuthStateChanged);
    _setupListeners();
  }

  void _onAuthStateChanged() {
    _setupListeners();
  }

  void _setupListeners() {
    dispose();
    if (authProvider.isLoggedIn) {
      if (authProvider.userRole == 'admin') {
        _listenForNewPayments();
        _listenForNewMessagesForAdmin();
      } else {
        _listenForPaymentUpdatesForUser();
        _listenForNewMessagesForUser();
      }
    }
  }

  void _listenForNewPayments() {
    _paymentSubscription = supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .listen((data) {
          if (_lastPaymentCheck == null) return;
          final hasNew = data.any((item) {
            final createdAt = DateTime.parse(item['created_at']);
            return createdAt.isAfter(_lastPaymentCheck!);
          });
          if (hasNew) {
            _hasNewPayment = true;
            notifyListeners();
          }
        });
  }

  void _listenForNewMessagesForAdmin() {
    final adminId = authProvider.userModel?.uid;
    if (adminId == null) return;

    _chatSubscription = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .listen((data) {
          if (_lastMessageCheck == null) return;
          bool changed = false;
          for (var message in data) {
            final senderId = message['sender_id'];
            final createdAt = DateTime.parse(message['created_at']);
            if (senderId != adminId && createdAt.isAfter(_lastMessageCheck!)) {
              _unreadMessages[senderId] = true;
              changed = true;
            }
          }
          if (changed) {
            notifyListeners();
          }
        });
  }

  Future<void> _listenForPaymentUpdatesForUser() async {
    final user = authProvider.userModel;
    if (user == null) return;

    final studentResponse =
        await supabase
            .from('students')
            .select('id')
            .eq('parent_id', user.uid)
            .maybeSingle();
    if (studentResponse == null) return;
    final studentId = studentResponse['id'];

    _paymentSubscription = supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('student_id', studentId)
        .listen((data) {
          if (_lastPaymentUpdateCheck == null) return;
          final hasUpdate = data.any((item) {
            final updatedStr = item['paid_date'] ?? item['updated_at'];
            if (updatedStr == null) return false;
            final updated = DateTime.parse(updatedStr);
            return updated.isAfter(_lastPaymentUpdateCheck!);
          });
          if (hasUpdate) {
            _hasPaymentStatusUpdate = true;
            notifyListeners();
          }
        });
  }

  void _listenForNewMessagesForUser() {
    final user = authProvider.userModel;
    if (user == null) return;

    _chatSubscription = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.uid)
        .listen((data) {
          if (_lastAdminMessageCheck == null) return;
          final hasNewMessage = data.any((message) {
            final createdAt = DateTime.parse(message['created_at']);
            return message['sender_id'] != user.uid &&
                createdAt.isAfter(_lastAdminMessageCheck!);
          });
          if (hasNewMessage) {
            _hasNewAdminMessage = true;
            notifyListeners();
          }
        });
  }

  void clearPaymentNotification() {
    _hasNewPayment = false;
    _lastPaymentCheck = DateTime.now();
    notifyListeners();
  }

  void clearMessageNotificationFor(String userId) {
    if (_unreadMessages.containsKey(userId)) {
      _unreadMessages.remove(userId);
      _lastMessageCheck = DateTime.now();
      notifyListeners();
    }
  }

  void clearPaymentStatusUpdateNotification() {
    _hasPaymentStatusUpdate = false;
    _lastPaymentUpdateCheck = DateTime.now();
    notifyListeners();
  }

  void clearAdminMessageNotification() {
    _hasNewAdminMessage = false;
    _lastAdminMessageCheck = DateTime.now();
    notifyListeners();
  }

  @override
  // ignore: must_call_super
  void dispose() {
    _paymentSubscription?.cancel();
    _chatSubscription?.cancel();
  }

  void disposePermanently() {
    authProvider.removeListener(_onAuthStateChanged);
    dispose();
    super.dispose();
  }
}
