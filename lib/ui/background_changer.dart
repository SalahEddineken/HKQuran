import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme/palette.dart';

/// Floating vertical dropdown for selecting backgrounds with instant live preview on hover.
class BackgroundDropdown extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final double topOffset;
  final double endOffset;

  const BackgroundDropdown({
    super.key,
    required this.isOpen,
    required this.onClose,
    this.topOffset = 84,
    this.endOffset = 34,
  });

  @override
  State<BackgroundDropdown> createState() => _BackgroundDropdownState();
}

class _BackgroundDropdownState extends State<BackgroundDropdown> {
  int? _hoveredIndex;

  static const List<int> _displayOrder = [0, 2, 3, 4, 5, 6, 7, 8, 1];

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen) return const SizedBox.shrink();

    final s = AppStateScope.of(context);
    final size = MediaQuery.sizeOf(context);
    final isSmall = size.width < 600 || size.height < 760;
    final cardW = isSmall ? 104.0 : 128.0;
    final cardH = isSmall ? 65.0 : 80.0;
    final maxH = math.min(size.height - widget.topOffset - 30, 640.0);

    return PositionedDirectional(
      top: widget.topOffset,
      end: widget.endOffset,
      child: RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, anim, child) {
            return Transform.translate(
              offset: Offset(0, (1.0 - anim) * -12.0),
              child: Opacity(
                opacity: anim,
                child: child,
              ),
            );
          },
          child: MouseRegion(
            onExit: (_) {
              if (mounted) {
                setState(() => _hoveredIndex = null);
              }
              s.previewWatchface(null);
            },
            child: SizedBox(
              width: cardW,
              height: maxH,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(scrollbars: false),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _displayOrder.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final targetIndex = _displayOrder[index];
                      final wf = kWatchfaces[targetIndex];
                      final isSelected = targetIndex == s.watchface;
                      final isHovered = targetIndex == _hoveredIndex;

                      return _BackgroundCard(
                        watchface: wf,
                        width: cardW,
                        height: cardH,
                        isSelected: isSelected,
                        isHovered: isHovered,
                        onEnter: () {
                          if (mounted) {
                            setState(() => _hoveredIndex = targetIndex);
                          }
                          s.previewWatchface(targetIndex);
                        },
                        onTap: () {
                          HapticFeedback.selectionClick();
                          s.setWatchface(targetIndex);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundCard extends StatelessWidget {
  final Watchface watchface;
  final double width;
  final double height;
  final bool isSelected;
  final bool isHovered;
  final VoidCallback onEnter;
  final VoidCallback onTap;

  const _BackgroundCard({
    required this.watchface,
    required this.width,
    required this.height,
    required this.isSelected,
    required this.isHovered,
    required this.onEnter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(15);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onEnter(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isHovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : (isHovered
                        ? Colors.white.withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.2)),
                width: isSelected ? 2.4 : (isHovered ? 1.8 : 1.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isHovered ? 0.6 : (isSelected ? 0.45 : 0.25),
                  ),
                  blurRadius: isHovered ? 14 : (isSelected ? 10 : 6),
                  offset: Offset(0, isHovered ? 4 : 2),
                ),
                if (isSelected)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildContent(context),
                  // Subtle top-to-bottom edge vignette for cards
                  if (watchface.isImage)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.25),
                          ],
                        ),
                      ),
                    ),
                  // Selected indicator checkmark pill
                  if (isSelected)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: Color(0xFF141416),
                          ),
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

  Widget _buildContent(BuildContext context) {
    if (watchface.isWhite) {
      return Container(
        color: const Color(0xFFF7F7F8),
        child: const Center(
          child: CustomPaint(
            size: Size(32, 32),
            painter: _MiniClockPainter(color: Color(0xFF222226)),
          ),
        ),
      );
    } else if (watchface.isBlack) {
      return Container(
        color: const Color(0xFF121214),
        child: const Center(
          child: CustomPaint(
            size: Size(32, 32),
            painter: _MiniClockPainter(color: Colors.white70),
          ),
        ),
      );
    } else if (watchface.asset != null) {
      return Image.asset(
        watchface.asset!,
        fit: BoxFit.cover,
        cacheWidth: 360,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => Container(
          color: const Color(0xFF222226),
          child: const Icon(Icons.image_not_supported_rounded, size: 20),
        ),
      );
    }
    return const ColoredBox(color: Color(0xFF222226));
  }
}

/// Draws an ultra-clean miniature analog clock face matching the minimal design aesthetic.
class _MiniClockPainter extends CustomPainter {
  final Color color;

  const _MiniClockPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 1.0;

    final circlePaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, circlePaint);

    // Center pivot
    final pivotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 1.4, pivotPaint);

    // Hour hand pointing roughly towards 10 o'clock
    final hourPaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.4;
    final hourAngle = -math.pi * 0.65;
    final hourEnd = center + Offset(
      math.cos(hourAngle) * (radius * 0.52),
      math.sin(hourAngle) * (radius * 0.52),
    );
    canvas.drawLine(center, hourEnd, hourPaint);

    // Minute hand pointing roughly towards 2 o'clock
    final minPaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.1;
    final minAngle = math.pi * 0.05;
    final minEnd = center + Offset(
      math.cos(minAngle) * (radius * 0.78),
      math.sin(minAngle) * (radius * 0.78),
    );
    canvas.drawLine(center, minEnd, minPaint);
  }

  @override
  bool shouldRepaint(_MiniClockPainter oldDelegate) => oldDelegate.color != color;
}
