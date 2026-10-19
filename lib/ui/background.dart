import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/palette.dart';

/// Full-bleed watchface: solid white/black background or a photo, with an animated
/// crossfade and readability scrim so switching backgrounds is smooth and text
/// is always crystal clear.
///
/// Isolated inside a [RepaintBoundary] so the high-resolution background
/// bitmap never repaints when foreground timers, karaoke words, or sliders update.
class WatchfaceBackground extends StatelessWidget {
  const WatchfaceBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final wf = kWatchfaces[s.effectiveWatchface];
    final solid = wf.isWhite
        ? const Color(0xFFFAFAFA)
        : const Color(0xFF0F0F12);

    final size = MediaQuery.maybeSizeOf(context);
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final cacheW = size != null
        ? (size.width * dpr).clamp(720.0, 1920.0).round()
        : 1920;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base solid color (white for White mode, black for Black and Image modes)
          Positioned.fill(child: ColoredBox(color: solid)),

          // Background photo (only rendered if isImage)
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: wf.isImage && wf.asset != null
                  ? SizedBox.expand(
                      key: ValueKey(wf.asset),
                      child: Image.asset(
                        wf.asset!,
                        fit: BoxFit.cover,
                        cacheWidth: cacheW,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, _, _) =>
                            const SizedBox.shrink(key: ValueKey('plain')),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('plain')),
            ),
          ),

          // Readability gradient scrim over background photos so text is 100% readable
          if (wf.isImage)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: const [
                        Color(0x99000000), // 60% black at top for date/actions
                        Color(0x66000000), // 40% black in center
                        Color(0xA6000000), // 65% black at bottom for transport bar
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

