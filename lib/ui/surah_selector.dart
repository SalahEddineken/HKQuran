import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';

/// Floating circular trigger button matching the eject button in Pic 2.
class SurahMenuButton extends StatefulWidget {
  final double size;
  final bool isOpen;
  final VoidCallback onTap;

  const SurahMenuButton({
    super.key,
    this.size = 46,
    required this.isOpen,
    required this.onTap,
  });

  @override
  State<SurahMenuButton> createState() => _SurahMenuButtonState();
}

class _SurahMenuButtonState extends State<SurahMenuButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final isLight = s.themeMode == AppThemeMode.light;

    return Tooltip(
      message: s.tr('surahs'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.92 : (_hovered ? 1.05 : 1.0),
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isOpen
                    ? (isLight ? const Color(0xFF1E1E22) : Colors.white)
                    : (isLight ? Colors.white : const Color(0xFF222226)),
                border: Border.all(
                  color: isLight
                      ? const Color(0xFFE4E4E7)
                      : const Color(0xFF38383E),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: widget.isOpen ? 0.22 : (_hovered ? 0.16 : 0.10),
                    ),
                    blurRadius: widget.isOpen ? 12 : (_hovered ? 10 : 6),
                    spreadRadius: widget.isOpen ? 1 : 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.eject_rounded,
                  size: widget.size * 0.48,
                  color: widget.isOpen
                      ? (isLight ? Colors.white : const Color(0xFF1E1E22))
                      : (isLight ? const Color(0xFF1E1E22) : Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating selector popover matching Pic 2.
/// Displays a smooth rounded card with the Surah name on the left
/// and the Surah logo disc on the right.
class SurahSelectorPopup extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final double endOffset;
  final double bottomOffset;

  const SurahSelectorPopup({
    super.key,
    required this.isOpen,
    required this.onClose,
    this.endOffset = 34,
    this.bottomOffset = 88,
  });

  @override
  State<SurahSelectorPopup> createState() => _SurahSelectorPopupState();
}

class _SurahSelectorPopupState extends State<SurahSelectorPopup> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _query = '';
  int? _hoveredChapter;
  bool _scrolledToCurrent = false;

  @override
  void didUpdateWidget(covariant SurahSelectorPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _scrolledToCurrent = false;
      _query = '';
      _searchController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveSurah());
    }
  }

  void _scrollToActiveSurah() {
    if (!mounted || _scrolledToCurrent || !_scrollController.hasClients) return;
    final s = AppStateScope.of(context);
    final targetIndex = s.chapter - 1;
    if (targetIndex >= 0 && targetIndex < kSurahs.length) {
      // 52px item height + 6px padding
      final offset = (targetIndex * 54.0 - 120.0).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      _scrolledToCurrent = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    final s = AppStateScope.of(context);
    final size = MediaQuery.sizeOf(context);
    final isSmall = size.width < 600 || size.height < 760;

    final cardWidth = isSmall
        ? math.min(230.0, size.width * 0.82)
        : 248.0;
    final maxH = math.min(size.height - widget.bottomOffset - 24, 560.0);

    final filtered = kSurahs.where((m) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return m.en.toLowerCase().contains(q) ||
          m.ar.contains(_query) ||
          m.arShort.contains(_query) ||
          m.n.toString() == _query;
    }).toList();

    return PositionedDirectional(
      end: widget.endOffset,
      bottom: widget.bottomOffset,
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, anim, child) {
            return Transform.translate(
              offset: Offset(0, (1.0 - anim) * 14.0),
              child: Opacity(
                opacity: anim,
                child: Transform.scale(
                  scale: 0.96 + (0.04 * anim),
                  alignment: Alignment.bottomRight,
                  child: child,
                ),
              ),
            );
          },
          child: Container(
            width: cardWidth,
            height: maxH,
            decoration: BoxDecoration(
              // Sleek luxury black card surface
              color: const Color(0xFF141416),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFF28282E),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 36,
                  spreadRadius: 2,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Column(
                children: [
                  // Sleek search input at the top
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E22),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF2B2B32),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.search_rounded,
                            size: 17,
                            color: Color(0xFF8E8E93),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _query = v),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              cursorColor: Colors.white,
                              decoration: InputDecoration(
                                hintText: s.tr('search'),
                                hintStyle: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF71717A),
                                ),
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          if (_query.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 15,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Divider line under search
                  Container(
                    height: 1,
                    color: const Color(0xFF202024),
                  ),

                  // Scrollable Surah list
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                s.tr('emptySearch'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF71717A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        : ScrollConfiguration(
                            behavior: const ScrollBehavior().copyWith(
                              scrollbars: false,
                            ),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 10,
                              ),
                              physics: const BouncingScrollPhysics(),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final m = filtered[index];
                                final isSelected = m.n == s.chapter;
                                final isHovered = m.n == _hoveredChapter;
                                final isPlaying = isSelected && s.player.playing;

                                return _SurahRowItem(
                                  meta: m,
                                  isSelected: isSelected,
                                  isHovered: isHovered,
                                  isPlaying: isPlaying,
                                  isArabicLocale: s.ar,
                                  onEnter: () {
                                    if (mounted) {
                                      setState(() => _hoveredChapter = m.n);
                                    }
                                  },
                                  onExit: () {
                                    if (mounted && _hoveredChapter == m.n) {
                                      setState(() => _hoveredChapter = null);
                                    }
                                  },
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    s.openSurah(m.n);
                                    widget.onClose();
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An individual row item in the selector:
/// - Surah Name on the left (right-aligned towards the disc, as in Pic 2)
/// - Surah Logo Disc on the right
class _SurahRowItem extends StatelessWidget {
  final SurahMeta meta;
  final bool isSelected;
  final bool isHovered;
  final bool isPlaying;
  final bool isArabicLocale;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  final VoidCallback onTap;

  const _SurahRowItem({
    required this.meta,
    required this.isSelected,
    required this.isHovered,
    required this.isPlaying,
    required this.isArabicLocale,
    required this.onEnter,
    required this.onExit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Text styling: In Pic 2, selected item is deep dark/prominent,
    // inactive items are clean grey.
    final Color textColor = isSelected
        ? Colors.white
        : (isHovered ? const Color(0xFFF4F4F6) : const Color(0xFFA1A1AA));

    final FontWeight fontWeight = isSelected
        ? FontWeight.w700
        : (isHovered ? FontWeight.w600 : FontWeight.w500);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onEnter(),
      onExit: (_) => onExit(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 48,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF25252B)
                : (isHovered ? const Color(0xFF1C1C20) : Colors.transparent),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              // Surah Name on the left (aligned right towards the disc, just like Pic 2)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isArabicLocale ? meta.arShort : meta.en,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: isArabicLocale ? 'UthmanicHafs' : null,
                        fontSize: isArabicLocale ? 15.5 : 13.5,
                        fontWeight: fontWeight,
                        color: textColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (isSelected)
                      Text(
                        isArabicLocale
                            ? '${meta.ayahs} آية'
                            : '${meta.ayahs} ayahs',
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF8E8E93),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Surah Logo Disc on the right (matches the circular vinyl disc with white dot in Pic 2)
              _SurahDisc(
                chapter: meta.n,
                meta: meta,
                isSelected: isSelected,
                isHovered: isHovered,
                isPlaying: isPlaying,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular vinyl disc for a Surah with a white center hole (spindle dot)
/// exactly as seen in Pic 2.
class _SurahDisc extends StatefulWidget {
  final int chapter;
  final SurahMeta meta;
  final bool isSelected;
  final bool isHovered;
  final bool isPlaying;

  const _SurahDisc({
    required this.chapter,
    required this.meta,
    required this.isSelected,
    required this.isHovered,
    required this.isPlaying,
  });

  @override
  State<_SurahDisc> createState() => _SurahDiscState();
}

class _SurahDiscState extends State<_SurahDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  static const List<List<Color>> _discPalettes = [
    [Color(0xFF2E3192), Color(0xFF1BFFFF)], // Ocean
    [Color(0xFFD4145A), Color(0xFFFBB03B)], // Sunset / Calm
    [Color(0xFF662D8C), Color(0xFFED1E79)], // Violet Dream
    [Color(0xFF009245), Color(0xFFFCEE21)], // Forest Dawn
    [Color(0xFF1F4037), Color(0xFF99F2C8)], // Emerald Mist
    [Color(0xFF4A00E0), Color(0xFF8E2DE2)], // Night Sky
    [Color(0xFFFFA07A), Color(0xFF8A2BE2)], // Dusk Glow
    [Color(0xFF3A1C71), Color(0xFFD76D77), Color(0xFFFFAF7B)], // Brazilian Vibes
    [Color(0xFF141E30), Color(0xFF243B55)], // Deep Midnight
    [Color(0xFFF857A6), Color(0xFFFF5858)], // Rose
    [Color(0xFF200122), Color(0xFF6f0000)], // Fireplace / Maroon
    [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)], // Calm River
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    if (widget.isPlaying) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _SurahDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!widget.isPlaying && _rotationController.isAnimating) {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = 40.0;
    final palette = _discPalettes[(widget.chapter - 1) % _discPalettes.length];

    Widget discVisual = Image.asset(
      'assets/Surahs logo/${widget.chapter}.jpg',
      fit: BoxFit.cover,
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) {
        return _buildFallbackDisc(size, palette);
      },
    );

    return AnimatedScale(
      scale: widget.isHovered ? 1.08 : (widget.isSelected ? 1.04 : 1.0),
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: widget.isSelected ? 0.24 : 0.12,
              ),
              blurRadius: widget.isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Spinning vinyl artwork / disc
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: child,
                  );
                },
                child: SizedBox(
                  width: size,
                  height: size,
                  child: discVisual,
                ),
              ),

              // Concentric vinyl rings overlay
              CustomPaint(
                size: const Size(size, size),
                painter: const _DiscGroovesPainter(),
              ),

              // The signature White Center Hole (Spindle Dot) from Pic 2!
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.15),
                    width: 0.6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 1.5,
                      offset: const Offset(0, 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackDisc(double size, List<Color> palette) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: palette,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          widget.meta.arShort,
          maxLines: 1,
          style: const TextStyle(
            fontFamily: 'UthmanicHafs',
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Color(0x88000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints subtle concentric vinyl grooves over the disc
class _DiscGroovesPainter extends CustomPainter {
  const _DiscGroovesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final r = size.width / 2;
    canvas.drawCircle(center, r * 0.55, paint);
    canvas.drawCircle(center, r * 0.72, paint);
    canvas.drawCircle(center, r * 0.88, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
