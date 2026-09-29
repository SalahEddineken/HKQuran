import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AmbientChannel {
  final String id;
  final String asset;
  final String en;
  final String ar;
  final IconData icon;
  double volume;
  bool on;
  final AudioPlayer player = AudioPlayer();
  AmbientChannel({
    required this.id,
    required this.asset,
    required this.en,
    required this.ar,
    required this.icon,
    this.volume = 0.7,
    this.on = false,
  });
}

/// A small mixer: five bundled nature loops that play simultaneously, each
/// with its own level, plus a master fader. Levels ramp over ~300 ms so
/// nothing ever clicks.
///
/// Robustness details:
/// * Each channel keeps a [_loading] future so concurrent toggles never
///   double-load the asset, and a failed load is retried on the next toggle.
/// * LoopMode.one keeps the loop seamless, but if the player ever reaches
///   the end anyway (web autoplay quirks, codec hiccup) the completion
///   stream restarts it as a safety net.
/// * Every state change ends in [notifyListeners] so the panel UI, sliders
///   and persisted state always stay in sync.
class AmbientMixer extends ChangeNotifier {
  AmbientMixer() {
    for (final c in channels) {
      c.player.setLoopMode(LoopMode.one);
      c.player.setVolume(0);
      // Loop is the normal path; this only fires if playback ends anyway.
      c.player.playerStateStream.listen((state) {
        if (c.on &&
            state.processingState == ProcessingState.completed &&
            !c.player.playing) {
          c.player.play();
        }
      });
    }
  }

  final List<AmbientChannel> channels = [
    AmbientChannel(
      id: 'rain',
      asset: 'assets/ambient/rain.wav',
      en: 'Rain',
      ar: 'مطر',
      icon: Icons.water_rounded,
    ),
    AmbientChannel(
      id: 'fire',
      asset: 'assets/ambient/fire.wav',
      en: 'Fireplace',
      ar: 'موقد نار',
      icon: Icons.local_fire_department_rounded,
    ),
    AmbientChannel(
      id: 'ocean',
      asset: 'assets/ambient/ocean.wav',
      en: 'Ocean',
      ar: 'محيط',
      icon: Icons.sailing_rounded,
    ),
    AmbientChannel(
      id: 'wind',
      asset: 'assets/ambient/wind.wav',
      en: 'Wind',
      ar: 'رياح',
      icon: Icons.air_rounded,
    ),
    AmbientChannel(
      id: 'night',
      asset: 'assets/ambient/night.wav',
      en: 'Night',
      ar: 'ليل',
      icon: Icons.dark_mode_rounded,
    ),
  ];

  double master = 0.8;
  final Map<String, double> _applied = {};
  final Map<String, Timer> _ramps = {};
  final Map<String, Future<void>> _loading = {};

  double effective(int i) {
    final c = channels[i];
    return c.on ? c.volume * master : 0.0;
  }

  bool get anyOn => channels.any((c) => c.on);

  void setVolume(int i, double v) {
    channels[i].volume = v.clamp(0, 1).toDouble();
    _ramp(channels[i], effective(i));
    notifyListeners();
  }

  void toggle(int i) {
    final c = channels[i];
    c.on = !c.on;
    if (c.on) {
      // Turning on a muted channel should actually be audible.
      if (c.volume <= 0) c.volume = 0.7;
      _ensureLoaded(c).then((_) {
        if (c.on && !c.player.playing) c.player.play();
      });
    }
    _ramp(c, effective(i));
    notifyListeners();
  }

  void setMaster(double v) {
    master = v.clamp(0, 1).toDouble();
    for (var i = 0; i < channels.length; i++) {
      _ramp(channels[i], effective(i));
    }
    notifyListeners();
  }

  /// Restore persisted mixer state (levels, toggles, master).
  void restore(List<double> volumes, List<bool> ons, double savedMaster) {
    master = savedMaster.clamp(0, 1).toDouble();
    for (var i = 0; i < channels.length; i++) {
      final c = channels[i];
      if (i < volumes.length) c.volume = volumes[i].clamp(0, 1).toDouble();
      c.on = i < ons.length ? ons[i] : false;
      if (c.on) {
        _ensureLoaded(c).then((_) {
          if (c.on && !c.player.playing) c.player.play();
        });
      }
      _ramp(c, effective(i), instant: true);
    }
    notifyListeners();
  }

  /// Load the loop asset once per channel; failures are cleared so the next
  /// toggle retries. Resolves even on failure so callers can proceed.
  Future<void> _ensureLoaded(AmbientChannel c) {
    final existing = _loading[c.id];
    if (existing != null) return existing;
    if (c.player.processingState != ProcessingState.idle) {
      return Future.value();
    }
    final f = c.player.setAsset(c.asset).then((_) {
      _loading.remove(c.id);
    }).catchError((Object e) {
      _loading.remove(c.id);
      // One failed loop must not break the mixer; drop to silent.
      c.on = false;
      _applied[c.id] = 0;
      c.player.setVolume(0);
    });
    _loading[c.id] = f;
    return f;
  }

  void _ramp(AmbientChannel c, double target, {bool instant = false}) {
    final t = target.clamp(0, 1).toDouble();
    _ramps[c.id]?.cancel();
    final from = _applied[c.id] ?? 0;
    if (instant || (t - from).abs() < 0.005) {
      _applied[c.id] = t;
      c.player.setVolume(t);
      return;
    }
    const steps = 20;
    var step = 0;
    _ramps[c.id] = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      step++;
      final v = (from + (t - from) * (step / steps)).clamp(0, 1).toDouble();
      _applied[c.id] = v;
      c.player.setVolume(v);
      if (step >= steps) {
        timer.cancel();
        _ramps.remove(c.id);
      }
    });
  }

  @override
  void dispose() {
    for (final t in _ramps.values) {
      t.cancel();
    }
    for (final c in channels) {
      c.player.dispose();
    }
    super.dispose();
  }
}
