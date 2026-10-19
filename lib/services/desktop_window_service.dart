import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

class DesktopWindowService extends ChangeNotifier with WindowListener, TrayListener {
  static final DesktopWindowService instance = DesktopWindowService._();
  DesktopWindowService._();

  bool _initialized = false;
  bool _startAtStartup = false;
  bool _closeToTray = true;

  VoidCallback? onPlayPauseToggle;
  VoidCallback? onNextDhikr;

  bool get startAtStartup => _startAtStartup;
  bool get closeToTray => _closeToTray;

  Future<void> init({bool startMinimized = false}) async {
    if (_initialized || kIsWeb || !Platform.isWindows) return;

    try {
      // 1. Initialize Window Manager
      await windowManager.ensureInitialized();
      windowManager.addListener(this);

      const windowOptions = WindowOptions(
        size: Size(1280, 820),
        minimumSize: Size(940, 640),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        title: 'HKQuran',
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.setPreventClose(true);
        if (startMinimized) {
          await windowManager.hide();
        } else {
          await windowManager.show();
          await windowManager.focus();
        }
      });

      // 2. Initialize System Tray
      await _initSystemTray();

      // 3. Initialize Launch At Startup
      await _initLaunchAtStartup();

      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('DesktopWindowService init error: $e');
    }
  }

  Future<void> _initSystemTray() async {
    try {
      trayManager.addListener(this);
      
      // Resolve app icon path reliably across local debug and installed Release
      String? iconPath;
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final candidates = [
        '$exeDir\\app_icon.ico',
        '$exeDir\\data\\flutter_assets\\assets\\logo\\app_icon.ico',
        '$exeDir\\data\\flutter_assets\\assets\\app_icon.ico',
        'assets/logo/app_icon.ico',
        'windows/runner/resources/app_icon.ico',
        'assets/app_icon.ico',
      ];

      for (final p in candidates) {
        if (File(p).existsSync()) {
          iconPath = p;
          break;
        }
      }

      if (iconPath != null) {
        await trayManager.setIcon(iconPath);
      } else {
        await trayManager.setIcon('assets/logo/app_icon.ico');
      }

      final menu = Menu(
        items: [
          MenuItem(
            key: 'show_window',
            label: 'فتح التطبيق / Open HKQuran',
          ),
          MenuItem(
            key: 'check_updates',
            label: 'التحقق من التحديثات / Check for Updates',
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'toggle_play',
            label: 'تشغيل/إيقاف مؤقت / Play/Pause',
          ),
          MenuItem(
            key: 'show_dhikr',
            label: 'إشعار الذكر / Show Dhikr Reminder',
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'exit_app',
            label: 'خروج / Exit',
          ),
        ],
      );
      await trayManager.setContextMenu(menu);
      await trayManager.setToolTip('HKQuran (Quran & Adhkar)');
    } catch (e) {
      debugPrint('System Tray initialization note: $e');
    }
  }

  Future<void> _initLaunchAtStartup() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      launchAtStartup.setup(
        appName: packageInfo.appName.isNotEmpty ? packageInfo.appName : 'HKQuran',
        appPath: Platform.resolvedExecutable,
        args: ['--minimized'],
      );
      _startAtStartup = await launchAtStartup.isEnabled();
      notifyListeners();
    } catch (e) {
      debugPrint('LaunchAtStartup initialization note: $e');
    }
  }

  Future<void> setStartAtStartup(bool enable) async {
    if (kIsWeb || !Platform.isWindows) return;
    try {
      if (enable) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
      _startAtStartup = await launchAtStartup.isEnabled();
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling launch at startup: $e');
    }
  }

  void setCloseToTray(bool value) {
    _closeToTray = value;
    notifyListeners();
  }

  @override
  void onWindowClose() async {
    if (_closeToTray) {
      await windowManager.hide();
    } else {
      await windowManager.destroy();
      exit(0);
    }
  }

  @override
  void onTrayIconMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show_window':
        final isMinimized = await windowManager.isMinimized();
        if (isMinimized) {
          await windowManager.restore();
        }
        await windowManager.show();
        await windowManager.focus();
        break;
      case 'check_updates':
        try {
          await launchUrl(
            Uri.parse('https://github.com/SalahEddineken/HKQuran/releases/latest'),
            mode: LaunchMode.externalApplication,
          );
        } catch (e) {
          debugPrint('Error launching update URL: $e');
        }
        break;
      case 'toggle_play':
        onPlayPauseToggle?.call();
        break;
      case 'show_dhikr':
        onNextDhikr?.call();
        break;
      case 'exit_app':
        await windowManager.destroy();
        exit(0);
    }
  }
}
