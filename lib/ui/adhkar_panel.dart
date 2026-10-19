import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/adhkar_data.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import 'glass.dart';

/// Clean, polished Adhkar & Tasbeeh modal dialog.
/// Built with refined typography, quiet craftsmanship, and zero AI clutter.
class AdhkarModal extends StatefulWidget {
  final VoidCallback onClose;
  final bool isCompact;

  const AdhkarModal({
    super.key,
    required this.onClose,
    this.isCompact = false,
  });

  @override
  State<AdhkarModal> createState() => _AdhkarModalState();
}

class _AdhkarModalState extends State<AdhkarModal> {
  // Static map to remember counts throughout the session
  static final Map<int, int> _sessionCounts = {};

  AdhkarCategory _activeCategory = AdhkarCategory.morning;
  int _currentIndex = 0;
  final FocusNode _focusNode = FocusNode();

  int _getCount(int id) => _sessionCounts[id] ?? 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _increment(DhikrItem item) {
    HapticFeedback.selectionClick();
    final current = _getCount(item.id);
    if (current < item.targetCount) {
      setState(() => _sessionCounts[item.id] = current + 1);
      if (current + 1 >= item.targetCount) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  void _reset(DhikrItem item) {
    HapticFeedback.lightImpact();
    setState(() => _sessionCounts[item.id] = 0);
  }

  void _next(int total) {
    if (_currentIndex < total - 1) {
      HapticFeedback.lightImpact();
      setState(() => _currentIndex++);
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      HapticFeedback.lightImpact();
      setState(() => _currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final mode = s.themeMode;
    final isLight = mode.brightness == Brightness.light;
    final ink = mode.ink;
    final sub = mode.inkSoft;
    final accent = mode.accent;
    final size = MediaQuery.sizeOf(context);

    final currentItems = AdhkarData.getByCategory(_activeCategory);
    if (_currentIndex >= currentItems.length) {
      _currentIndex = 0;
    }
    final activeDhikr = currentItems.isNotEmpty ? currentItems[_currentIndex] : null;
    final count = activeDhikr != null ? _getCount(activeDhikr.id) : 0;
    final target = activeDhikr?.targetCount ?? 1;

    final modalWidth = math.min(540.0, size.width * 0.92);
    final modalHeight = math.min(610.0, size.height * 0.88);

    final surfaceBg = isLight ? const Color(0xFFFAFAFC) : const Color(0xFF141416);
    final borderColor = isLight ? const Color(0xFFE4E4E8) : const Color(0xFF28282E);

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) {
          if (activeDhikr != null) _increment(activeDhikr);
          return KeyEventResult.handled;
        } else if (key == LogicalKeyboardKey.arrowRight) {
          if (s.ar) {
            _prev();
          } else {
            _next(currentItems.length);
          }
          return KeyEventResult.handled;
        } else if (key == LogicalKeyboardKey.arrowLeft) {
          if (s.ar) {
            _next(currentItems.length);
          } else {
            _prev();
          }
          return KeyEventResult.handled;
        } else if (key == LogicalKeyboardKey.keyR) {
          if (activeDhikr != null) _reset(activeDhikr);
          return KeyEventResult.handled;
        } else if (key == LogicalKeyboardKey.escape) {
          widget.onClose();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, anim, child) {
          return Transform.scale(
            scale: 0.96 + (0.04 * anim),
            child: Opacity(
              opacity: anim,
              child: child,
            ),
          );
        },
        child: Container(
          width: modalWidth,
          height: modalHeight,
          decoration: BoxDecoration(
            color: surfaceBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isLight ? 0.12 : 0.55),
                blurRadius: 40,
                spreadRadius: 2,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isLight ? 0.04 : 0.20),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---- Header Bar ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
                  child: Row(
                    children: [
                      // Quiet icon badge
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isLight ? 0.12 : 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.auto_stories_rounded,
                          size: 17,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              s.ar ? 'الأذكار والمسبحة' : 'Adhkar & Tasbeeh',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: ink,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              AdhkarData.getCategoryName(_activeCategory, s.ar),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: sub,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GlassButton(
                        size: 32,
                        icon: Icon(Icons.close_rounded, size: 16, color: ink),
                        onTap: widget.onClose,
                      ),
                    ],
                  ),
                ),

                // ---- Refined Segmented Category Tabs ----
                _CategoryTabs(
                  active: _activeCategory,
                  isAr: s.ar,
                  isLight: isLight,
                  ink: ink,
                  sub: sub,
                  onSelect: (cat) {
                    setState(() {
                      _activeCategory = cat;
                      _currentIndex = 0;
                    });
                  },
                ),

                // ---- Stepper Segment Indicators ----
                _DhikrStepper(
                  total: currentItems.length,
                  current: _currentIndex,
                  counts: _sessionCounts,
                  items: currentItems,
                  accent: accent,
                  isLight: isLight,
                  onSelect: (idx) => setState(() => _currentIndex = idx),
                ),

                // ---- Main Dhikr View Card ----
                if (activeDhikr != null) ...[
                  // Item meta bar (Dhikr number & Narration source)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: isLight ? const Color(0xFFF0F0F4) : const Color(0xFF1E1E23),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isLight ? const Color(0xFFE2E2E7) : const Color(0xFF2A2A31),
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            s.ar
                                ? 'الذكر ${_currentIndex + 1} من ${currentItems.length}'
                                : 'Dhikr ${_currentIndex + 1} of ${currentItems.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: sub,
                            ),
                          ),
                        ),
                        if (activeDhikr.source != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: isLight ? 0.09 : 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              activeDhikr.source!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Dhikr Arabic Text
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            activeDhikr.text,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 20.5,
                              height: 1.95,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'UthmanicHafs',
                              color: ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Virtue / Fadl Callout (clean, no emojis)
                  if (activeDhikr.fadl != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: isLight ? const Color(0xFFF7F7FA) : const Color(0xFF19191C),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isLight ? const Color(0xFFE8E8ED) : const Color(0xFF26262C),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.bookmark_border_rounded,
                                size: 14,
                                color: accent.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                activeDhikr.fadl!,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.45,
                                  color: sub,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ---- Interactive Navigation & Tasbeeh Counter Bar ----
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Previous Button
                            _NavArrowButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              tooltip: s.ar ? 'السابق' : 'Previous',
                              enabled: _currentIndex > 0,
                              ink: ink,
                              sub: sub,
                              onTap: _currentIndex > 0 ? () => _prev() : null,
                            ),

                            // Central Interactive Sebha Counter Button
                            _TasbeehCounterButton(
                              count: count,
                              target: target,
                              accent: accent,
                              ink: ink,
                              sub: sub,
                              isLight: isLight,
                              isAr: s.ar,
                              onTap: () => _increment(activeDhikr),
                            ),

                            // Next Button
                            _NavArrowButton(
                              icon: Icons.arrow_forward_ios_rounded,
                              tooltip: s.ar ? 'التالي' : 'Next',
                              enabled: _currentIndex < currentItems.length - 1,
                              ink: ink,
                              sub: sub,
                              onTap: _currentIndex < currentItems.length - 1
                                  ? () => _next(currentItems.length)
                                  : null,
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Subtle reset & shortcut footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (count > 0) ...[
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _reset(activeDhikr),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.restart_alt_rounded, size: 13, color: sub),
                                      const SizedBox(width: 4),
                                      Text(
                                        s.ar ? 'إعادة العداد' : 'Reset',
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
                              const SizedBox(width: 12),
                            ],
                            Text(
                              s.ar
                                  ? 'المسافة: تسبيح  •  الأسهم: تنقل  •  Esc: إغلاق'
                                  : 'Space: Count  •  Arrows: Navigate  •  Esc: Close',
                              style: TextStyle(
                                fontSize: 10,
                                color: sub.withValues(alpha: 0.45),
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Backward compatibility wrapper for callers expecting `AdhkarPanel`.
class AdhkarPanel extends StatelessWidget {
  final VoidCallback onClose;
  const AdhkarPanel({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return AdhkarModal(onClose: onClose, isCompact: true);
  }
}

// ---------------------------------------------------------------------------
// Supporting Subcomponents
// ---------------------------------------------------------------------------

class _CategoryTabs extends StatelessWidget {
  final AdhkarCategory active;
  final bool isAr;
  final bool isLight;
  final Color ink;
  final Color sub;
  final ValueChanged<AdhkarCategory> onSelect;

  const _CategoryTabs({
    required this.active,
    required this.isAr,
    required this.isLight,
    required this.ink,
    required this.sub,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final categories = AdhkarCategory.values;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFECECF1) : const Color(0xFF1B1B1E),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isLight ? const Color(0xFFE0E0E6) : const Color(0xFF28282E),
            width: 0.8,
          ),
        ),
        child: Row(
          children: categories.map((cat) {
            final isSelected = cat == active;
            String label;
            switch (cat) {
              case AdhkarCategory.morning:
                label = isAr ? 'الصباح' : 'Morning';
                break;
              case AdhkarCategory.evening:
                label = isAr ? 'المساء' : 'Evening';
                break;
              case AdhkarCategory.afterPrayer:
                label = isAr ? 'بعد الصلاة' : 'After Prayer';
                break;
              case AdhkarCategory.sleep:
                label = isAr ? 'النوم' : 'Sleep';
                break;
              case AdhkarCategory.tasbeeh:
                label = isAr ? 'تسبيح' : 'Tasbeeh';
                break;
            }

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(cat);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isLight ? Colors.white : const Color(0xFF28282E))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isLight ? 0.06 : 0.25,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? ink : sub,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DhikrStepper extends StatelessWidget {
  final int total;
  final int current;
  final Map<int, int> counts;
  final List<DhikrItem> items;
  final Color accent;
  final bool isLight;
  final ValueChanged<int> onSelect;

  const _DhikrStepper({
    required this.total,
    required this.current,
    required this.counts,
    required this.items,
    required this.accent,
    required this.isLight,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (total <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(total, (i) {
          final item = items[i];
          final c = counts[item.id] ?? 0;
          final isDone = c >= item.targetCount;
          final isCurrent = i == current;

          Color barColor;
          if (isDone) {
            barColor = const Color(0xFF34C759);
          } else if (isCurrent) {
            barColor = accent;
          } else {
            barColor = isLight ? const Color(0xFFE2E2E8) : const Color(0xFF28282E);
          }

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: isCurrent ? 4.5 : 3.0,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavArrowButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final Color ink;
  final Color sub;
  final VoidCallback? onTap;

  const _NavArrowButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.ink,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: enabled
                    ? sub.withValues(alpha: 0.25)
                    : sub.withValues(alpha: 0.1),
                width: 0.8,
              ),
            ),
            child: Icon(
              icon,
              size: 15,
              color: enabled ? ink : sub.withValues(alpha: 0.25),
            ),
          ),
        ),
      ),
    );
  }
}

class _TasbeehCounterButton extends StatefulWidget {
  final int count;
  final int target;
  final Color accent;
  final Color ink;
  final Color sub;
  final bool isLight;
  final bool isAr;
  final VoidCallback onTap;

  const _TasbeehCounterButton({
    required this.count,
    required this.target,
    required this.accent,
    required this.ink,
    required this.sub,
    required this.isLight,
    required this.isAr,
    required this.onTap,
  });

  @override
  State<_TasbeehCounterButton> createState() => _TasbeehCounterButtonState();
}

class _TasbeehCounterButtonState extends State<_TasbeehCounterButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.count >= widget.target;
    final progress = widget.target > 0
        ? (widget.count / widget.target).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: SizedBox(
          width: 86,
          height: 86,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer track & smooth progress arc
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                builder: (context, val, _) {
                  return SizedBox(
                    width: 86,
                    height: 86,
                    child: CircularProgressIndicator(
                      value: val,
                      strokeWidth: 4.2,
                      strokeCap: StrokeCap.round,
                      backgroundColor: widget.isLight
                          ? const Color(0xFFE4E4E8)
                          : const Color(0xFF26262C),
                      valueColor: AlwaysStoppedAnimation(
                        isCompleted ? const Color(0xFF34C759) : widget.accent,
                      ),
                    ),
                  );
                },
              ),
              // Inner tactile circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? const Color(0xFF34C759).withValues(alpha: widget.isLight ? 0.12 : 0.18)
                      : widget.accent.withValues(alpha: widget.isLight ? 0.08 : 0.14),
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF34C759).withValues(alpha: 0.35)
                        : widget.accent.withValues(alpha: 0.22),
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: isCompleted
                        ? Column(
                            key: const ValueKey('done'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_rounded,
                                size: 24,
                                color: Color(0xFF34C759),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                widget.isAr ? 'مكتمل' : 'Done',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF34C759),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            key: ValueKey('counting_${widget.count}'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${widget.count}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: widget.ink,
                                  height: 1.1,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                              Text(
                                '/${widget.target}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: widget.sub,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
