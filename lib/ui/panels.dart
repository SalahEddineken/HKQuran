import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:url_launcher/url_launcher.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import 'adhkar_panel.dart';
import '../audio/reciter_download_service.dart';
import '../services/desktop_window_service.dart';
import '../services/notification_service.dart';
import 'glass.dart';

enum PanelKind { surahs, reciters, ambient, settings, adhkar }

/// Right-hand glass drawer hosting one of the panels.
class SidePanel extends StatelessWidget {
  final PanelKind kind;
  final VoidCallback onClose;
  const SidePanel({super.key, required this.kind, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final isLight = s.themeMode == AppThemeMode.light;
    final bg = isLight ? const Color(0xFFF7F7FA) : const Color(0xFF18181B);
    final size = MediaQuery.sizeOf(context);
    final panelWidth = math.min(372.0, size.width * 0.92);
    return liquid(
      width: panelWidth,
      radius: 0,
      tint: bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        child: switch (kind) {
          PanelKind.surahs => _SurahPanel(onClose: onClose),
          PanelKind.reciters => _ReciterPanel(onClose: onClose),
          PanelKind.ambient => AmbientPanel(onClose: onClose),
          PanelKind.settings => SettingsPanel(onClose: onClose),
          PanelKind.adhkar => AdhkarPanel(onClose: onClose),
        },
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  const _PanelHeader({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: s.themeMode.ink,
              ),
            ),
          ),
          GlassButton(
            size: 36,
            icon: Icon(Icons.close_rounded, size: 18, color: s.themeMode.ink),
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- surahs

class _SurahPanel extends StatefulWidget {
  final VoidCallback onClose;
  const _SurahPanel({required this.onClose});

  @override
  State<_SurahPanel> createState() => _SurahPanelState();
}

class _SurahPanelState extends State<_SurahPanel> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final items = kSurahs.where((m) {
      if (query.isEmpty) return true;
      final q = query.toLowerCase();
      return m.en.toLowerCase().contains(q) ||
          m.ar.contains(query) ||
          m.n.toString() == query ||
          m.arShort.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelHeader(title: s.tr('surahs'), onClose: widget.onClose),
        TextField(
          autofocus: false,
          onChanged: (v) => setState(() => query = v),
          style: TextStyle(fontSize: 14, color: s.themeMode.ink),
          cursorColor: s.themeMode.accent,
          decoration: InputDecoration(
            hintText: s.tr('search'),
            hintStyle: TextStyle(color: s.themeMode.inkSoft, fontSize: 14),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: s.themeMode.inkSoft,
              size: 20,
            ),
            isDense: true,
            filled: true,
            fillColor: s.themeMode == AppThemeMode.light
                ? Colors.black.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    s.tr('emptySearch'),
                    style: TextStyle(color: s.themeMode.inkSoft),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final m = items[i];
                    final selected = m.n == s.chapter;
                    return _Tile(
                      selected: selected,
                      onTap: () {
                        widget.onClose();
                        s.openSurah(m.n);
                      },
                      child: Row(
                        children: [
                          _NumberBadge(
                            n: m.n,
                            accent: s.themeMode.accent,
                            ink: s.themeMode.ink,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.ar ? m.arShort : m.en,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: s.themeMode.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s.ar
                                      ? '${m.ayahs} آية • ${m.type == 'Meccan' ? 'مكية' : 'مدنية'}'
                                      : '${m.ayahs} ayahs • ${m.enMeaning}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: s.themeMode.inkSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            m.arShort,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: 'UthmanicHafs',
                              fontSize: 17,
                              color: s.themeMode.ink.withValues(
                                alpha: selected ? 1 : 0.75,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------- reciters

class _ReciterPanel extends StatelessWidget {
  final VoidCallback onClose;
  const _ReciterPanel({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelHeader(title: s.tr('reciters'), onClose: onClose),
        Expanded(
          child: ListView(
            children: [
              for (final r in kReciters)
                _Tile(
                  selected: r.id == s.reciterId,
                  onTap: () {
                    onClose();
                    if (r.id != s.reciterId) s.changeReciter(r.id);
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: r.id == s.reciterId
                              ? (s.themeMode.brightness == Brightness.light
                                    ? const Color(0xFFF5E8CF)
                                    : const Color(0xFF332A1C))
                              : (s.themeMode.brightness == Brightness.light
                                    ? const Color(0xFFE4E4E7)
                                    : const Color(0xFF27272A)),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          size: 20,
                          color: r.id == s.reciterId
                              ? s.themeMode.accent
                              : s.themeMode.inkSoft,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.ar ? r.ar : r.en,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: s.themeMode.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.ar ? r.en : r.origin,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: s.themeMode.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (r.id == s.reciterId)
                        Icon(
                          Icons.check_circle_rounded,
                          size: 19,
                          color: s.themeMode.accent,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------- ambient

class AmbientPanel extends StatelessWidget {
  final VoidCallback? onClose;
  const AmbientPanel({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final mixer = s.mixer;
    final isLight = s.themeMode.brightness == Brightness.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      s.tr('ambient'),
                      style: TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: s.themeMode.ink,
                      ),
                    ),
                    if (mixer.activeCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: s.themeMode.accent.withValues(
                            alpha: isLight ? 0.14 : 0.20,
                          ),
                        ),
                        child: Text(
                          '${mixer.activeCount}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: s.themeMode.accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (mixer.activeCount > 0)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    mixer.muteAll();
                    s.saveAmbient();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Text(
                      s.tr('muteAll'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: s.themeMode.inkSoft,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Master Volume Bar (Clean, integrated, minimal)
        Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.fromLTRB(11, 7, 11, 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: isLight ? const Color(0xFFF3F4F6) : const Color(0xFF1E1E22),
            border: Border.all(
              color: isLight
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFF2A2A30),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  mixer.toggleMasterMute();
                  s.saveAmbient();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 2,
                  ),
                  child: Icon(
                    mixer.master == 0
                        ? Icons.volume_off_rounded
                        : (mixer.master < 0.5
                              ? Icons.volume_down_rounded
                              : Icons.volume_up_rounded),
                    size: 18,
                    color: mixer.master > 0
                        ? s.themeMode.accent
                        : s.themeMode.inkSoft.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                s.tr('masterVolume'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: s.themeMode.inkSoft,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3.2,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5.2,
                      elevation: 0,
                      pressedElevation: 1,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                    activeTrackColor: s.themeMode.accent,
                    inactiveTrackColor: isLight
                        ? const Color(0xFFDFE2E6)
                        : const Color(0xFF2E2E35),
                    thumbColor: mixer.master > 0
                        ? s.themeMode.accent
                        : (isLight
                              ? const Color(0xFF9CA3AF)
                              : s.themeMode.inkSoft),
                    overlayColor: s.themeMode.accent.withValues(alpha: 0.12),
                  ),
                  child: Slider(
                    value: mixer.master,
                    onChanged: (v) {
                      mixer.setMaster(v);
                      s.saveAmbient();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 32,
                child: Text(
                  '${(mixer.master * 100).round()}%',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: mixer.master > 0
                        ? s.themeMode.ink
                        : s.themeMode.inkSoft.withValues(alpha: 0.5),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Channels List
        Flexible(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < mixer.channels.length; i++)
                  _AmbientSoundRow(index: i),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AmbientSoundRow extends StatelessWidget {
  final int index;
  const _AmbientSoundRow({required this.index});

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final mixer = s.mixer;
    final c = mixer.channels[index];

    final isLight = s.themeMode.brightness == Brightness.light;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(vertical: 3.5),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: c.on
            ? (isLight ? const Color(0xFFFFFFFF) : const Color(0xFF1E1E22))
            : (isLight ? const Color(0xFFFAFAFC) : const Color(0xFF17171A)),
        border: Border.all(
          color: c.on
              ? (isLight
                    ? s.themeMode.accent.withValues(alpha: 0.38)
                    : s.themeMode.accent.withValues(alpha: 0.32))
              : (isLight ? const Color(0xFFE8E8EC) : const Color(0xFF242428)),
          width: c.on ? 0.9 : 0.6,
        ),
        boxShadow: c.on
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.16),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Left: Tap target to toggle sound
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              mixer.toggle(index);
              s.saveAmbient();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    color: c.on
                        ? s.themeMode.accent.withValues(
                            alpha: isLight ? 0.15 : 0.22,
                          )
                        : (isLight
                              ? const Color(0xFFF3F4F6)
                              : const Color(0xFF222226)),
                  ),
                  child: Icon(
                    c.icon,
                    size: 18,
                    color: c.on ? s.themeMode.accent : s.themeMode.inkSoft,
                  ),
                ),
                const SizedBox(width: 9),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 104),
                  child: Text(
                    s.ar ? c.ar : c.en,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: c.on ? FontWeight.w600 : FontWeight.w500,
                      color: c.on ? s.themeMode.ink : s.themeMode.inkSoft,
                    ),
                  ),
                ),
                if (c.on) ...[
                  const SizedBox(width: 5),
                  _MiniEqualizer(
                    playing: c.on && mixer.master > 0,
                    color: s.themeMode.accent,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Right: Seamless volume slider + percentage
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3.2,
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: c.on ? 5.2 : 4.2,
                  elevation: 0,
                  pressedElevation: 1,
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 11),
                activeTrackColor: c.on
                    ? s.themeMode.accent
                    : (isLight
                          ? const Color(0xFFD1D5DB)
                          : const Color(0xFF44444C)),
                inactiveTrackColor: isLight
                    ? const Color(0xFFE5E7EB)
                    : const Color(0xFF26262B),
                thumbColor: c.on
                    ? s.themeMode.accent
                    : (isLight
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF55555C)),
                overlayColor: s.themeMode.accent.withValues(alpha: 0.12),
              ),
              child: Slider(
                value: c.volume,
                onChanged: (v) {
                  mixer.setVolume(index, v);
                  s.saveAmbient();
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 32,
            child: Text(
              '${(c.volume * 100).round()}%',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: c.on
                    ? s.themeMode.ink
                    : s.themeMode.inkSoft.withValues(alpha: 0.4),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniEqualizer extends StatefulWidget {
  final bool playing;
  final Color color;
  const _MiniEqualizer({required this.playing, required this.color});

  @override
  State<_MiniEqualizer> createState() => _MiniEqualizerState();
}

class _MiniEqualizerState extends State<_MiniEqualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    if (widget.playing) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _MiniEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.playing && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = widget.playing ? _ctrl.value : 0.0;
        final h1 = 3.5 + (widget.playing ? t * 7.5 : 0.0);
        final h2 = 3.5 + (widget.playing ? (1.0 - t) * 9.0 : 0.0);
        final h3 = 3.5 + (widget.playing ? math.sin(t * math.pi) * 8.0 : 0.0);

        return SizedBox(
          width: 14,
          height: 14,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [_bar(h1), _bar(h2), _bar(h3)],
          ),
        );
      },
    );
  }

  Widget _bar(double h) {
    return Container(
      width: 2.6,
      height: h.clamp(3.0, 14.0),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(1.3),
      ),
    );
  }
}

// -------------------------------------------------------------- settings

class SettingsPanel extends StatefulWidget {
  final VoidCallback? onClose;
  const SettingsPanel({super.key, this.onClose});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching $url: $e');
    }
  }

  static double _nearestScale(double current) {
    const scales = [0.9, 1.0, 1.18, 1.32];
    double closest = scales.first;
    double minDiff = (current - closest).abs();
    for (final s in scales) {
      final diff = (current - s).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = s;
      }
    }
    return closest;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final mode = s.themeMode;
    final isLight = mode == AppThemeMode.light;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---- Official Brand Header ----
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white : const Color(0xFF1E2D2B),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: isLight
                          ? const Color(0x18000000)
                          : const Color(0x33F59E0B),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isLight ? 0.04 : 0.25,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Image.asset(
                      'assets/logo/hkquran_emblem_transparent.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/logo/hkquran_app_icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.ar
                        ? 'مصحف الحكيم (“HK-Quran”) — تجربة هادئة ونقية لقراءة وتدبر القرآن الكريم.'
                        : 'HK-Quran (“Zero Noise”) is a calm, minimalist sanctuary for daily Quran focus.',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                      color: mode.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (widget.onClose != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onClose,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: isLight
                            ? const Color(0xFF71717A)
                            : const Color(0xFFA1A1AA),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.ar
                ? 'صُمم بتصميم هادئ وخلوّ من التشتيت مع تلاوات خاشعة وتنبيهات أذكار وأوقات الصلاة.'
                : 'Designed around calm software and mindful living, with serene recitations, peaceful typography, and offline prayers.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: isLight
                  ? const Color(0xFF71717A)
                  : const Color(0xFFA1A1AA),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              height: 1,
              thickness: 1,
              color: isLight
                  ? const Color(0x12000000)
                  : const Color(0x1FFFFFFF),
            ),
          ),

          // ---- Language selector ----
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  s.tr('language'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: mode.ink,
                  ),
                ),
                const Spacer(),
                _MinimalPill(
                  options: const [('en', 'English'), ('ar', 'العربية')],
                  selected: s.locale.languageCode,
                  onSelect: (code) => s.setLocale(Locale(code)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // ---- Translation toggle ----
          _MinimalToggleRow(
            label: s.tr('translation'),
            subtitle: s.ar
                ? 'عرض معاني الآيات باللغة الإنجليزية'
                : 'Show English verse translation',
            value: s.showTranslation,
            onChanged: (val) => s.setTranslation(val),
          ),

          // ---- Auto advance toggle ----
          _MinimalToggleRow(
            label: s.tr('autoAdvance'),
            value: s.autoAdvance,
            onChanged: (_) => s.toggleAutoAdvance(),
          ),

          // ---- Arabic text size ----
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  s.tr('arabicScale'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: mode.ink,
                  ),
                ),
                const Spacer(),
                _MinimalPill(
                  options: const [
                    ('0.9', 'S'),
                    ('1.0', 'M'),
                    ('1.18', 'L'),
                    ('1.32', 'XL'),
                  ],
                  selected: _nearestScale(s.arabicTextScale).toString(),
                  onSelect: (val) => s.setArabicTextScale(double.parse(val)),
                ),
              ],
            ),
          ),

          if (!kIsWeb) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(
                height: 1,
                thickness: 1,
                color: isLight
                    ? const Color(0x12000000)
                    : const Color(0x1FFFFFFF),
              ),
            ),

            // Prayer location row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.prayerService.cityName.isEmpty
                              ? (s.ar ? 'مواقيت الصلاة' : 'Prayer Times')
                              : '${s.prayerService.cityName}, ${s.prayerService.countryName}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: mode.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.ar
                              ? 'تلقائي بناءً على موقعك'
                              : 'Based on local coordinates',
                          style: TextStyle(
                            fontSize: 11,
                            color: isLight
                                ? const Color(0xFF71717A)
                                : const Color(0xFFA1A1AA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      s.prayerService.autoDetectLocation();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isLight
                            ? const Color(0xFFF4F4F5)
                            : const Color(0xFF27272A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.my_location_rounded,
                            size: 12,
                            color: mode.accent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            s.ar ? 'تحديث' : 'Locate',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: mode.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Adhan Sound alert
            _MinimalToggleRow(
              label: s.ar ? 'أذان الصلاة' : 'Adhan Sound Alert',
              subtitle: s.ar
                  ? 'تنبيه صوتي عند دخول الوقت'
                  : 'Plays adhan sound at prayer times',
              value: s.prayerService.adhanSoundEnabled,
              onChanged: (val) => s.prayerService.toggleAdhanSound(val),
            ),

            // Dhikr notifications
            _MinimalToggleRow(
              label: s.ar ? 'إشعارات الأذكار' : 'Dhikr Notifications',
              subtitle: s.ar
                  ? 'تنبيهات ويندوز دورية في الزاوية'
                  : 'Periodic toast alerts on desktop',
              value: NotificationService.instance.enabled,
              onChanged: (v) {
                setState(() {});
                NotificationService.instance.setEnabled(v);
              },
            ),

            if (NotificationService.instance.enabled) ...[
              // Interval selector
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.ar ? 'تكرار الأذكار' : 'Notification Frequency',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: mode.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.ar
                                ? 'الفترة بين كل ذكر وآخر'
                                : 'How often reminders appear',
                            style: TextStyle(
                              fontSize: 11,
                              color: isLight
                                  ? const Color(0xFF71717A)
                                  : const Color(0xFFA1A1AA),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _MinimalPill(
                      options: [
                        ('10', s.ar ? '10 د' : '10m'),
                        ('15', s.ar ? '15 د' : '15m'),
                        ('20', s.ar ? '20 د' : '20m'),
                        ('30', s.ar ? '30 د' : '30m'),
                        ('60', s.ar ? '1 س' : '1h'),
                      ],
                      selected: NotificationService.instance.intervalMinutes
                          .toString(),
                      onSelect: (val) {
                        NotificationService.instance
                            .setIntervalMinutes(int.parse(val));
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),

              // Sound alert toggle ("not so annoying": silent by default)
              _MinimalToggleRow(
                label: s.ar ? 'صوت التنبيه' : 'Notification Sound',
                subtitle: s.ar
                    ? (NotificationService.instance.soundEnabled
                        ? 'تنبيه بصوت ويندوز'
                        : 'إشعار صامت هادئ وبدون إزعاج')
                    : (NotificationService.instance.soundEnabled
                        ? 'Play Windows alert chime'
                        : 'Silent toast, calm & non-intrusive'),
                value: NotificationService.instance.soundEnabled,
                onChanged: (val) {
                  NotificationService.instance.setSoundEnabled(val);
                  setState(() {});
                },
              ),

              // Test notification button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.ar ? 'تجربة إشعار الأذكار' : 'Test Dhikr Alert',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: mode.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.ar
                                ? 'إرسال إشعار فوري للتأكد من المظهر'
                                : 'Send an immediate desktop notification',
                            style: TextStyle(
                              fontSize: 11,
                              color: isLight
                                  ? const Color(0xFF71717A)
                                  : const Color(0xFFA1A1AA),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await NotificationService.instance
                            .showNextDhikrNotification(force: true);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                s.ar
                                    ? 'تم إرسال إشعار ذكر إلى سطح المكتب'
                                    : 'Sent dhikr notification to desktop',
                              ),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isLight
                              ? const Color(0xFFF4F4F5)
                              : const Color(0xFF27272A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_active_outlined,
                              size: 12,
                              color: mode.accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              s.ar ? 'تجربة الآن' : 'Test now',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: mode.accent,
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

            // Windows Startup
            _MinimalToggleRow(
              label: s.ar ? 'بدء التشغيل مع ويندوز' : 'Start with Windows',
              subtitle: s.ar
                  ? 'يبدأ مصغراً بهدوء'
                  : 'Starts minimized in background',
              value: DesktopWindowService.instance.startAtStartup,
              onChanged: (val) async {
                await DesktopWindowService.instance.setStartAtStartup(val);
                setState(() {});
              },
            ),

            // Minimize to Tray
            _MinimalToggleRow(
              label: s.ar
                  ? 'تصغير إلى شريط المهام'
                  : 'Minimize to Tray on Close',
              value: DesktopWindowService.instance.closeToTray,
              onChanged: (val) {
                DesktopWindowService.instance.setCloseToTray(val);
                setState(() {});
              },
            ),
          ],

          // ---- Action links (matching Zeno reference layout) ----
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(
              height: 1,
              thickness: 1,
              color: isLight
                  ? const Color(0x12000000)
                  : const Color(0x1FFFFFFF),
            ),
          ),

          _CleanLinkRow(
            label: s.ar ? 'زيارة موقع المطور →' : 'Explore website & apps →',
            onTap: () {
              HapticFeedback.lightImpact();
              _openUrl('https://salaheddineken.com');
            },
          ),
          _CleanLinkRow(
            label: s.ar
                ? 'مشروع جيت هاب مفتوح المصدر →'
                : 'Follow GitHub project →',
            onTap: () {
              HapticFeedback.lightImpact();
              _openUrl('https://github.com/SalahEddineken');
            },
          ),
          if (kIsWeb)
            _CleanLinkRow(
              label: s.ar
                  ? 'تحميل تطبيق سطح المكتب (Windows) →'
                  : 'Download desktop app (Windows) →',
              onTap: () {
                HapticFeedback.lightImpact();
                _openUrl('https://github.com/SalahEddineken/Quran/releases/latest');
              },
            ),

          if (!kIsWeb)
            FutureBuilder<int>(
              future: ReciterDownloadService.instance.getTotalStorageBytes(),
              builder: (context, snapshot) {
                final bytes = snapshot.data ?? 0;
                if (bytes <= 0) return const SizedBox.shrink();
                final formatted = ReciterDownloadService.instance.formatBytes(
                  bytes,
                );
                return _CleanLinkRow(
                  label: s.ar
                      ? 'مسح التلاوات المحملة ($formatted) →'
                      : 'Clear downloaded audio ($formatted) →',
                  isDestructive: true,
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    for (final r in kReciters) {
                      await ReciterDownloadService.instance.deleteReciterAudio(
                        r.id,
                      );
                    }
                    setState(() {});
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CleanLinkRow extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _CleanLinkRow({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_CleanLinkRow> createState() => _CleanLinkRowState();
}

class _CleanLinkRowState extends State<_CleanLinkRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final isLight = s.themeMode == AppThemeMode.light;
    final baseColor = widget.isDestructive ? Colors.redAccent : s.themeMode.ink;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _hovered
                        ? (widget.isDestructive
                              ? Colors.red
                              : s.themeMode.accent)
                        : baseColor,
                  ),
                ),
              ),
              AnimatedSlide(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                offset: _hovered ? Offset(s.ar ? -0.15 : 0.15, 0) : Offset.zero,
                child: Icon(
                  s.ar ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                  size: 15,
                  color: _hovered
                      ? (widget.isDestructive ? Colors.red : s.themeMode.accent)
                      : (isLight
                            ? const Color(0xFF71717A)
                            : const Color(0xFFA1A1AA)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MinimalToggleRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MinimalToggleRow({
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final mode = s.themeMode;
    final isLight = mode == AppThemeMode.light;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: mode.ink,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11,
                      color: isLight
                          ? const Color(0xFF71717A)
                          : const Color(0xFFA1A1AA),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Transform.scale(
            scale: 0.75,
            child: CupertinoSwitch(
              value: value,
              activeTrackColor: mode.accent,
              inactiveTrackColor: isLight
                  ? const Color(0xFFE4E4E7)
                  : const Color(0xFF2E2E34),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalPill extends StatelessWidget {
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _MinimalPill({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final isLight = s.themeMode == AppThemeMode.light;

    return Container(
      height: 26,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF4F4F5) : const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (value, label) in options)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelect(value);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selected == value
                      ? (isLight ? Colors.white : const Color(0xFF3F3F46))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: selected == value
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: selected == value
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: selected == value
                        ? s.themeMode.ink
                        : (isLight
                              ? const Color(0xFF71717A)
                              : const Color(0xFFA1A1AA)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- fragments

class _Tile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  const _Tile({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: child,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: selected
              ? liquid(
                  radius: 16,
                  tint: isLight
                      ? const Color(0xFFE4E4E7)
                      : const Color(0xFF27272A),
                  child: content,
                )
              : content,
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  final int n;
  final Color accent;
  final Color ink;
  const _NumberBadge({
    required this.n,
    required this.accent,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.16),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1),
      ),
      child: Center(
        child: Text(
          '$n',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ink.withValues(alpha: 0.90),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
