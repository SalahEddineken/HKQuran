import 'package:flutter_test/flutter_test.dart';
import 'package:hkquran/audio/reciter_download_service.dart';
import 'package:hkquran/data/adhkar_data.dart';
import 'package:hkquran/data/models.dart';
import 'package:hkquran/data/prayer_times_service.dart';
import 'package:hkquran/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PrayerTimesService', () {
    test('Calculates prayer times and schedule items correctly for Makkah', () async {
      final service = await PrayerTimesService.create();
      expect(service.cityName, isNotEmpty);
      expect(service.prayerTimes, isNotNull);

      final schedule = service.getSchedule();
      expect(schedule.length, 6);

      // Verify all 6 prayer items exist in order
      expect(schedule[0].kind, PrayerKind.fajr);
      expect(schedule[1].kind, PrayerKind.sunrise);
      expect(schedule[2].kind, PrayerKind.dhuhr);
      expect(schedule[3].kind, PrayerKind.asr);
      expect(schedule[4].kind, PrayerKind.maghrib);
      expect(schedule[5].kind, PrayerKind.isha);

      for (final item in schedule) {
        expect(item.nameAr, isNotEmpty);
        expect(item.nameEn, isNotEmpty);
        expect(item.time, isNotNull);
      }
    });

    test('Can switch city location and calculation method', () async {
      final service = await PrayerTimesService.create();
      await service.setLocation(
        latitude: 36.7538,
        longitude: 3.0588,
        cityName: 'الجزائر العاصمة',
        countryName: 'الجزائر',
        calcMethod: 'muslim_world_league',
        save: false,
      );

      expect(service.cityName, 'الجزائر العاصمة');
      expect(service.countryName, 'الجزائر');
      expect(service.calcMethodName, 'muslim_world_league');
      expect(service.prayerTimes, isNotNull);

      final next = service.getNextPrayer();
      expect(next, isNotNull);
    });
  });

  group('AdhkarData', () {
    test('Contains rich adhkar across all categories', () {
      for (final cat in AdhkarCategory.values) {
        final list = AdhkarData.getByCategory(cat);
        expect(list, isNotEmpty, reason: 'Category $cat should have items');
        for (final item in list) {
          expect(item.text, isNotEmpty);
          expect(item.targetCount, greaterThan(0));
        }
      }
    });

    test('Short reminders for Windows desktop notifications are non-empty', () {
      expect(AdhkarData.shortReminders.length, greaterThanOrEqualTo(40));
      for (final reminder in AdhkarData.shortReminders) {
        expect(reminder.trim(), isNotEmpty);
      }
    });

    test('notificationReminders contains at least 40 rich items with titles and valid texts', () {
      expect(AdhkarData.notificationReminders.length, greaterThanOrEqualTo(40));
      for (final item in AdhkarData.notificationReminders) {
        expect(item.titleAr.trim(), isNotEmpty);
        expect(item.titleEn.trim(), isNotEmpty);
        expect(item.bodyAr.trim(), isNotEmpty);
      }
    });

    test('NotificationService manages interval, silent mode, and state correctly', () async {
      final service = NotificationService.instance;
      await service.init();
      expect(service.enabled, isTrue);
      expect(service.intervalMinutes, 15);
      expect(service.soundEnabled, isFalse); // Silent by default to not be annoying

      await service.setIntervalMinutes(10);
      expect(service.intervalMinutes, 10);

      await service.setSoundEnabled(true);
      expect(service.soundEnabled, isTrue);

      await service.setSoundEnabled(false);
      expect(service.soundEnabled, isFalse);
    });
  });

  group('ReciterDownloadService', () {
    test('Format bytes accurately', () {
      final service = ReciterDownloadService.instance;
      expect(service.formatBytes(0), '0 B');
      expect(service.formatBytes(1024 * 1024 * 50), contains('MB'));
      expect(service.formatBytes(1024 * 1024 * 1024 * 2), contains('GB'));
    });

    test('Mishary Rashid Alafasy is recognized as pre-bundled reciter 7', () {
      final reciter = reciterById(7);
      expect(reciter.en, contains('Mishary'));
      expect(reciter.ar, contains('مشاري'));
    });
  });
}
