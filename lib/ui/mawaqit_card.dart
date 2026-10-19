import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/prayer_times_service.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';

class MawaqitCard extends StatefulWidget {
  final VoidCallback? onClose;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const MawaqitCard({
    super.key,
    this.onClose,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  State<MawaqitCard> createState() => _MawaqitCardState();
}

class _MawaqitCardState extends State<MawaqitCard> {
  void _openCitySelector(
    BuildContext context,
    PrayerTimesService service,
    AppState s,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final isLight = s.themeMode == AppThemeMode.light;
            final bg = isLight
                ? const Color(0xFFF9F9FB)
                : const Color(0xFF161619);
            final ink = isLight ? const Color(0xFF1E1E22) : Colors.white;
            final sub = isLight
                ? const Color(0xFF71717A)
                : const Color(0xFF8E8E93);

            final filtered = PrayerTimesService.predefinedCities.where((c) {
              if (searchQuery.isEmpty) return true;
              final q = searchQuery.toLowerCase();
              final ar = (c['nameAr'] as String).toLowerCase();
              final en = (c['nameEn'] as String).toLowerCase();
              final coAr = (c['countryAr'] as String).toLowerCase();
              return ar.contains(q) || en.contains(q) || coAr.contains(q);
            }).toList();

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                width: 380,
                height: 520,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isLight
                        ? const Color(0xFFE4E4E8)
                        : const Color(0xFF2E2E34),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Title Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 20,
                            color: s.themeMode.accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.ar
                                  ? 'اختر المدينة لمواقيت الصلاة'
                                  : 'Select City for Prayer Times',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: ink,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: sub,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ),

                    // Auto-detect button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          service.autoDetectLocation();
                          Navigator.of(ctx).pop();
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: s.themeMode.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: s.themeMode.accent.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.my_location_rounded,
                                size: 16,
                                color: s.themeMode.accent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                s.ar
                                    ? 'تحديد الموقع تلقائياً (IP)'
                                    : 'Auto-Detect Location (IP)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: s.themeMode.accent,
                                ),
                              ),
                              if (service.loading) ...[
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      s.themeMode.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Search input
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: isLight
                              ? const Color(0xFFEEEEF2)
                              : const Color(0xFF222226),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, size: 17, color: sub),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (v) =>
                                    setDialogState(() => searchQuery = v),
                                style: TextStyle(fontSize: 13, color: ink),
                                decoration: InputDecoration(
                                  hintText: s.ar
                                      ? 'بحث عن مدينة أو دولة...'
                                      : 'Search city or country...',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: sub,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // City List
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: isLight
                              ? const Color(0xFFECECEF)
                              : const Color(0xFF222226),
                        ),
                        itemBuilder: (cContext, idx) {
                          final item = filtered[idx];
                          final isSelected =
                              item['nameAr'] == service.cityName ||
                              item['nameEn'] == service.cityName;
                          return InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              service.setLocation(
                                latitude: (item['lat'] as num).toDouble(),
                                longitude: (item['lon'] as num).toDouble(),
                                cityName: s.ar
                                    ? item['nameAr']
                                    : item['nameEn'],
                                countryName: item['countryAr'],
                                calcMethod: item['method'],
                                save: true,
                              );
                              Navigator.of(ctx).pop();
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.ar
                                              ? item['nameAr']
                                              : item['nameEn'],
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? s.themeMode.accent
                                                : ink,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item['countryAr'],
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: sub,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 18,
                                      color: s.themeMode.accent,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  IconData _iconForPrayer(PrayerKind kind) {
    switch (kind) {
      case PrayerKind.fajr:
        return Icons.nights_stay_rounded;
      case PrayerKind.sunrise:
        return Icons.wb_twilight_rounded;
      case PrayerKind.dhuhr:
        return Icons.wb_sunny_rounded;
      case PrayerKind.asr:
        return Icons.wb_sunny_outlined;
      case PrayerKind.maghrib:
        return Icons.bedtime_outlined;
      case PrayerKind.isha:
        return Icons.dark_mode_rounded;
      case PrayerKind.none:
        return Icons.access_time_rounded;
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final service = s.prayerService;
    final mode = s.themeMode;
    final isLight = mode.brightness == Brightness.light;

    final cardBg = isLight ? const Color(0xFFFAFBFD) : const Color(0xFF161619);
    final borderColor = isLight
        ? const Color(0xFFE4E4E8)
        : const Color(0xFF2E2E34);
    final ink = mode.ink;
    final sub = mode.inkSoft;
    final accent = mode.accent;

    if (widget.isCollapsed) {
      final nextPrayer = service.getNextPrayer();
      final (nextAr, nextEn) = service.getPrayerNames(nextPrayer);
      final nextLabel = s.ar ? nextAr : nextEn;

      return Tooltip(
        message: s.ar ? 'عرض مواقيت الصلاة' : 'Show Prayer Times',
        waitDuration: const Duration(milliseconds: 300),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onToggleCollapse,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.mosque_rounded, size: 16, color: accent),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.ar ? 'المواقيت' : 'Prayers',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: ink,
                      ),
                    ),
                    if (nextLabel.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '· $nextLabel',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: sub,
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Icon(
                      s.ar ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                      size: 18,
                      color: sub,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final schedule = service.getSchedule();
    final nextPrayer = service.getNextPrayer();
    final (nextAr, nextEn) = service.getPrayerNames(nextPrayer);
    final remaining = service.getRemainingToNextPrayer();
    final timeFormatter = DateFormat(
      s.ar ? 'h:mm a' : 'h:mm a',
      s.ar ? 'ar' : 'en',
    );

    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Header ----
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.15),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.mosque_rounded,
                        size: 16,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.ar ? 'مواقيت الصلاة' : 'Prayer Times',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ink,
                          ),
                        ),
                        InkWell(
                          onTap: () => _openCitySelector(context, service, s),
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 11,
                                color: accent,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  service.cityName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 14,
                                color: accent,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onToggleCollapse != null)
                    IconButton(
                      icon: Icon(
                        Icons.first_page_rounded,
                        size: 18,
                        color: sub,
                      ),
                      tooltip: s.ar ? 'تصغير' : 'Collapse',
                      onPressed: widget.onToggleCollapse,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                    ),
                ],
              ),
            ),

            // ---- Next Prayer Countdown Spotlight Card ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLight
                        ? [const Color(0xFFFFF7E6), const Color(0xFFFFF0D4)]
                        : [const Color(0xFF282319), const Color(0xFF1E1A14)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.35),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.ar
                                ? 'الصلاة القادمة: $nextAr'
                                : 'Next Prayer: $nextEn',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatDuration(remaining),
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: ink,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(_iconForPrayer(nextPrayer), size: 26, color: accent),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // ---- Prayer Schedule List ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: schedule.map((item) {
                  final isCurrent = item.isCurrent;
                  final isNext = item.isNext;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2.5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7.5,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? accent.withValues(alpha: isLight ? 0.12 : 0.18)
                          : (isNext
                                ? (isLight
                                      ? const Color(0xFFF1F1F5)
                                      : const Color(0xFF1E1E22))
                                : Colors.transparent),
                      borderRadius: BorderRadius.circular(12),
                      border: isCurrent
                          ? Border.all(
                              color: accent.withValues(alpha: 0.4),
                              width: 1.0,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _iconForPrayer(item.kind),
                          size: 15,
                          color: isCurrent ? accent : sub,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            s.ar ? item.nameAr : item.nameEn,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isCurrent || isNext
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isCurrent ? accent : ink,
                            ),
                          ),
                        ),
                        Text(
                          timeFormatter.format(item.time),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent || isNext
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: isCurrent ? accent : (isNext ? ink : sub),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // ---- Footer Quick Controls ----
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isLight
                        ? const Color(0xFFECECEF)
                        : const Color(0xFF222226),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      service.toggleAdhanSound(!service.adhanSoundEnabled);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            service.adhanSoundEnabled
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_off_rounded,
                            size: 14,
                            color: service.adhanSoundEnabled ? accent : sub,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            s.ar ? 'تنبيه الأذان' : 'Adhan Alert',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: service.adhanSoundEnabled ? accent : sub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _openCitySelector(context, service, s),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_city_rounded, size: 14, color: sub),
                          const SizedBox(width: 4),
                          Text(
                            s.ar ? 'المدينة' : 'City',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: sub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
