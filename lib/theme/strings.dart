import 'package:flutter/material.dart';

/// Tiny bilingual string table (English / Arabic).
const Map<String, Map<String, String>> kStrings = {
  'appName': {'en': 'Noor', 'ar': 'نور'},
  'focus': {'en': 'Focus', 'ar': 'تركيز'},
  'min': {'en': 'min', 'ar': 'د'},
  'endFocus': {'en': 'End focus', 'ar': 'إنهاء التركيز'},
  'surahs': {'en': 'Surahs', 'ar': 'السور'},
  'reciters': {'en': 'Reciters', 'ar': 'القرّاء'},
  'ambient': {'en': 'Ambient', 'ar': 'أصوات محيطة'},
  'settings': {'en': 'Settings', 'ar': 'الإعدادات'},
  'reader': {'en': 'Read along', 'ar': 'المصحف'},
  'play': {'en': 'Play', 'ar': 'تشغيل'},
  'pause': {'en': 'Pause', 'ar': 'إيقاف'},
  'translation': {'en': 'Translation', 'ar': 'الترجمة'},
  'language': {'en': 'Language', 'ar': 'اللغة'},
  'theme': {'en': 'Theme', 'ar': 'المظهر'},
  'appearance': {'en': 'Appearance', 'ar': 'المظهر العام'},
  'watchfaces': {'en': 'Backgrounds', 'ar': 'الخلفيات'},
  'masterVolume': {'en': 'Master volume', 'ar': 'مستوى الصوت العام'},
  'loading': {'en': 'Loading recitation…', 'ar': 'جاري تحميل التلاوة…'},
  'error': {'en': 'Something went wrong', 'ar': 'حدث خطأ ما'},
  'retry': {'en': 'Try again', 'ar': 'أعد المحاولة'},
  'close': {'en': 'Close', 'ar': 'إغلاق'},
  'search': {'en': 'Search surah…', 'ar': 'ابحث عن سورة…'},
  'emptySearch': {'en': 'No surah matches', 'ar': 'لا توجد نتائج'},
  'about': {'en': 'About', 'ar': 'حول التطبيق'},
  'credits': {'en': 'Image credits', 'ar': 'مصادر الصور'},
  'bismillah': {
    'en': 'In the name of God, the Most Gracious, the Most Merciful',
    'ar': 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
  },
  'nowPlaying': {'en': 'Now playing', 'ar': 'قيد التشغيل'},
  'tapToJump': {
    'en': 'Tap an ayah to jump to it',
    'ar': 'اضغط على آية للانتقال إليها',
  },
  'soundscapes': {'en': 'Soundscapes', 'ar': 'أجواء مختارة'},
  'activeSounds': {'en': 'active', 'ar': 'نشط'},
  'muteAll': {'en': 'Silence all', 'ar': 'إسكات الكل'},
  'allCategory': {'en': 'All', 'ar': 'الكل'},
  'waterCategory': {'en': 'Water', 'ar': 'مياه'},
  'natureCategory': {'en': 'Nature', 'ar': 'طبيعة'},
  'skyCategory': {'en': 'Sky', 'ar': 'سماء'},
  'stream': {'en': 'Stream', 'ar': 'جدول ماء'},
  'birds': {'en': 'Birds', 'ar': 'طيور'},
  'thunder': {'en': 'Thunder', 'ar': 'رعد'},
  'desert': {'en': 'Desert Breeze', 'ar': 'نسيم الصحراء'},
  'droplets': {'en': 'Rain on Glass', 'ar': 'قطرات زجاج'},
  'ocean': {'en': 'Ocean', 'ar': 'محيط'},
  'rain': {'en': 'Rain', 'ar': 'مطر'},
  'fire': {'en': 'Fireplace', 'ar': 'موقد نار'},
  'wind': {'en': 'Wind', 'ar': 'رياح'},
  'night': {'en': 'Night', 'ar': 'ليل'},
  'presetRainstorm': {'en': 'Rainstorm', 'ar': 'عاصفة ماطرة'},
  'presetRawdah': {'en': 'Rawdah', 'ar': 'الروضة'},
  'presetCoastal': {'en': 'Coast', 'ar': 'شاطئ'},
  'presetSanctuary': {'en': 'Sanctuary', 'ar': 'سكينة'},
  'presetTahajjud': {'en': 'Tahajjud Rain', 'ar': 'مطر التهجد'},
  'vibeQuran': {'en': 'Viby Quran', 'ar': 'تلاوة وأجواء'},
  'vibeDesc': {
    'en': 'Blend reciter and ambient atmosphere',
    'ar': 'امزج تلاوة القارئ بالأصوات المحيطة',
  },
  'reciterVolume': {'en': 'Reciter volume', 'ar': 'صوت القارئ'},
  'ambientVolume': {'en': 'Ambient volume', 'ar': 'صوت الأجواء'},
  'syncWithReciter': {'en': 'Sync with Reciter', 'ar': 'مزامنة مع القارئ'},
  'syncWithReciterDesc': {
    'en': 'Play atmosphere when Quran is reciting, fade when paused',
    'ar': 'تشغيل الأجواء مع التلاوة والتلاشي عند الإيقاف',
  },
  'customizeSounds': {'en': '10-Channel Mixer', 'ar': 'موزع القنوات العشر'},
  'vibeActive': {'en': 'Vibe mix active', 'ar': 'المزيج نشط'},
  'blended': {'en': 'Reciter & Ambience blended', 'ar': 'تلاوة ممتزجة مع الأجواء'},
  'tapToVibe': {
    'en': 'Select an atmosphere to mix with recitation',
    'ar': 'اختر أجواء للمزج مع التلاوة',
  },
  'speed': {'en': 'Speed', 'ar': 'السرعة'},
  'repeat': {'en': 'Repeat', 'ar': 'تكرار'},
  'repeatOff': {'en': 'Repeat: Off', 'ar': 'التكرار: معطل'},
  'repeatSurah': {'en': 'Repeat Surah', 'ar': 'تكرار السورة'},
  'repeatAyah': {'en': 'Repeat Ayah (Hifdh)', 'ar': 'تكرار الآية (حفظ)'},
  'bookmark': {'en': 'Bookmark', 'ar': 'إشارة مرجعية'},
  'bookmarked': {'en': 'Bookmarked', 'ar': 'تم حفظ الإشارة'},
  'resumeBookmark': {'en': 'Resume', 'ar': 'متابعة'},
  'autoAdvance': {'en': 'Auto-advance to next Surah', 'ar': 'تشغيل السورة التالية تلقائياً'},
  'arabicScale': {'en': 'Quran font size', 'ar': 'حجم خط المصحف'},
  'mute': {'en': 'Mute', 'ar': 'كتم'},
  'unmute': {'en': 'Unmute', 'ar': 'إلغاء الكتم'},
  'sessionComplete': {'en': 'Focus session completed', 'ar': 'اكتملت جلسة التركيز'},
  'alhamdulillah': {'en': 'Alhamdulillah', 'ar': 'الحمد لله'},
  'wordInfo': {'en': 'Word meaning', 'ar': 'معنى الكلمة'},
};

extension StringsX on BuildContext {
  String tr(String key, {required bool ar}) {
    final m = kStrings[key];
    if (m == null) return key;
    return m[ar ? 'ar' : 'en'] ?? m['en'] ?? key;
  }
}

ThemeData noorTheme(Brightness brightness, Color seed) {
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    scaffoldBackgroundColor: brightness == Brightness.light
        ? const Color(0xFFEDEDED)
        : const Color(0xFF111111),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: brightness == Brightness.light
          ? const Color(0xFF111111)
          : Colors.white,
      displayColor: brightness == Brightness.light
          ? const Color(0xFF111111)
          : Colors.white,
    ),
    splashFactory: NoRipple.splashFactory,
  );
}

/// A clean ripple-free splash factory for crisp, high-performance interactions.
class NoRipple extends InteractiveInkFeatureFactory {
  const NoRipple();
  static const splashFactory = NoRipple();

  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    Rect Function()? rectCallback,
    BorderRadius? borderRadius,
    double? radius,
    ShapeBorder? customBorder,
    VoidCallback? onRemoved,
  }) {
    return _NoRippleFeature(
      controller: controller,
      referenceBox: referenceBox,
      color: color,
    );
  }
}

class _NoRippleFeature extends InteractiveInkFeature {
  _NoRippleFeature({
    required super.controller,
    required super.referenceBox,
    required super.color,
  });

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) {}
}
