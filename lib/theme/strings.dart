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

/// A ripple-free splash so glass surfaces stay pristine.
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
