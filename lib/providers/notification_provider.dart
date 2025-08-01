// lib/providers/notification_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sipatka/main.dart';
import 'package:sipatka/providers/auth_provider.dart';

class NotificationProvider with ChangeNotifier {
  final AuthProvider authProvider;
  StreamSubscription<dynamic>? _paymentSubscription;
  StreamSubscription<dynamic>? _chatSubscription;

  bool _hasNewPayment = false;
  final Map<String, bool> _unreadMessages = {};
  bool _hasPaymentStatusUpdate = false;
  bool _hasNewAdminMessage = false;

  // Tambahkan variabel untuk menyimpan timestamp terakhir
  DateTime? _lastPaymentCheck;
  DateTime? _lastMessageCheck;
  DateTime? _lastPaymentUpdateCheck;
  DateTime? _lastAdminMessageCheck;

  bool get hasNewPayment => _hasNewPayment;
  bool hasUnreadMessagesFrom(String userId) => _unreadMessages[userId] ?? false;
  bool get hasAnyUnreadMessages => _unreadMessages.containsValue(true);
  bool get hasPaymentStatusUpdate => _hasPaymentStatusUpdate;
  bool get hasNewAdminMessage => _hasNewAdminMessage;

  NotificationProvider(this.authProvider) {
    authProvider.addListener(_onAuthStateChanged);
    _onAuthStateChanged();
  }

  @override
  void dispose() {
    authProvider.removeListener(_onAuthStateChanged);
    _paymentSubscription?.cancel();
    _chatSubscription?.cancel();
    super.dispose();
  }

  void _onAuthStateChanged() {
    _setupListeners();
  }

  Future<void> _setupListeners() async {
    _paymentSubscription?.cancel();
    _chatSubscription?.cancel();

    if (!authProvider.isLoggedIn) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = authProvider.userModel?.uid ?? 'unknown';

    if (authProvider.userRole == 'admin') {
      // Setup untuk admin
      final paymentKey = 'lastPaymentCheck';
      var lastCheckMillis = prefs.getInt(paymentKey);
      if (lastCheckMillis == null) {
        lastCheckMillis = DateTime.now().toUtc().millisecondsSinceEpoch;
        await prefs.setInt(paymentKey, lastCheckMillis);
      }
      _lastPaymentCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckMillis);
      _listenForNewPayments(_lastPaymentCheck!);

      final messageKey = 'lastMessageCheck';
      var lastMsgCheckMillis = prefs.getInt(messageKey);
      if (lastMsgCheckMillis == null) {
        lastMsgCheckMillis = DateTime.now().toUtc().millisecondsSinceEpoch;
        await prefs.setInt(messageKey, lastMsgCheckMillis);
      }
      _lastMessageCheck = DateTime.fromMillisecondsSinceEpoch(
        lastMsgCheckMillis,
      );
      _listenForNewMessagesForAdmin(_lastMessageCheck!);
    } else {
      // Setup untuk user
      final paymentUpdateKey = 'lastPaymentUpdateCheck_$userId';
      var lastUpdateCheckMillis = prefs.getInt(paymentUpdateKey);
      if (lastUpdateCheckMillis == null) {
        lastUpdateCheckMillis = DateTime.now().toUtc().millisecondsSinceEpoch;
        await prefs.setInt(paymentUpdateKey, lastUpdateCheckMillis);
      }
      _lastPaymentUpdateCheck = DateTime.fromMillisecondsSinceEpoch(
        lastUpdateCheckMillis,
      );
      _listenForPaymentUpdatesForUser(_lastPaymentUpdateCheck!);

      final adminMessageKey = 'lastAdminMessageCheck_$userId';
      var lastAdminMsgCheckMillis = prefs.getInt(adminMessageKey);
      if (lastAdminMsgCheckMillis == null) {
        lastAdminMsgCheckMillis = DateTime.now().toUtc().millisecondsSinceEpoch;
        await prefs.setInt(adminMessageKey, lastAdminMsgCheckMillis);
      }
      _lastAdminMessageCheck = DateTime.fromMillisecondsSinceEpoch(
        lastAdminMsgCheckMillis,
      );
      _listenForNewMessagesForUser(_lastAdminMessageCheck!);
    }
  }

  // Method untuk refresh timestamp saat app kembali dari background
  Future<void> refreshTimestamps() async {
    if (!authProvider.isLoggedIn) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = authProvider.userModel?.uid ?? 'unknown';
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    if (authProvider.userRole == 'admin') {
      // Update timestamp untuk admin
      _lastPaymentCheck = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt('lastPaymentCheck') ?? now,
      );
      _lastMessageCheck = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt('lastMessageCheck') ?? now,
      );
    } else {
      // Update timestamp untuk user
      _lastPaymentUpdateCheck = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt('lastPaymentUpdateCheck_$userId') ?? now,
      );
      _lastAdminMessageCheck = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt('lastAdminMessageCheck_$userId') ?? now,
      );
    }
  }

  Future<void> checkForPaymentUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getInt('lastPaymentCheck') ?? 0;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    final response = await supabase
        .from('payments')
        .select('updated_at')
        .order('updated_at', ascending: false)
        .limit(1);

    if (response != null && response.isNotEmpty) {
      final updatedAt =
          DateTime.parse(
            response.first['updated_at'],
          ).toUtc().millisecondsSinceEpoch;
      if (updatedAt > lastCheck) {
        _hasPaymentStatusUpdate = true;
        notifyListeners();
      }
    }

    await prefs.setInt('lastPaymentCheck', now);
  }

  Future<void> syncInitialTimestamps() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final userId = authProvider.userModel?.uid ?? 'unknown';

    // Reset semua flag notifikasi saat sync
    _hasNewPayment = false;
    _hasPaymentStatusUpdate = false;
    _hasNewAdminMessage = false;
    _unreadMessages.clear();

    if (authProvider.userRole == 'admin') {
      if (!prefs.containsKey('lastPaymentCheck')) {
        await prefs.setInt('lastPaymentCheck', now);
      }
      if (!prefs.containsKey('lastMessageCheck')) {
        await prefs.setInt('lastMessageCheck', now);
      }
      // Update timestamp lokal
      _lastPaymentCheck = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt('lastPaymentCheck') ?? now,
      );
      _lastMessageCheck = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt('lastMessageCheck') ?? now,
      );
    } else {
      final paymentUpdateKey = 'lastPaymentUpdateCheck_$userId';
      final adminMessageKey = 'lastAdminMessageCheck_$userId';

      if (!prefs.containsKey(paymentUpdateKey)) {
        await prefs.setInt(paymentUpdateKey, now);
      }
      if (!prefs.containsKey(adminMessageKey)) {
        await prefs.setInt(adminMessageKey, now);
      }
      // Update timestamp lokal
      _lastPaymentUpdateCheck = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt(paymentUpdateKey) ?? now,
      );
      _lastAdminMessageCheck = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt(adminMessageKey) ?? now,
      );
    }

    notifyListeners();
  }

  void _listenForNewPayments(DateTime lastCheck) {
    _paymentSubscription = supabase
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .listen((data) {
          // Gunakan timestamp lokal yang sudah diupdate
          final currentLastCheck = _lastPaymentCheck ?? lastCheck;
          final hasNew = data.any((item) {
            final updateTimestampStr = item['updated_at'];
            if (updateTimestampStr == null) return false;
            final updateTimestamp = DateTime.parse(updateTimestampStr).toUtc();
            return updateTimestamp.isAfter(currentLastCheck);
          });
          if (hasNew) {
            _hasNewPayment = true;
            notifyListeners();
          }
        });
  }

  void _listenForNewMessagesForAdmin(DateTime lastCheck) {
    final adminId = authProvider.userModel?.uid;
    if (adminId == null) return;

    _chatSubscription = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .listen((data) {
          final currentLastCheck = _lastMessageCheck ?? lastCheck;
          bool changed = false;
          for (var message in data) {
            final senderId = message['sender_id'];
            final createdAt = DateTime.parse(message['created_at']).toUtc();
            if (senderId != adminId && createdAt.isAfter(currentLastCheck)) {
              _unreadMessages[senderId] = true;
              changed = true;
            }
          }
          if (changed) {
            notifyListeners();
          }
        });
  }

  Future<void> _listenForPaymentUpdatesForUser(DateTime lastCheck) async {
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
          final currentLastCheck = _lastPaymentUpdateCheck ?? lastCheck;
          final hasUpdate = data.any((item) {
            final updatedStr = item['updated_at'];
            if (updatedStr == null) return false;
            final updated = DateTime.parse(updatedStr).toUtc();
            return updated.isAfter(currentLastCheck) &&
                item['status'] != 'pending';
          });
          if (hasUpdate) {
            _hasPaymentStatusUpdate = true;
            notifyListeners();
          }
        });
  }

  void _listenForNewMessagesForUser(DateTime lastCheck) {
    final user = authProvider.userModel;
    if (user == null) return;

    _chatSubscription = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.uid)
        .listen((data) {
          final currentLastCheck = _lastAdminMessageCheck ?? lastCheck;
          final hasNewMessage = data.any((message) {
            final createdAt = DateTime.parse(message['created_at']).toUtc();
            return message['sender_id'] != user.uid &&
                createdAt.isAfter(currentLastCheck);
          });
          if (hasNewMessage) {
            _hasNewAdminMessage = true;
            notifyListeners();
          }
        });
  }

  Future<void> clearPaymentNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await prefs.setInt('lastPaymentCheck', now);
    _lastPaymentCheck = DateTime.fromMillisecondsSinceEpoch(now);
    _hasNewPayment = false;
    notifyListeners();
  }

  Future<void> clearMessageNotificationFor(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await prefs.setInt('lastMessageCheck', now);
    _lastMessageCheck = DateTime.fromMillisecondsSinceEpoch(now);
    if (_unreadMessages.containsKey(userId)) {
      _unreadMessages.remove(userId);
      notifyListeners();
    }
  }

  Future<void> clearPaymentStatusUpdateNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = authProvider.userModel?.uid ?? 'unknown';
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final key = 'lastPaymentUpdateCheck_$userId';
    await prefs.setInt(key, now);
    _lastPaymentUpdateCheck = DateTime.fromMillisecondsSinceEpoch(now);
    _hasPaymentStatusUpdate = false;
    notifyListeners();
  }

  Future<void> clearAdminMessageNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = authProvider.userModel?.uid ?? 'unknown';
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final key = 'lastAdminMessageCheck_$userId';
    await prefs.setInt(key, now);
    _lastAdminMessageCheck = DateTime.fromMillisecondsSinceEpoch(now);
    _hasNewAdminMessage = false;
    notifyListeners();
  }
}
