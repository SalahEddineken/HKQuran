import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

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
    return liquid(
      width: 372,
      radius: 0,
      tint: Colors.black.withValues(alpha: 0.35),
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
            fillColor: Colors.white.withValues(alpha: 0.07),
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
                              ? s.themeMode.accent.withValues(alpha: 0.22)
                              : Colors.white.withValues(alpha: 0.08),
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

class _AmbientPanel extends StatelessWidget {
  final VoidCallback onClose;
  const _AmbientPanel({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final mixer = s.mixer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelHeader(title: s.tr('ambient'), onClose: onClose),
        Expanded(
          child: ListView(
            children: [
              for (var i = 0; i < mixer.channels.length; i++)
                _AmbientRow(index: i),
              const SizedBox(height: 10),
              Divider(color: Colors.white.withValues(alpha: 0.12)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.volume_up_rounded,
                    size: 18,
                    color: s.themeMode.inkSoft,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.tr('masterVolume'),
                      style: TextStyle(
                        fontSize: 13,
                        color: s.themeMode.inkSoft,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: Slider(
                      value: mixer.master,
                      activeColor: s.themeMode.accent,
                      inactiveColor: Colors.white.withValues(alpha: 0.15),
                      onChanged: (v) {
                        mixer.setMaster(v);
                        s.saveAmbient();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AmbientRow extends StatelessWidget {
  final int index;
  const _AmbientRow({required this.index});

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final mixer = s.mixer;
    final c = mixer.channels[index];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          GlassButton(
            size: 40,
            color: c.on
                ? s.themeMode.accent.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.08),
            icon: Icon(
              c.icon,
              size: 19,
              color: c.on ? s.themeMode.accent : s.themeMode.inkSoft,
            ),
            onTap: () {
              mixer.toggle(index);
              s.saveAmbient();
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.ar ? c.ar : c.en,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: c.on
                        ? s.themeMode.ink
                        : s.themeMode.ink.withValues(alpha: 0.55),
                  ),
                ),
                Slider(
                  value: c.volume,
                  onChanged: (v) {
                    mixer.setVolume(index, v);
                    s.saveAmbient();
                  },
                ),
              ],
            ),
          ),
        ],
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
                      padding: const EdgeInsets.only(right: 8),
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
              _SectionLabel(s.tr('appearance')),
              Row(
                children: [
                  for (final t in AppThemeMode.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Tooltip(
                        message: t.label,
                        child: GestureDetector(
                          onTap: () => s.setTheme(t),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: t.scrim,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: t == mode
                                    ? mode.accent
                                    : Colors.white.withValues(alpha: 0.2),
                                width: t == mode ? 2.4 : 1.2,
                              ),
                            ),
                            child: Icon(
                              t == AppThemeMode.light
                                  ? Icons.light_mode_rounded
                                  : t == AppThemeMode.dark
                                  ? Icons.dark_mode_rounded
                                  : Icons.auto_awesome_rounded,
                              size: 18,
                              color: t == mode ? mode.accent : Colors.white70,
                            ),
                          ),
                        ),
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
                    GestureDetector(
                      onTap: () => s.setWatchface(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: i == s.watchface
                                ? mode.accent
                                : Colors.white.withValues(alpha: 0.15),
                            width: i == s.watchface ? 2.2 : 1,
                          ),
                          image: kWatchfaces[i].asset != null
                              ? DecorationImage(
                                  image: AssetImage(kWatchfaces[i].asset!),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                    Colors.black.withValues(alpha: 0.25),
                                    BlendMode.darken,
                                  ),
                                )
                              : null,
                          color: kWatchfaces[i].asset == null
                              ? (i == 0 ? const Color(0xFFEDEDED) : null)
                              : null,
                        ),
                        child: kWatchfaces[i].asset == null
                            ? Center(
                                child: Text(
                                  'Plain',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: i == 0
                                        ? Colors.black54
                                        : mode.inkSoft,
                                  ),
                                ),
                              )
                            : null,
                      ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          child: child,
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
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Text(
        '$n',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: ink.withValues(alpha: 0.85),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
