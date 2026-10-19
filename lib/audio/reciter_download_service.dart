import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../data/models.dart';

class ReciterDownloadProgress {
  final int reciterId;
  final int currentSurah;
  final int totalSurahs;
  final double currentSurahProgress;
  final bool isDownloadingAll;

  const ReciterDownloadProgress({
    required this.reciterId,
    required this.currentSurah,
    required this.totalSurahs,
    required this.currentSurahProgress,
    required this.isDownloadingAll,
  });

  double get overallProgress {
    if (totalSurahs == 0) return 0.0;
    return (currentSurah - 1 + currentSurahProgress) / totalSurahs;
  }
}

class ReciterDownloadService extends ChangeNotifier {
  static final ReciterDownloadService instance = ReciterDownloadService._();
  ReciterDownloadService._();

  String? _baseStoragePath;
  bool _initialized = false;

  final Set<String> _downloadingKeys = {};
  final Map<int, bool> _downloadingAllMap = {};
  final Map<int, double> _surahProgressMap = {};
  http.Client? _activeClient;
  bool _cancelRequested = false;

  bool isDownloading(int reciterId, int chapter) =>
      _downloadingKeys.contains('$reciterId:$chapter');

  bool isDownloadingAll(int reciterId) =>
      _downloadingAllMap[reciterId] == true;

  double getSurahProgress(int reciterId, int chapter) =>
      _surahProgressMap[chapter] ?? 0.0;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    try {
      final docs = await getApplicationDocumentsDirectory();
      _baseStoragePath = '${docs.path}/HKQuranAudio';
      final dir = Directory(_baseStoragePath!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _initialized = true;
    } catch (e) {
      debugPrint('ReciterDownloadService init error: $e');
    }
  }

  String? _getSurahFilePath(int reciterId, int chapter) {
    if (_baseStoragePath == null) return null;
    return '$_baseStoragePath/reciter_$reciterId/$chapter.mp3';
  }

  bool isSurahDownloaded(int reciterId, int chapter) {
    if (kIsWeb || _baseStoragePath == null) return false;
    final path = _getSurahFilePath(reciterId, chapter);
    if (path == null) return false;
    final file = File(path);
    return file.existsSync() && file.lengthSync() > 1024;
  }

  String? getDownloadedPath(int reciterId, int chapter) {
    if (isSurahDownloaded(reciterId, chapter)) {
      return _getSurahFilePath(reciterId, chapter);
    }
    return null;
  }

  int getDownloadedCount(int reciterId) {
    if (kIsWeb || _baseStoragePath == null) return 0;
    final dir = Directory('$_baseStoragePath/reciter_$reciterId');
    if (!dir.existsSync()) return 0;
    int count = 0;
    for (int i = 1; i <= 114; i++) {
      if (isSurahDownloaded(reciterId, i)) count++;
    }
    return count;
  }

  Future<int> getTotalStorageBytes() async {
    if (kIsWeb || _baseStoragePath == null) return 0;
    final dir = Directory(_baseStoragePath!);
    if (!await dir.exists()) return 0;
    int total = 0;
    try {
      await for (final file in dir.list(recursive: true, followLinks: false)) {
        if (file is File) {
          total += await file.length();
        }
      }
    } catch (_) {}
    return total;
  }

  String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<bool> downloadSurah(int reciterId, int chapter) async {
    if (kIsWeb) return false;
    await init();
    if (_baseStoragePath == null) return false;

    final reciter = reciterById(reciterId);
    final url = reciter.remoteAudioUrl(chapter);
    if (url == null) return false;

    final targetPath = _getSurahFilePath(reciterId, chapter)!;
    final targetFile = File(targetPath);
    if (await targetFile.exists() && await targetFile.length() > 1024) {
      return true; // Already downloaded
    }

    final key = '$reciterId:$chapter';
    _downloadingKeys.add(key);
    _surahProgressMap[chapter] = 0.0;
    notifyListeners();

    final dir = Directory('$_baseStoragePath/reciter_$reciterId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final tmpFile = File('$targetPath.tmp');
    _activeClient = http.Client();

    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await _activeClient!.send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed with status: ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      final sink = tmpFile.openWrite();

      await for (final chunk in response.stream) {
        if (_cancelRequested) {
          await sink.close();
          if (await tmpFile.exists()) await tmpFile.delete();
          return false;
        }
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          _surahProgressMap[chapter] = receivedBytes / totalBytes;
          notifyListeners();
        }
      }

      await sink.flush();
      await sink.close();

      if (await tmpFile.length() > 1024) {
        if (await targetFile.exists()) await targetFile.delete();
        await tmpFile.rename(targetPath);
        _surahProgressMap[chapter] = 1.0;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error downloading surah $chapter for reciter $reciterId: $e');
      if (await tmpFile.exists()) {
        try { await tmpFile.delete(); } catch (_) {}
      }
      return false;
    } finally {
      _downloadingKeys.remove(key);
      notifyListeners();
    }
  }

  Future<void> downloadAllSurahs(int reciterId) async {
    if (kIsWeb) return;
    _cancelRequested = false;
    _downloadingAllMap[reciterId] = true;
    notifyListeners();

    try {
      for (int ch = 1; ch <= 114; ch++) {
        if (_cancelRequested) break;
        if (!isSurahDownloaded(reciterId, ch)) {
          await downloadSurah(reciterId, ch);
        }
      }
    } finally {
      _downloadingAllMap[reciterId] = false;
      notifyListeners();
    }
  }

  void cancelDownloads() {
    _cancelRequested = true;
    _activeClient?.close();
    _downloadingKeys.clear();
    _downloadingAllMap.clear();
    notifyListeners();
  }

  Future<void> deleteSurah(int reciterId, int chapter) async {
    final path = _getSurahFilePath(reciterId, chapter);
    if (path != null) {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
        notifyListeners();
      }
    }
  }

  Future<void> deleteReciterAudio(int reciterId) async {
    if (_baseStoragePath == null) return;
    final dir = Directory('$_baseStoragePath/reciter_$reciterId');
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      notifyListeners();
    }
  }
}
