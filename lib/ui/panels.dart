import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../audio/ambient_mixer.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import 'glass.dart';

enum PanelKind { surahs, reciters, ambient, settings }

/// Right-hand glass drawer hosting one of the four panels.
class SidePanel extends StatelessWidget {
  final PanelKind kind;
  final VoidCallback onClose;
  const SidePanel({super.key, required this.kind, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final isLight = s.themeMode == AppThemeMode.light;
    final bg = isLight
        ? const Color(0xFFF7F7FA)
        : const Color(0xFF18181B);
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
          PanelKind.ambient => _AmbientPanel(onClose: onClose),
          PanelKind.settings => _SettingsPanel(onClose: onClose),
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

class _AmbientPanel extends StatefulWidget {
  final VoidCallback onClose;
  const _AmbientPanel({required this.onClose});

  @override
  State<_AmbientPanel> createState() => _AmbientPanelState();
}

class _AmbientPanelState extends State<_AmbientPanel> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final mixer = s.mixer;

    // Filter channels based on selected category
    final channelIndices = <int>[];
    for (var i = 0; i < mixer.channels.length; i++) {
      if (_selectedCategory == 'all' ||
          mixer.channels[i].category == _selectedCategory) {
        channelIndices.add(i);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with active counter and Mute All action
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
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: s.themeMode.ink,
                      ),
                    ),
                    if (mixer.activeCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: s.themeMode.accent.withValues(alpha: 0.18),
                          border: Border.all(
                            color: s.themeMode.accent.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '${mixer.activeCount} ${s.tr('activeSounds')}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: s.themeMode.accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (mixer.activeCount > 0)
                GlassButton(
                  size: 34,
                  tooltip: s.tr('muteAll'),
                  icon: Icon(
                    Icons.volume_off_rounded,
                    size: 16,
                    color: s.themeMode.inkSoft,
                  ),
                  onTap: () {
                    mixer.muteAll();
                    s.saveAmbient();
                  },
                ),
              if (mixer.activeCount > 0) const SizedBox(width: 6),
              GlassButton(
                size: 34,
                icon: Icon(
                  Icons.close_rounded,
                  size: 17,
                  color: s.themeMode.ink,
                ),
                onTap: widget.onClose,
              ),
            ],
          ),
        ),

        // Master Volume Frosted Card
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  mixer.toggleMasterMute();
                  s.saveAmbient();
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: mixer.master > 0
                        ? s.themeMode.accent.withValues(alpha: 0.20)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                  child: Icon(
                    mixer.master == 0
                        ? Icons.volume_off_rounded
                        : (mixer.master < 0.5
                            ? Icons.volume_down_rounded
                            : Icons.volume_up_rounded),
                    size: 17,
                    color: mixer.master > 0
                        ? s.themeMode.accent
                        : s.themeMode.inkSoft,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.tr('masterVolume'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: s.themeMode.inkSoft,
                          ),
                        ),
                        Text(
                          '${(mixer.master * 100).round()}%',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: s.themeMode.ink,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3.5,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                          elevation: 1,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                        activeTrackColor: s.themeMode.accent,
                        inactiveTrackColor: Colors.white.withValues(
                          alpha: 0.12,
                        ),
                        thumbColor: s.themeMode.accent,
                        overlayColor: s.themeMode.accent.withValues(
                          alpha: 0.15,
                        ),
                      ),
                      child: Slider(
                        value: mixer.master,
                        onChanged: (v) {
                          mixer.setMaster(v);
                          s.saveAmbient();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Sync with Quran Reciter (Vibe Mode toggle)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: mixer.syncWithReciter
                ? s.themeMode.accent.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: mixer.syncWithReciter
                  ? s.themeMode.accent.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.sync_rounded,
                size: 16,
                color: mixer.syncWithReciter
                    ? s.themeMode.accent
                    : s.themeMode.inkSoft,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.tr('syncWithReciter'),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: s.themeMode.ink,
                      ),
                    ),
                    Text(
                      s.tr('syncWithReciterDesc'),
                      style: TextStyle(
                        fontSize: 9.5,
                        color: s.themeMode.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.72,
                child: Switch.adaptive(
                  value: mixer.syncWithReciter,
                  activeThumbColor: s.themeMode.accent,
                  onChanged: (v) => s.setSyncAmbientWithReciter(v),
                ),
              ),
            ],
          ),
        ),

        // Soundscapes (Curated Mixes) Section
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 13,
                color: s.themeMode.accent,
              ),
              const SizedBox(width: 5),
              Text(
                s.tr('soundscapes'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: s.themeMode.inkSoft,
                ),
              ),
            ],
          ),
        ),

        SizedBox(
          height: 33,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: kAmbientPresets.length,
            separatorBuilder: (context, index) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final p = kAmbientPresets[i];
              final isSelected = mixer.isPresetActive(p);
              return GestureDetector(
                onTap: () {
                  mixer.applyPreset(p);
                  s.saveAmbient();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isSelected
                        ? s.themeMode.accent.withValues(alpha: 0.24)
                        : Colors.white.withValues(alpha: 0.07),
                    border: Border.all(
                      color: isSelected
                          ? s.themeMode.accent
                          : Colors.white.withValues(alpha: 0.12),
                      width: isSelected ? 1.2 : 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        p.icon,
                        size: 13,
                        color: isSelected
                            ? s.themeMode.accent
                            : s.themeMode.inkSoft,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        s.ar ? p.ar : p.en,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? s.themeMode.ink
                              : s.themeMode.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Category Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              for (final cat in [
                ('all', 'allCategory'),
                ('water', 'waterCategory'),
                ('nature', 'natureCategory'),
                ('sky', 'skyCategory'),
              ]) ...[
                GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: _selectedCategory == cat.$1
                          ? Colors.white.withValues(alpha: 0.14)
                          : Colors.transparent,
                    ),
                    child: Text(
                      s.tr(cat.$2),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: _selectedCategory == cat.$1
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: _selectedCategory == cat.$1
                            ? s.themeMode.ink
                            : s.themeMode.inkSoft,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ],
          ),
        ),

        // Channel Cards List
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: channelIndices.length,
            itemBuilder: (context, i) {
              return _AmbientSoundCard(index: channelIndices[i]);
            },
          ),
        ),
      ],
    );
  }
}

class _AmbientSoundCard extends StatelessWidget {
  final int index;
  const _AmbientSoundCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final mixer = s.mixer;
    final c = mixer.channels[index];

    final isLight = s.themeMode.brightness == Brightness.light;
    final activeBg = isLight ? const Color(0xFFFBF4E6) : const Color(0xFF262118);
    final inactiveBg = isLight ? Colors.white : const Color(0xFF222226);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(11, 8, 11, 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: c.on ? activeBg : inactiveBg,
        border: Border.all(
          color: c.on
              ? s.themeMode.accent
              : (isLight ? const Color(0xFFE4E4E7) : const Color(0xFF2E2E33)),
          width: c.on ? 1.1 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isLight ? const Color(0x08000000) : const Color(0x22000000),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: Icon, Title & Category, Equalizer Wave, Toggle
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  mixer.toggle(index);
                  s.saveAmbient();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.on
                        ? (isLight ? const Color(0xFFF5E8CF) : const Color(0xFF332A1C))
                        : (isLight ? const Color(0xFFF4F4F5) : const Color(0xFF2A2A30)),
                  ),
                  child: Icon(
                    c.icon,
                    size: 17,
                    color: c.on ? s.themeMode.accent : s.themeMode.inkSoft,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    mixer.toggle(index);
                    s.saveAmbient();
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.ar ? c.ar : c.en,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: c.on ? FontWeight.w700 : FontWeight.w600,
                          color: c.on
                              ? s.themeMode.ink
                              : s.themeMode.ink.withValues(alpha: 0.65),
                        ),
                      ),
                      Text(
                        s.tr('${c.category}Category'),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: s.themeMode.inkSoft.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (c.on) ...[
                _MiniEqualizer(
                  playing: c.on && mixer.master > 0,
                  color: s.themeMode.accent,
                ),
                const SizedBox(width: 8),
              ],
              _GlassToggle(
                active: c.on,
                accentColor: s.themeMode.accent,
                onTap: () {
                  mixer.toggle(index);
                  s.saveAmbient();
                },
              ),
            ],
          ),

          // Bottom Row: Slider and Level Percentage
          Row(
            children: [
              Icon(
                c.volume == 0
                    ? Icons.volume_off_rounded
                    : (c.volume < 0.5
                        ? Icons.volume_down_rounded
                        : Icons.volume_up_rounded),
                size: 14,
                color: c.on
                    ? s.themeMode.accent.withValues(alpha: 0.85)
                    : s.themeMode.inkSoft.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2.8,
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: c.on ? 5.5 : 4.5,
                      elevation: 1,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
                    activeTrackColor: c.on
                        ? s.themeMode.accent
                        : Colors.white.withValues(alpha: 0.25),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.10),
                    thumbColor: c.on ? s.themeMode.accent : s.themeMode.inkSoft,
                    overlayColor: s.themeMode.accent.withValues(alpha: 0.15),
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
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: c.on
                        ? s.themeMode.ink
                        : s.themeMode.inkSoft.withValues(alpha: 0.5),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassToggle extends StatelessWidget {
  final bool active;
  final Color accentColor;
  final VoidCallback onTap;

  const _GlassToggle({
    required this.active,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36,
        height: 20,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: active
              ? accentColor
              : (isLight ? const Color(0xFFD4D4D8) : const Color(0xFF2E2E33)),
          border: Border.all(
            color: active
                ? accentColor
                : (isLight ? const Color(0xFFC4C4C8) : const Color(0xFF38383E)),
            width: 1,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          alignment: active
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? (isLight ? Colors.white : const Color(0xFF1B1B1D))
                  : Colors.white,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
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
            children: [
              _bar(h1),
              _bar(h2),
              _bar(h3),
            ],
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

class _SettingsPanel extends StatefulWidget {
  final VoidCallback onClose;
  const _SettingsPanel({required this.onClose});

  @override
  State<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<_SettingsPanel> {
  Map<String, dynamic>? credits;

  @override
  void initState() {
    super.initState();
    rootBundle
        .loadString('assets/bg/credits.json')
        .then((v) {
          if (mounted) {
            setState(() => credits = jsonDecode(v) as Map<String, dynamic>);
          }
        })
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final mode = s.themeMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelHeader(title: s.tr('settings'), onClose: widget.onClose),
        Expanded(
          child: ListView(
            children: [
              _SectionLabel(s.tr('language')),
              Row(
                children: [
                  for (final (code, label) in const [
                    ('en', 'English'),
                    ('ar', 'العربية'),
                  ])
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        selected: s.locale.languageCode == code,
                        selectedColor: mode.accent.withValues(alpha: 0.3),
                        label: Text(
                          label,
                          style: TextStyle(fontSize: 13, color: mode.ink),
                        ),
                        onSelected: (_) => s.setLocale(Locale(code)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionLabel(s.tr('watchfaces')),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.35,
                children: [
                  for (var i = 0; i < kWatchfaces.length; i++)
                    _WatchfaceTile(
                      watchface: kWatchfaces[i],
                      isSelected: i == s.watchface,
                      onTap: () => s.setWatchface(i),
                      isAr: s.ar,
                      accent: mode.accent,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.showTranslation,
                activeThumbColor: mode.accent,
                title: Text(
                  s.tr('translation'),
                  style: TextStyle(fontSize: 14, color: mode.ink),
                ),
                onChanged: (_) => s.toggleTranslation(),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.autoAdvance,
                activeThumbColor: mode.accent,
                title: Text(
                  s.tr('autoAdvance'),
                  style: TextStyle(fontSize: 14, color: mode.ink),
                ),
                onChanged: (_) => s.toggleAutoAdvance(),
              ),
              const SizedBox(height: 18),
              _SectionLabel(s.tr('arabicScale')),
              Row(
                children: [
                  for (final (scale, label) in const [
                    (0.9, 'Small'),
                    (1.0, 'Normal'),
                    (1.18, 'Large'),
                    (1.32, 'Extra'),
                  ])
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        selected: (s.arabicTextScale - scale).abs() < 0.06,
                        selectedColor: mode.accent.withValues(alpha: 0.3),
                        label: Text(
                          label,
                          style: TextStyle(fontSize: 12, color: mode.ink),
                        ),
                        onSelected: (_) => s.setArabicTextScale(scale),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionLabel(s.tr('credits')),
              if (credits != null)
                for (final e in (credits as Map).values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${e['label']} — ${(e['artist'] ?? '').toString().trim().isEmpty ? 'unknown' : e['artist']}',
                          style: TextStyle(fontSize: 12, color: mode.ink),
                        ),
                        Text(
                          '${e['license']} • Wikimedia Commons',
                          style: TextStyle(fontSize: 11, color: mode.inkSoft),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 10),
              Text(
                'Noor — recitation by quran.com, text & translation © their respective authors. Font: Amiri Quran (OFL).',
                style: TextStyle(fontSize: 11, color: mode.inkSoft),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
          color: s.themeMode.inkSoft,
        ),
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
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
          width: 1,
        ),
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

class _WatchfaceTile extends StatelessWidget {
  final Watchface watchface;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isAr;
  final Color accent;

  const _WatchfaceTile({
    required this.watchface,
    required this.isSelected,
    required this.onTap,
    required this.isAr,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final title = watchface.name(isAr);

    Widget content;
    Color? tileBg;
    Border border;

    if (watchface.isWhite) {
      tileBg = const Color(0xFFFAFAFA);
      border = Border.all(
        color: isSelected ? accent : const Color(0xFFD4D4D8),
        width: isSelected ? 2.2 : 1.0,
      );
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.light_mode_rounded,
            size: 20,
            color: isSelected ? accent : const Color(0xFF1E1E22),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? accent : const Color(0xFF1E1E22),
            ),
          ),
        ],
      );
    } else if (watchface.isBlack) {
      tileBg = const Color(0xFF0F0F12);
      border = Border.all(
        color: isSelected ? accent : const Color(0xFF333338),
        width: isSelected ? 2.2 : 1.0,
      );
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dark_mode_rounded,
            size: 20,
            color: isSelected ? accent : Colors.white,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? accent : Colors.white,
            ),
          ),
        ],
      );
    } else {
      border = Border.all(
        color: isSelected ? accent : Colors.white.withValues(alpha: 0.18),
        width: isSelected ? 2.2 : 1.0,
      );
      content = Stack(
        fit: StackFit.expand,
        children: [
          if (watchface.asset != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.asset(
                watchface.asset!,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x10000000), Color(0x99000000)],
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            left: 4,
            right: 4,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? accent : Colors.white,
                shadows: const [
                  Shadow(color: Colors.black, blurRadius: 4),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(14),
          border: border,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: content,
      ),
    );
  }
}

