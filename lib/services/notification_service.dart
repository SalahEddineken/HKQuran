import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/adhkar_data.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  static const String _kEnabledKey = 'adhkar_notify_enabled';
  static const String _kIntervalKey = 'adhkar_notify_interval';
  static const String _kSoundKey = 'adhkar_notify_sound';
  static const String _kMorningKey = 'adhkar_morning_enabled';
  static const String _kEveningKey = 'adhkar_evening_enabled';

  bool _initialized = false;
  bool _enabled = true;
  int _intervalMinutes = 15;
  bool _soundEnabled = false;
  bool _morningEnabled = true;
  bool _eveningEnabled = true;

  Timer? _periodicTimer;
  DateTime? _lastDhikrTime;
  DateTime? _lastPrayerTime;

  final List<int> _deck = [];
  final List<int> _recentIndices = [];
  int _lastReminderIndex = 0;

  bool get enabled => _enabled;
  int get intervalMinutes => _intervalMinutes;
  bool get soundEnabled => _soundEnabled;
  bool get morningEnabled => _morningEnabled;
  bool get eveningEnabled => _eveningEnabled;
  int get lastReminderIndex => _lastReminderIndex;

  Future<void> init() async {
    if (_initialized) return;

    if (!kIsWeb && Platform.isWindows) {
      try {
        await localNotifier.setup(
          appName: 'HKQuran',
          shortcutPolicy: ShortcutPolicy.requireCreate,
        );
      } catch (e) {
        debugPrint('localNotifier.setup error: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_kEnabledKey) ?? true;
    _intervalMinutes = prefs.getInt(_kIntervalKey) ?? 15;
    _soundEnabled = prefs.getBool(_kSoundKey) ?? false;
    _morningEnabled = prefs.getBool(_kMorningKey) ?? true;
    _eveningEnabled = prefs.getBool(_kEveningKey) ?? true;

    _initialized = true;
    _restartTimer();
    notifyListeners();
  }

  void _restartTimer() {
    _periodicTimer?.cancel();
    if (!_enabled || _intervalMinutes <= 0) return;

    _periodicTimer = Timer.periodic(Duration(minutes: _intervalMinutes), (_) {
      showNextDhikrNotification();
    });
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    _restartTimer();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, value);
  }

  Future<void> setIntervalMinutes(int mins) async {
    _intervalMinutes = mins;
    _restartTimer();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kIntervalKey, mins);
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSoundKey, value);
  }

  Future<void> setMorningEnabled(bool value) async {
    _morningEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kMorningKey, value);
  }

  Future<void> setEveningEnabled(bool value) async {
    _eveningEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEveningKey, value);
  }

  Future<void> showToast({
    required String title,
    required String body,
    String? subtitle,
    bool silent = true,
  }) async {
    if (kIsWeb || !Platform.isWindows) return;

    try {
      final notification = LocalNotification(
        title: title,
        subtitle: subtitle,
        body: body,
        silent: silent,
      );
      await notification.show();
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  Future<void> showNextDhikrNotification({bool force = false}) async {
    if (!force && !_enabled) return;

    final now = DateTime.now();

    // 1. Avoid firing immediately after a prayer notification (3 min cooldown)
    if (!force && _lastPrayerTime != null) {
      final diff = now.difference(_lastPrayerTime!);
      if (diff.inMinutes < 3) return;
    }

    // 2. Minimum interval cooldown between dhikrs (at least 45 seconds)
    if (!force && _lastDhikrTime != null) {
      final diff = now.difference(_lastDhikrTime!);
      if (diff.inSeconds < 45) return;
    }

    final items = AdhkarData.notificationReminders;
    if (items.isEmpty) return;

    final item = _pickNextItem(items);
    _lastDhikrTime = now;

    final prefs = await SharedPreferences.getInstance();
    final isAr = (prefs.getString('locale') ?? 'en') == 'ar';

    final title = isAr ? item.titleAr : 'HKQuran — ${item.titleEn}';
    final body = item.bodyAr;
    final subtitle = isAr ? item.virtueAr : (item.virtueEn ?? item.bodyEn);

    await showToast(
      title: title,
      body: body,
      subtitle: subtitle,
      silent: !_soundEnabled,
    );
  }

  DhikrNotificationItem _pickNextItem(List<DhikrNotificationItem> items) {
    final now = DateTime.now();
    final hour = now.hour;
    final isMorning = hour >= 5 && hour < 11;
    final isEvening = hour >= 16 && hour < 22;

    final eligibleIndices = <int>[];
    for (int i = 0; i < items.length; i++) {
      final cat = items[i].category;
      if (cat == AdhkarCategory.morning) {
        if (isMorning && _morningEnabled) eligibleIndices.add(i);
      } else if (cat == AdhkarCategory.evening) {
        if (isEvening && _eveningEnabled) eligibleIndices.add(i);
      } else {
        eligibleIndices.add(i);
      }
    }

    if (eligibleIndices.isEmpty) {
      for (int i = 0; i < items.length; i++) {
        eligibleIndices.add(i);
      }
    }

    _deck.removeWhere((idx) => !eligibleIndices.contains(idx));
    if (_deck.isEmpty) {
      final pool = List<int>.from(eligibleIndices)..shuffle(Random());
      _deck.addAll(pool);
    }

    int chosen = _deck.removeAt(0);
    if (_recentIndices.contains(chosen) && _deck.isNotEmpty) {
      final altIdx = _deck.indexWhere((idx) => !_recentIndices.contains(idx));
      if (altIdx != -1) {
        _deck.add(chosen);
        chosen = _deck.removeAt(altIdx);
      }
    }

    _recentIndices.add(chosen);
    if (_recentIndices.length > (items.length ~/ 2).clamp(5, 20)) {
      _recentIndices.removeAt(0);
    }

    _lastReminderIndex = chosen;
    return items[chosen];
  }

  Future<void> showPrayerNotification({
    required String prayerNameAr,
    required String prayerNameEn,
    required String cityName,
  }) async {
    _lastPrayerTime = DateTime.now();
    await showToast(
      title: 'حان الآن موعد صلاة $prayerNameAr',
      body: 'نداء الصلاة في $cityName — أَقِمِ الصَّلَاةَ لِذِكْرِي',
      silent: false,
    );
  }
}
