import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';

class AmbientPreset {
  final String id;
  final String en;
  final String ar;
  final IconData icon;
  final Map<String, double> levels;

  const AmbientPreset({
    required this.id,
    required this.en,
    required this.ar,
    required this.icon,
    required this.levels,
  });
}

const List<AmbientPreset> kAmbientPresets = [
  AmbientPreset(
    id: 'rainstorm',
    en: 'Rainstorm',
    ar: 'عاصفة ماطرة',
    icon: Icons.thunderstorm_rounded,
    levels: {'rain': 0.65, 'thunder': 0.30, 'wind': 0.20},
  ),
  AmbientPreset(
    id: 'rawdah',
    en: 'Rawdah',
    ar: 'الروضة',
    icon: Icons.forest_rounded,
    levels: {'birds': 0.55, 'stream': 0.50, 'wind': 0.20},
  ),
  AmbientPreset(
    id: 'coastal',
    en: 'Coast',
    ar: 'شاطئ',
    icon: Icons.waves_rounded,
    levels: {'ocean': 0.65, 'night': 0.35, 'wind': 0.20},
  ),
  AmbientPreset(
    id: 'sanctuary',
    en: 'Sanctuary',
    ar: 'سكينة',
    icon: Icons.local_fire_department_rounded,
    levels: {'fire': 0.50, 'droplets': 0.45, 'night': 0.25},
  ),
  AmbientPreset(
    id: 'desert',
    en: 'Desert',
    ar: 'صحراء',
    icon: Icons.landscape_rounded,
    levels: {'desert': 0.60, 'fire': 0.30, 'wind': 0.25},
  ),
];

class AmbientChannel {
  final String id;
  final String asset;
  final String en;
  final String ar;
  final IconData icon;
  final String category; // 'water', 'nature', 'sky'
  double volume;
  bool on;
  AudioPlayer? _player;
  bool get hasPlayer => _player != null;
  AudioPlayer get player {
    if (_player == null) {
      final p = AudioPlayer();
      p.setLoopMode(LoopMode.one);
      p.setVolume(0);
      p.playerStateStream.listen((state) {
        if (on &&
            state.processingState == ProcessingState.completed &&
            !p.playing) {
          p.play();
        }
      });
      _player = p;
    }
    return _player!;
  }

  AmbientChannel({
    required this.id,
    required this.asset,
    required this.en,
    required this.ar,
    required this.icon,
    this.category = 'nature',
    this.volume = 0.7,
    this.on = false,
  });
}

/// A ten-channel ambient mixer: nature and atmospheric loops that play
/// simultaneously, each with its own level, plus a master fader and presets.
/// Levels ramp over ~300 ms so nothing ever clicks.
///
/// Robustness details:
/// * Channels lazily instantiate AudioPlayer on demand when activated.
/// * Each channel keeps a [_loading] future so concurrent toggles never
///   double-load the asset, and a failed load is retried on the next toggle.
/// * LoopMode.one keeps the loop seamless, but if the player ever reaches
///   the end anyway (web autoplay quirks, codec hiccup) the completion
///   stream restarts it as a safety net.
/// * Every state change ends in [notifyListeners] so the panel UI, sliders
///   and persisted state always stay in sync.
class AmbientMixer extends ChangeNotifier {
  AmbientMixer();

  final List<AmbientChannel> channels = [
    AmbientChannel(
      id: 'rain',
      asset: 'assets/ambient/rain.mp3',
      en: 'Rain',
      ar: 'مطر',
      icon: Icons.water_rounded,
      category: 'water',
    ),
    AmbientChannel(
      id: 'stream',
      asset: 'assets/ambient/stream.mp3',
      en: 'Stream',
      ar: 'جدول ماء',
      icon: Icons.water_drop_rounded,
      category: 'water',
    ),
    AmbientChannel(
      id: 'ocean',
      asset: 'assets/ambient/ocean.mp3',
      en: 'Ocean',
      ar: 'محيط',
      icon: Icons.waves_rounded,
      category: 'water',
    ),
    AmbientChannel(
      id: 'droplets',
      asset: 'assets/ambient/droplets.mp3',
      en: 'Rain on Glass',
      ar: 'قطرات زجاج',
      icon: Icons.grain_rounded,
      category: 'water',
    ),
    AmbientChannel(
      id: 'birds',
      asset: 'assets/ambient/birds.mp3',
      en: 'Birds',
      ar: 'طيور',
      icon: Icons.flutter_dash_rounded,
      category: 'nature',
    ),
    AmbientChannel(
      id: 'fire',
      asset: 'assets/ambient/fire.mp3',
      en: 'Fireplace',
      ar: 'موقد نار',
      icon: Icons.local_fire_department_rounded,
      category: 'nature',
    ),
    AmbientChannel(
      id: 'wind',
      asset: 'assets/ambient/wind.mp3',
      en: 'Wind',
      ar: 'رياح',
      icon: Icons.air_rounded,
      category: 'sky',
    ),
    AmbientChannel(
      id: 'thunder',
      asset: 'assets/ambient/thunder.mp3',
      en: 'Thunder',
      ar: 'رعد',
      icon: Icons.thunderstorm_rounded,
      category: 'sky',
    ),
    AmbientChannel(
      id: 'night',
      asset: 'assets/ambient/night.mp3',
      en: 'Night',
      ar: 'ليل',
      icon: Icons.dark_mode_rounded,
      category: 'sky',
    ),
    AmbientChannel(
      id: 'desert',
      asset: 'assets/ambient/desert.mp3',
      en: 'Desert Breeze',
      ar: 'نسيم الصحراء',
      icon: Icons.landscape_rounded,
      category: 'nature',
    ),
  ];

  double master = 0.8;
  double? _preMuteMaster;
  final Map<String, double> _applied = {};
  final Map<String, Timer> _ramps = {};
  final Map<String, Future<void>> _loading = {};

  double effective(int i) {
    final c = channels[i];
    return c.on ? (c.volume * master).clamp(0.0, 1.0) : 0.0;
  }

  bool get anyOn => channels.any((c) => c.on);
  int get activeCount => channels.where((c) => c.on).length;

  bool isPresetActive(AmbientPreset preset) {
    if (activeCount != preset.levels.length) return false;
    for (final c in channels) {
      final target = preset.levels[c.id];
      if (target != null && target > 0) {
        if (!c.on) return false;
      } else {
        if (c.on) return false;
      }
    }
    return true;
  }

  void applyPreset(AmbientPreset preset) {
    final alreadyActive = isPresetActive(preset);
    if (alreadyActive) {
      muteAll();
      return;
    }
    for (var i = 0; i < channels.length; i++) {
      final c = channels[i];
      final target = preset.levels[c.id];
      if (target != null && target > 0) {
        c.volume = target;
        c.on = true;
        _ensureLoaded(c).then((_) {
          if (c.on && effective(i) > 0 && c.player.processingState != ProcessingState.idle && !c.player.playing) {
            c.player.play();
          }
        });
      } else {
        c.on = false;
      }
      _ramp(c, effective(i));
    }
    notifyListeners();
  }

  void muteAll() {
    for (var i = 0; i < channels.length; i++) {
      final c = channels[i];
      c.on = false;
      _ramp(c, 0);
    }
    notifyListeners();
  }

  void toggleMasterMute() {
    if (master > 0) {
      _preMuteMaster = master;
      setMaster(0);
    } else {
      setMaster(_preMuteMaster ?? 0.8);
    }
  }

  void setVolume(int i, double v) {
    final c = channels[i];
    c.volume = v.clamp(0, 1).toDouble();
    if (v > 0 && !c.on) {
      c.on = true;
      _ensureLoaded(c).then((_) {
        if (c.on && effective(i) > 0 && c.player.processingState != ProcessingState.idle && !c.player.playing) {
          c.player.play();
        }
      });
    }
    _ramp(c, effective(i));
    notifyListeners();
  }

  void toggle(int i) {
    final c = channels[i];
    c.on = !c.on;
    if (c.on) {
      // Turning on a muted channel should actually be audible.
      if (c.volume <= 0) c.volume = 0.7;
      _ensureLoaded(c).then((_) {
        if (c.on && effective(i) > 0 && c.player.processingState != ProcessingState.idle && !c.player.playing) {
          c.player.play();
        }
      });
    }
    _ramp(c, effective(i));
    notifyListeners();
  }

  void setMaster(double v) {
    master = v.clamp(0, 1).toDouble();
    for (var i = 0; i < channels.length; i++) {
      final c = channels[i];
      if (c.on && master > 0) {
        _ensureLoaded(c).then((_) {
          if (c.on && effective(i) > 0 && c.player.processingState != ProcessingState.idle && !c.player.playing) {
            c.player.play();
          }
        });
      }
      _ramp(c, effective(i));
    }
    notifyListeners();
  }

  /// Restore persisted mixer state (levels, toggles, master).
  void restore(
    List<double> volumes,
    List<bool> ons,
    double savedMaster,
  ) {
    master = savedMaster.clamp(0, 1).toDouble();

    for (var i = 0; i < channels.length; i++) {
      final c = channels[i];
      if (i < volumes.length) c.volume = volumes[i].clamp(0, 1).toDouble();
      c.on = i < ons.length ? ons[i] : false;
      final target = effective(i);
      if (c.on && target > 0) {
        _ensureLoaded(c).then((_) {
          if (c.on && effective(i) > 0 && c.player.processingState != ProcessingState.idle && !c.player.playing) {
            c.player.play();
          }
        });
      }
      _ramp(c, target, instant: true);
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

    final Future<Duration?> loadFuture = kIsWeb
        ? c.player.setAudioSource(
            AudioSource.uri(Uri.parse(c.asset)),
            preload: true,
          )
        : c.player.setAsset(c.asset, preload: true);

    final f = loadFuture.then((_) {
      _loading.remove(c.id);
      final currentVol = _applied[c.id] ?? effective(channels.indexOf(c));
      c.player.setVolume(currentVol);
      if (c.on && currentVol > 0 && !c.player.playing) {
        c.player.play();
      }
    }).catchError((Object e) {
      debugPrint('Ambient load error for ${c.id}: $e');
      _loading.remove(c.id);
      if (!kIsWeb) {
        c.player
            .setAudioSource(AudioSource.uri(Uri.parse(c.asset)), preload: true)
            .then((_) {
          final currentVol = _applied[c.id] ?? effective(channels.indexOf(c));
          c.player.setVolume(currentVol);
          if (c.on && currentVol > 0 && !c.player.playing) {
            c.player.play();
          }
        }).catchError((Object e2) {
          debugPrint('Ambient fallback error for ${c.id}: $e2');
          _applied[c.id] = 0;
          c.player.setVolume(0);
        });
      } else {
        _applied[c.id] = 0;
        c.player.setVolume(0);
      }
    });
    _loading[c.id] = f;
    return f;
  }

  void _ramp(AmbientChannel c, double target, {bool instant = false}) {
    final t = target.clamp(0, 1).toDouble();
    _ramps[c.id]?.cancel();
    if (!c.hasPlayer && t == 0) {
      _applied[c.id] = 0;
      return;
    }
    final from = _applied[c.id] ?? 0;
    if (instant || (t - from).abs() < 0.005) {
      _applied[c.id] = t;
      c.player.setVolume(t);
      if (t == 0 && c.player.playing) {
        c.player.pause();
      } else if (t > 0 && c.player.processingState != ProcessingState.idle && !c.player.playing) {
        c.player.play();
      }
      return;
    }
    const steps = 20;
    var step = 0;
    _ramps[c.id] = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      step++;
      final v = (from + (t - from) * (step / steps)).clamp(0, 1).toDouble();
      _applied[c.id] = v;
      c.player.setVolume(v);
      if (v > 0 && c.player.processingState != ProcessingState.idle && !c.player.playing) {
        c.player.play();
      }
      if (step >= steps) {
        timer.cancel();
        _ramps.remove(c.id);
        if (t == 0 && c.player.playing) {
          c.player.pause();
        }
      }
    });
  }

  @override
  void notifyListeners() {
    try {
      if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (hasListeners) super.notifyListeners();
        });
        return;
      }
    } catch (_) {}
    super.notifyListeners();
  }

  @override
  void dispose() {
    for (final t in _ramps.values) {
      t.cancel();
    }
    _ramps.clear();
    for (final c in channels) {
      if (c.hasPlayer) {
        c.player.dispose();
      }
    }
    super.dispose();
  }
}
