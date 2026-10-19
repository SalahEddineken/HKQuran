import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/reciter_download_service.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';

/// Floating circular trigger button matching SurahMenuButton.
class ReciterMenuButton extends StatefulWidget {
  final double size;
  final bool isOpen;
  final VoidCallback onTap;

  const ReciterMenuButton({
    super.key,
    this.size = 46,
    required this.isOpen,
    required this.onTap,
  });

  @override
  State<ReciterMenuButton> createState() => _ReciterMenuButtonState();
}

class _ReciterMenuButtonState extends State<ReciterMenuButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final isLight = s.themeMode == AppThemeMode.light;

    return Tooltip(
      message: s.tr('reciters'),
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
                  Icons.record_voice_over_rounded,
                  size: widget.size * 0.44,
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

/// Floating selector popover matching SurahSelectorPopup UI.
/// Displays a smooth rounded white card with reciter search and selection.
class ReciterSelectorPopup extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final double endOffset;
  final double bottomOffset;

  const ReciterSelectorPopup({
    super.key,
    required this.isOpen,
    required this.onClose,
    this.endOffset = 34,
    this.bottomOffset = 88,
  });

  @override
  State<ReciterSelectorPopup> createState() => _ReciterSelectorPopupState();
}

class _ReciterSelectorPopupState extends State<ReciterSelectorPopup> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _query = '';
  int? _hoveredId;
  bool _scrolledToCurrent = false;

  @override
  void didUpdateWidget(covariant ReciterSelectorPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _scrolledToCurrent = false;
      _query = '';
      _searchController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveReciter());
    }
  }

  void _scrollToActiveReciter() {
    if (!mounted || _scrolledToCurrent || !_scrollController.hasClients) return;
    final s = AppStateScope.of(context);
    final targetIndex = kReciters.indexWhere((r) => r.id == s.reciterId);
    if (targetIndex >= 0) {
      final offset = (targetIndex * 58.0 - 80.0).clamp(
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
        ? math.min(250.0, size.width * 0.85)
        : 268.0;
    final maxH = math.min(size.height - widget.bottomOffset - 24, 480.0);

    final filtered = kReciters.where((r) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return r.en.toLowerCase().contains(q) ||
          r.ar.contains(_query) ||
          r.origin.toLowerCase().contains(q);
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

                  // Scrollable Reciters list
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
                                final r = filtered[index];
                                final isSelected = r.id == s.reciterId;
                                final isHovered = r.id == _hoveredId;

                                return _ReciterRowItem(
                                  reciter: r,
                                  isSelected: isSelected,
                                  isHovered: isHovered,
                                  isArabicLocale: s.ar,
                                  onEnter: () {
                                    if (mounted) {
                                      setState(() => _hoveredId = r.id);
                                    }
                                  },
                                  onExit: () {
                                    if (mounted && _hoveredId == r.id) {
                                      setState(() => _hoveredId = null);
                                    }
                                  },
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    if (r.id != s.reciterId) {
                                      s.changeReciter(r.id);
                                    }
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

/// An individual row item in the reciter selector:
/// - Reciter name & details on the left
/// - Circular badge with checkmark or avatar on the right
class _ReciterRowItem extends StatelessWidget {
  final Reciter reciter;
  final bool isSelected;
  final bool isHovered;
  final bool isArabicLocale;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  final VoidCallback onTap;

  const _ReciterRowItem({
    required this.reciter,
    required this.isSelected,
    required this.isHovered,
    required this.isArabicLocale,
    required this.onEnter,
    required this.onExit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = isSelected
        ? Colors.white
        : (isHovered ? const Color(0xFFF4F4F6) : const Color(0xFFA1A1AA));

    final Color bgColor = isSelected
        ? const Color(0xFF25252B)
        : (isHovered ? const Color(0xFF1C1C20) : Colors.transparent);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => onEnter(),
        onExit: (_) => onExit(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                // Text Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: isArabicLocale
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isArabicLocale ? reciter.ar : reciter.en,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: textColor,
                          fontFamily: isArabicLocale ? 'UthmanicHafs' : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              isArabicLocale ? reciter.en : reciter.origin,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF71717A),
                              ),
                            ),
                          ),
                          if (!kIsWeb) ...[
                            const SizedBox(width: 6),
                            if (reciter.id == 7) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF34C759)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isArabicLocale ? 'مضمّن' : 'Bundled',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF34C759),
                                ),
                              ),
                            ),
                          ] else ...[
                            ListenableBuilder(
                              listenable: ReciterDownloadService.instance,
                              builder: (context, _) {
                                final isDlAll = ReciterDownloadService
                                    .instance
                                    .isDownloadingAll(reciter.id);
                                final count = ReciterDownloadService
                                    .instance
                                    .getDownloadedCount(reciter.id);
                                if (isDlAll) {
                                  return const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Color(0xFFF0C878),
                                      ),
                                    ),
                                  );
                                }
                                if (count == 114) {
                                  return const Icon(
                                    Icons.check_circle_rounded,
                                    size: 13,
                                    color: Color(0xFF34C759),
                                  );
                                }
                                return InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    ReciterDownloadService.instance
                                        .downloadAllSurahs(reciter.id);
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.cloud_download_outlined,
                                        size: 12,
                                        color: Color(0xFF8E8E93),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        count > 0
                                            ? '$count/114'
                                            : (isArabicLocale
                                                ? 'تحميل'
                                                : 'Download'),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF8E8E93),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Reciter Photo Avatar on the right
                _ReciterAvatar(
                  reciter: reciter,
                  isSelected: isSelected,
                  isHovered: isHovered,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular portrait avatar displaying the authentic photo for the reciter
/// with smooth scaling on hover, border, subtle drop shadow, and active check badge.
class _ReciterAvatar extends StatelessWidget {
  final Reciter reciter;
  final bool isSelected;
  final bool isHovered;

  const _ReciterAvatar({
    required this.reciter,
    required this.isSelected,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 36.0;

    return AnimatedScale(
      scale: isHovered ? 1.06 : (isSelected ? 1.02 : 1.0),
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFF0C878)
                      : (isHovered
                          ? const Color(0xFF52525B)
                          : const Color(0xFF2E2E34)),
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isSelected ? 0.28 : (isHovered ? 0.16 : 0.08),
                    ),
                    blurRadius: isSelected ? 8 : (isHovered ? 5 : 3),
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/reciters/${reciter.id}.jpg',
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isSelected
                          ? const Color(0xFF26262B)
                          : const Color(0xFF1E1E22),
                      child: Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF71717A),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (isSelected)
              PositionedDirectional(
                end: -2,
                bottom: -2,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0C878),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF141416), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 9,
                      color: Color(0xFF141416),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

