import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum PrayerKind {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
  none,
}

class PrayerScheduleItem {
  final PrayerKind kind;
  final String nameAr;
  final String nameEn;
  final DateTime time;
  final bool isCurrent;
  final bool isNext;

  const PrayerScheduleItem({
    required this.kind,
    required this.nameAr,
    required this.nameEn,
    required this.time,
    required this.isCurrent,
    required this.isNext,
  });
}

class PrayerTimesService extends ChangeNotifier {
  static const String _kLatKey = 'mawaqit_lat';
  static const String _kLonKey = 'mawaqit_lon';
  static const String _kCityKey = 'mawaqit_city';
  static const String _kCountryKey = 'mawaqit_country';
  static const String _kMethodKey = 'mawaqit_method';
  static const String _kAdhanSoundKey = 'mawaqit_adhan_sound';
  static const String _kNotificationKey = 'mawaqit_notification';

  double _latitude = 21.4225; // Default: Makkah
  double _longitude = 39.8262;
  String _cityName = 'مكة المكرمة';
  String _countryName = 'المملكة العربية السعودية';
  String _calcMethodName = 'umm_al_qura';
  bool _adhanSoundEnabled = true;
  bool _notificationEnabled = true;
  bool _initialized = false;
  bool _loading = false;

  PrayerTimes? _prayerTimes;
  Timer? _tickerTimer;
  PrayerKind _lastTriggeredPrayer = PrayerKind.none;

  // Callback hook for external audio chime / Windows notification
  void Function(PrayerKind prayer, String prayerNameAr, String prayerNameEn)?
      onPrayerArrived;

  double get latitude => _latitude;
  double get longitude => _longitude;
  String get cityName => _cityName;
  String get countryName => _countryName;
  String get calcMethodName => _calcMethodName;
  bool get adhanSoundEnabled => _adhanSoundEnabled;
  bool get notificationEnabled => _notificationEnabled;
  bool get initialized => _initialized;
  bool get loading => _loading;

  PrayerTimes? get prayerTimes => _prayerTimes;

  static final List<Map<String, dynamic>> predefinedCities = [
    {'nameAr': 'مكة المكرمة', 'nameEn': 'Makkah', 'countryAr': 'السعودية', 'lat': 21.4225, 'lon': 39.8262, 'method': 'umm_al_qura'},
    {'nameAr': 'المدينة المنورة', 'nameEn': 'Madinah', 'countryAr': 'السعودية', 'lat': 24.4672, 'lon': 39.6111, 'method': 'umm_al_qura'},
    {'nameAr': 'الرياض', 'nameEn': 'Riyadh', 'countryAr': 'السعودية', 'lat': 24.7136, 'lon': 46.6753, 'method': 'umm_al_qura'},
    {'nameAr': 'جدة', 'nameEn': 'Jeddah', 'countryAr': 'السعودية', 'lat': 21.4858, 'lon': 39.1925, 'method': 'umm_al_qura'},
    {'nameAr': 'الجزائر العاصمة', 'nameEn': 'Algiers', 'countryAr': 'الجزائر', 'lat': 36.7538, 'lon': 3.0588, 'method': 'muslim_world_league'},
    {'nameAr': 'وهران', 'nameEn': 'Oran', 'countryAr': 'الجزائر', 'lat': 35.6987, 'lon': -0.6349, 'method': 'muslim_world_league'},
    {'nameAr': 'قسنطينة', 'nameEn': 'Constantine', 'countryAr': 'الجزائر', 'lat': 36.3650, 'lon': 6.6147, 'method': 'muslim_world_league'},
    {'nameAr': 'القاهرة', 'nameEn': 'Cairo', 'countryAr': 'مصر', 'lat': 30.0444, 'lon': 31.2357, 'method': 'egyptian'},
    {'nameAr': 'الإسكندرية', 'nameEn': 'Alexandria', 'countryAr': 'مصر', 'lat': 31.2001, 'lon': 29.9187, 'method': 'egyptian'},
    {'nameAr': 'الرباط', 'nameEn': 'Rabat', 'countryAr': 'المغرب', 'lat': 34.0209, 'lon': -6.8416, 'method': 'muslim_world_league'},
    {'nameAr': 'الدار البيضاء', 'nameEn': 'Casablanca', 'countryAr': 'المغرب', 'lat': 33.5731, 'lon': -7.5898, 'method': 'muslim_world_league'},
    {'nameAr': 'تونس', 'nameEn': 'Tunis', 'countryAr': 'تونس', 'lat': 36.8065, 'lon': 10.1815, 'method': 'muslim_world_league'},
    {'nameAr': 'طرابلس', 'nameEn': 'Tripoli', 'countryAr': 'ليبيا', 'lat': 32.8872, 'lon': 13.1913, 'method': 'muslim_world_league'},
    {'nameAr': 'القدس الشريف', 'nameEn': 'Jerusalem', 'countryAr': 'فلسطين', 'lat': 31.7683, 'lon': 35.2137, 'method': 'muslim_world_league'},
    {'nameAr': 'عَمّان', 'nameEn': 'Amman', 'countryAr': 'الأردن', 'lat': 31.9539, 'lon': 35.9106, 'method': 'muslim_world_league'},
    {'nameAr': 'دمشق', 'nameEn': 'Damascus', 'countryAr': 'سوريا', 'lat': 33.5138, 'lon': 36.2765, 'method': 'muslim_world_league'},
    {'nameAr': 'بيروت', 'nameEn': 'Beirut', 'countryAr': 'لبنان', 'lat': 33.8938, 'lon': 35.5018, 'method': 'muslim_world_league'},
    {'nameAr': 'بغداد', 'nameEn': 'Baghdad', 'countryAr': 'العراق', 'lat': 33.3152, 'lon': 44.3661, 'method': 'muslim_world_league'},
    {'nameAr': 'الكويت', 'nameEn': 'Kuwait City', 'countryAr': 'الكويت', 'lat': 29.3759, 'lon': 47.9774, 'method': 'kuwait'},
    {'nameAr': 'الدوحة', 'nameEn': 'Doha', 'countryAr': 'قطر', 'lat': 25.2854, 'lon': 51.5310, 'method': 'qatar'},
    {'nameAr': 'دبي', 'nameEn': 'Dubai', 'countryAr': 'الإمارات', 'lat': 25.2048, 'lon': 55.2708, 'method': 'dubai'},
    {'nameAr': 'أبوظبي', 'nameEn': 'Abu Dhabi', 'countryAr': 'الإمارات', 'lat': 24.4539, 'lon': 54.3773, 'method': 'dubai'},
    {'nameAr': 'مسقط', 'nameEn': 'Muscat', 'countryAr': 'عُمان', 'lat': 23.5880, 'lon': 58.3829, 'method': 'muslim_world_league'},
    {'nameAr': 'المنامة', 'nameEn': 'Manama', 'countryAr': 'البحرين', 'lat': 26.2285, 'lon': 50.5860, 'method': 'umm_al_qura'},
    {'nameAr': 'إسطنبول', 'nameEn': 'Istanbul', 'countryAr': 'تركيا', 'lat': 41.0082, 'lon': 28.9784, 'method': 'turkey'},
    {'nameAr': 'لندن', 'nameEn': 'London', 'countryAr': 'المملكة المتحدة', 'lat': 51.5074, 'lon': -0.1278, 'method': 'muslim_world_league'},
    {'nameAr': 'باريس', 'nameEn': 'Paris', 'countryAr': 'فرنسا', 'lat': 48.8566, 'lon': 2.3522, 'method': 'muslim_world_league'},
    {'nameAr': 'نيويورك', 'nameEn': 'New York', 'countryAr': 'الولايات المتحدة', 'lat': 40.7128, 'lon': -74.0060, 'method': 'north_america'},
    {'nameAr': 'تورونتو', 'nameEn': 'Toronto', 'countryAr': 'كندا', 'lat': 43.6532, 'lon': -79.3832, 'method': 'north_america'},
    {'nameAr': 'كوالالمبور', 'nameEn': 'Kuala Lumpur', 'countryAr': 'ماليزيا', 'lat': 3.1390, 'lon': 101.6869, 'method': 'singapore'},
    {'nameAr': 'جاكرتا', 'nameEn': 'Jakarta', 'countryAr': 'إندونيسيا', 'lat': -6.2088, 'lon': 106.8456, 'method': 'singapore'},
  ];

  static Future<PrayerTimesService> create() async {
    final service = PrayerTimesService();
    await service.load();
    return service;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLat = prefs.getDouble(_kLatKey);
    final savedLon = prefs.getDouble(_kLonKey);
    _cityName = prefs.getString(_kCityKey) ?? 'مكة المكرمة';
    _countryName = prefs.getString(_kCountryKey) ?? 'المملكة العربية السعودية';
    _calcMethodName = prefs.getString(_kMethodKey) ?? 'umm_al_qura';
    _adhanSoundEnabled = prefs.getBool(_kAdhanSoundKey) ?? true;
    _notificationEnabled = prefs.getBool(_kNotificationKey) ?? true;

    if (savedLat != null && savedLon != null) {
      _latitude = savedLat;
      _longitude = savedLon;
      _recalculate();
    } else {
      // First run: Try IP geolocation, otherwise keep Makkah default
      _recalculate();
      autoDetectLocation();
    }

    _initialized = true;
    _startTicker();
    notifyListeners();
  }

  CalculationParameters _resolveCalculationParameters(String methodName) {
    switch (methodName) {
      case 'muslim_world_league':
        return CalculationMethod.muslim_world_league.getParameters();
      case 'egyptian':
        return CalculationMethod.egyptian.getParameters();
      case 'karachi':
        return CalculationMethod.karachi.getParameters();
      case 'dubai':
        return CalculationMethod.dubai.getParameters();
      case 'qatar':
        return CalculationMethod.qatar.getParameters();
      case 'kuwait':
        return CalculationMethod.kuwait.getParameters();
      case 'singapore':
        return CalculationMethod.singapore.getParameters();
      case 'north_america':
        return CalculationMethod.north_america.getParameters();
      case 'tehran':
        return CalculationMethod.tehran.getParameters();
      case 'turkey':
        return CalculationMethod.turkey.getParameters();
      case 'umm_al_qura':
      default:
        return CalculationMethod.umm_al_qura.getParameters();
    }
  }

  void _recalculate() {
    try {
      final coordinates = Coordinates(_latitude, _longitude);
      final params = _resolveCalculationParameters(_calcMethodName);
      params.madhab = Madhab.shafi;
      final date = DateComponents.from(DateTime.now());
      _prayerTimes = PrayerTimes(coordinates, date, params);
    } catch (e) {
      debugPrint('Error calculating prayer times: $e');
    }
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      // If day rolled over, recalculate
      if (_prayerTimes != null &&
          (_prayerTimes!.fajr.day != now.day ||
              _prayerTimes!.fajr.month != now.month)) {
        _recalculate();
      }

      // Check for prayer arrival
      _checkPrayerArrival(now);

      notifyListeners();
    });
  }

  void _checkPrayerArrival(DateTime now) {
    if (_prayerTimes == null) return;
    final current = getCurrentPrayer();
    if (current != PrayerKind.none &&
        current != PrayerKind.sunrise &&
        current != _lastTriggeredPrayer) {
      final time = getTimeForPrayer(current);
      if (time != null) {
        final diff = now.difference(time).inSeconds.abs();
        if (diff <= 2) {
          _lastTriggeredPrayer = current;
          final (ar, en) = getPrayerNames(current);
          onPrayerArrived?.call(current, ar, en);
        }
      }
    }
  }

  Future<void> autoDetectLocation() async {
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      final res = await http
          .get(Uri.parse('http://ip-api.com/json'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          final lat = (data['lat'] as num).toDouble();
          final lon = (data['lon'] as num).toDouble();
          final city = data['city'] as String? ?? 'Your City';
          final country = data['country'] as String? ?? 'Your Country';

          await setLocation(
            latitude: lat,
            longitude: lon,
            cityName: city,
            countryName: country,
            save: true,
          );
        }
      }
    } catch (e) {
      debugPrint('IP location detection error (safe to ignore): $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setLocation({
    required double latitude,
    required double longitude,
    required String cityName,
    required String countryName,
    String? calcMethod,
    bool save = true,
  }) async {
    _latitude = latitude;
    _longitude = longitude;
    _cityName = cityName;
    _countryName = countryName;
    if (calcMethod != null) {
      _calcMethodName = calcMethod;
    }
    _recalculate();
    notifyListeners();

    if (save) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kLatKey, _latitude);
      await prefs.setDouble(_kLonKey, _longitude);
      await prefs.setString(_kCityKey, _cityName);
      await prefs.setString(_kCountryKey, _countryName);
      if (calcMethod != null) {
        await prefs.setString(_kMethodKey, _calcMethodName);
      }
    }
  }

  Future<void> setCalcMethod(String method) async {
    _calcMethodName = method;
    _recalculate();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMethodKey, _calcMethodName);
  }

  Future<void> toggleAdhanSound(bool enabled) async {
    _adhanSoundEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAdhanSoundKey, enabled);
  }

  Future<void> toggleNotification(bool enabled) async {
    _notificationEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationKey, enabled);
  }

  PrayerKind getCurrentPrayer() {
    if (_prayerTimes == null) return PrayerKind.none;
    final p = _prayerTimes!.currentPrayer();
    return _convertPrayer(p);
  }

  PrayerKind getNextPrayer() {
    if (_prayerTimes == null) return PrayerKind.none;
    final p = _prayerTimes!.nextPrayer();
    return _convertPrayer(p);
  }

  DateTime? getTimeForPrayer(PrayerKind kind) {
    if (_prayerTimes == null) return null;
    switch (kind) {
      case PrayerKind.fajr:
        return _prayerTimes!.fajr;
      case PrayerKind.sunrise:
        return _prayerTimes!.sunrise;
      case PrayerKind.dhuhr:
        return _prayerTimes!.dhuhr;
      case PrayerKind.asr:
        return _prayerTimes!.asr;
      case PrayerKind.maghrib:
        return _prayerTimes!.maghrib;
      case PrayerKind.isha:
        return _prayerTimes!.isha;
      case PrayerKind.none:
        return null;
    }
  }

  Duration getRemainingToNextPrayer() {
    if (_prayerTimes == null) return Duration.zero;
    final next = getNextPrayer();
    if (next == PrayerKind.none) {
      // Calculate remaining to tomorrow's Fajr
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      try {
        final coords = Coordinates(_latitude, _longitude);
        final params = _resolveCalculationParameters(_calcMethodName);
        final nextDayTimes =
            PrayerTimes(coords, DateComponents.from(tomorrow), params);
        final diff = nextDayTimes.fajr.difference(DateTime.now());
        return diff.isNegative ? Duration.zero : diff;
      } catch (_) {
        return Duration.zero;
      }
    }
    final nextTime = getTimeForPrayer(next);
    if (nextTime == null) return Duration.zero;
    final diff = nextTime.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  PrayerKind _convertPrayer(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return PrayerKind.fajr;
      case Prayer.sunrise:
        return PrayerKind.sunrise;
      case Prayer.dhuhr:
        return PrayerKind.dhuhr;
      case Prayer.asr:
        return PrayerKind.asr;
      case Prayer.maghrib:
        return PrayerKind.maghrib;
      case Prayer.isha:
        return PrayerKind.isha;
      case Prayer.none:
        return PrayerKind.none;
    }
  }

  (String, String) getPrayerNames(PrayerKind kind) {
    switch (kind) {
      case PrayerKind.fajr:
        return ('الفجر', 'Fajr');
      case PrayerKind.sunrise:
        return ('الشروق', 'Sunrise');
      case PrayerKind.dhuhr:
        return ('الظهر', 'Dhuhr');
      case PrayerKind.asr:
        return ('العصر', 'Asr');
      case PrayerKind.maghrib:
        return ('المغرب', 'Maghrib');
      case PrayerKind.isha:
        return ('العشاء', 'Isha');
      case PrayerKind.none:
        return ('—', '—');
    }
  }

  List<PrayerScheduleItem> getSchedule() {
    if (_prayerTimes == null) return const [];
    final current = getCurrentPrayer();
    final next = getNextPrayer();

    const kinds = [
      PrayerKind.fajr,
      PrayerKind.sunrise,
      PrayerKind.dhuhr,
      PrayerKind.asr,
      PrayerKind.maghrib,
      PrayerKind.isha,
    ];

    return kinds.map((k) {
      final (ar, en) = getPrayerNames(k);
      return PrayerScheduleItem(
        kind: k,
        nameAr: ar,
        nameEn: en,
        time: getTimeForPrayer(k) ?? DateTime.now(),
        isCurrent: k == current,
        isNext: k == next,
      );
    }).toList();
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }
}
