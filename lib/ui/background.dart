import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/palette.dart';

/// Full-bleed watchface: solid theme colour or a photo, with an animated
/// scrim so switching theme never flashes. Photo changes crossfade.
class WatchfaceBackground extends StatelessWidget {
  const WatchfaceBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final wf = kWatchfaces[s.watchface];
    final solid = switch (s.themeMode) {
      AppThemeMode.light => const Color(0xFFEDEDED),
      AppThemeMode.dark => const Color(0xFF111111),
      AppThemeMode.noor => const Color(0xFF063B31),
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: ColoredBox(color: solid)),
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: wf.asset == null
                ? const SizedBox.shrink(key: ValueKey('plain'))
                : SizedBox.expand(
                    key: ValueKey(wf.asset),
                    child: Image.asset(
                      wf.asset!,
                      fit: BoxFit.cover,
                      cacheWidth: 1920,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) =>
                          const SizedBox.shrink(key: ValueKey('plain')),
                    ),
                  ),
          ),
        ),
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            color: s.themeMode.scrim,
          ),
        ),
      ],
    );
  }
}
