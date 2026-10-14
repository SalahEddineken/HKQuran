import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/ambient_mixer.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import 'glass.dart';

/// Floating or modal HUD providing direct tactile control over the "Viby Quran" experience:
/// blending the reciter's voice with curated ambient soundscapes (Rain, Rawdah, Coast, etc.)
/// and auto-syncing ambience with Quran playback.
class VibeHudCard extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback? onOpenFullMixer;
  final bool isBottomSheet;

  const VibeHudCard({
    super.key,
    required this.onClose,
    this.onOpenFullMixer,
    this.isBottomSheet = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStateScope.of(context);
    final mixer = s.mixer;
    final mode = s.themeMode;
    final size = MediaQuery.sizeOf(context);
    final isSmall = size.width < 600;
    final activePreset = mixer.activePreset;
    final isMixing = mixer.activeCount > 0 && (!mixer.syncWithReciter || s.player.playing);

    final cardWidth = math.min(size.width * 0.94, 460.0);

    return liquid(
      radius: isBottomSheet ? 28 : 22,
      width: isBottomSheet ? double.infinity : cardWidth,
      padding: EdgeInsets.fromLTRB(
        isSmall ? 14 : 18,
        isBottomSheet ? 12 : 14,
        isSmall ? 14 : 18,
        isSmall ? 14 : 16,
      ),
      tint: mode.brightness == Brightness.light
          ? const Color(0xFFFBFBFC)
          : const Color(0xFF1E1E23),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isBottomSheet) ...[
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: mode.ink.withValues(alpha: 0.18),
                ),
              ),
            ),
          ],

          // ---- Header Row ----
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isMixing
                      ? mode.accent.withValues(alpha: 0.22)
                      : mode.ink.withValues(alpha: 0.08),
                  border: Border.all(
                    color: isMixing
                        ? mode.accent.withValues(alpha: 0.45)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 17,
                  color: isMixing ? mode.accent : mode.inkSoft,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          s.tr('vibeQuran'),
                          style: TextStyle(
                            fontSize: isSmall ? 14.5 : 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: mode.ink,
                          ),
                        ),
                        if (isMixing) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: mode.accent.withValues(alpha: 0.18),
                            ),
                            child: Text(
                              s.tr('vibeActive'),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: mode.accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      mixer.activeCount > 0
                          ? '${activePreset != null ? (s.ar ? activePreset.ar : activePreset.en) : "${mixer.activeCount} ${s.tr('activeSounds')}"} • ${s.tr('blended')}'
                          : s.tr('tapToVibe'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isSmall ? 10.5 : 11.5,
                        color: mode.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (mixer.activeCount > 0) ...[
                GlassButton(
                  size: 32,
                  tooltip: s.tr('muteAll'),
                  icon: Icon(
                    Icons.volume_off_rounded,
                    size: 15,
                    color: mode.inkSoft,
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    mixer.muteAll();
                    s.saveAmbient();
                  },
                ),
                const SizedBox(width: 4),
              ],
              if (onOpenFullMixer != null) ...[
                GlassButton(
                  size: 32,
                  tooltip: s.tr('customizeSounds'),
                  icon: Icon(
                    Icons.tune_rounded,
                    size: 15,
                    color: mode.inkSoft,
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onOpenFullMixer!();
                  },
                ),
                const SizedBox(width: 4),
              ],
              GlassButton(
                size: 32,
                tooltip: s.tr('close'),
                icon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: mode.ink,
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onClose();
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ---- Soundscape Presets Carousel ----
          SizedBox(
            height: 34,
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
                    HapticFeedback.lightImpact();
                    s.applyVibePreset(p, startReciterIfPaused: true);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5.5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      color: isSelected
                          ? mode.accent.withValues(alpha: 0.22)
                          : mode.ink.withValues(alpha: 0.05),
                      border: Border.all(
                        color: isSelected
                            ? mode.accent
                            : mode.ink.withValues(alpha: 0.12),
                        width: isSelected ? 1.2 : 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          p.icon,
                          size: 13,
                          color: isSelected ? mode.accent : mode.inkSoft,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          s.ar ? p.ar : p.en,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? mode.accent : mode.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // ---- Volume Sliders Section ----
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: mode.ink.withValues(alpha: 0.035),
              border: Border.all(
                color: mode.ink.withValues(alpha: 0.07),
                width: 0.8,
              ),
            ),
            child: Column(
              children: [
                // Reciter Volume Row
                _MixSliderRow(
                  icon: Icons.record_voice_over_rounded,
                  label: s.tr('reciterVolume'),
                  value: s.reciterVolume,
                  accent: mode.accent,
                  ink: mode.ink,
                  inkSoft: mode.inkSoft,
                  onChanged: (v) => s.setReciterVolume(v),
                ),
                Divider(
                  height: 12,
                  thickness: 0.6,
                  color: mode.ink.withValues(alpha: 0.08),
                ),
                // Ambient Master Volume Row
                _MixSliderRow(
                  icon: Icons.waves_rounded,
                  label: s.tr('ambientVolume'),
                  value: mixer.master,
                  accent: mode.accent,
                  ink: mode.ink,
                  inkSoft: mode.inkSoft,
                  onChanged: (v) {
                    mixer.setMaster(v);
                    s.saveAmbient();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ---- Auto-Sync with Reciter Toggle ----
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              s.setSyncAmbientWithReciter(!mixer.syncWithReciter);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: mixer.syncWithReciter
                    ? mode.accent.withValues(alpha: 0.09)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sync_rounded,
                    size: 16,
                    color: mixer.syncWithReciter ? mode.accent : mode.inkSoft,
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
                            color: mode.ink,
                          ),
                        ),
                        Text(
                          s.tr('syncWithReciterDesc'),
                          style: TextStyle(
                            fontSize: 9.5,
                            color: mode.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.75,
                    child: Switch.adaptive(
                      value: mixer.syncWithReciter,
                      activeThumbColor: mode.accent,
                      onChanged: (v) {
                        HapticFeedback.lightImpact();
                        s.setSyncAmbientWithReciter(v);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MixSliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color accent;
  final Color ink;
  final Color inkSoft;
  final ValueChanged<double> onChanged;

  const _MixSliderRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.ink,
    required this.inkSoft,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return Row(
      children: [
        Icon(icon, size: 14, color: value > 0 ? accent : inkSoft),
        const SizedBox(width: 7),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 5.5,
                elevation: 1,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 10,
              ),
              activeTrackColor: accent,
              inactiveTrackColor: ink.withValues(alpha: 0.12),
              thumbColor: accent,
              overlayColor: accent.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$pct%',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: inkSoft,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
