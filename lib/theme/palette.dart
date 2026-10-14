import 'package:flutter/material.dart';

enum AppThemeMode { light, dark }

extension AppThemeModeX on AppThemeMode {
  String get label => switch (this) {
    AppThemeMode.light => 'Light',
    AppThemeMode.dark => 'Dark',
  };

  /// Scrim painted over the background photo so text stays readable.
  Color get scrim => switch (this) {
    AppThemeMode.light => const Color(0xF2EDEDED),
    AppThemeMode.dark => const Color(0xB3000000),
  };

  Brightness get brightness =>
      this == AppThemeMode.light ? Brightness.light : Brightness.dark;

  Color get ink =>
      this == AppThemeMode.light ? const Color(0xFF111111) : Colors.white;

  Color get inkSoft => switch (this) {
    AppThemeMode.light => const Color(0xFF9F9F9F),
    AppThemeMode.dark => const Color(0xFFA0A0A0),
  };

  Color get accent => switch (this) {
    AppThemeMode.light => const Color(0xFF9A6B12),
    AppThemeMode.dark => const Color(0xFFF0C878),
  };

  Color get seed => switch (this) {
    AppThemeMode.light => const Color(0xFF6B5CE7),
    AppThemeMode.dark => const Color(0xFF7F8AA6),
  };
}

enum WatchfaceKind { white, black, image }

class Watchface {
  final WatchfaceKind kind;
  final String? asset;
  final String nameEn;
  final String nameAr;

  const Watchface({
    required this.kind,
    this.asset,
    required this.nameEn,
    required this.nameAr,
  });

  bool get isWhite => kind == WatchfaceKind.white;
  bool get isBlack => kind == WatchfaceKind.black;
  bool get isImage => kind == WatchfaceKind.image;

  String name(bool ar) => ar ? nameAr : nameEn;
}

const List<Watchface> kWatchfaces = [
  Watchface(
    kind: WatchfaceKind.white,
    nameEn: 'White',
    nameAr: 'أبيض',
  ),
  Watchface(
    kind: WatchfaceKind.black,
    nameEn: 'Black',
    nameAr: 'أسود',
  ),
  Watchface(
    kind: WatchfaceKind.image,
    asset: 'assets/bg/bg1.jpg',
    nameEn: 'Mosque',
    nameAr: 'مسجد',
  ),
  Watchface(
    kind: WatchfaceKind.image,
    asset: 'assets/bg/bg2.jpg',
    nameEn: 'Night sky',
    nameAr: 'سماء ليلية',
  ),
  Watchface(
    kind: WatchfaceKind.image,
    asset: 'assets/bg/bg3.jpg',
    nameEn: 'Rain',
    nameAr: 'مطر',
  ),
  Watchface(
    kind: WatchfaceKind.image,
    asset: 'assets/bg/bg4.jpg',
    nameEn: 'Ocean',
    nameAr: 'محيط',
  ),
  Watchface(
    kind: WatchfaceKind.image,
    asset: 'assets/bg/bg5.jpg',
    nameEn: 'Fire',
    nameAr: 'نار',
  ),
  Watchface(
    kind: WatchfaceKind.image,
    asset: 'assets/bg/bg6.jpg',
    nameEn: 'Snow',
    nameAr: 'ثلج',
  ),
];

