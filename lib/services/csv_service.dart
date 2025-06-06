import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as pp;
import 'package:external_path/external_path.dart';
import 'package:permission_handler/permission_handler.dart';

class CsvService {
  final StringBuffer _csvBuffer = StringBuffer();
  IOSink? _fileSink;
  Timer? _csvFlushTimer;
  bool _hasPendingCsvData = false;
  String? _lastCsvPath;

  String? get lastCsvPath => _lastCsvPath;
  bool get isRecording => _fileSink != null;

  Future<bool> startRecording() async {
    if (isRecording) return true;

    _csvBuffer.clear();
    Directory dir;

    if (kIsWeb) {
      dir = await pp.getTemporaryDirectory();
    } else if (Platform.isAndroid) {
      dir = await pp.getDownloadsDirectory() ??
          await pp.getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      dir = await pp.getApplicationDocumentsDirectory();
    } else if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      dir = await pp.getDownloadsDirectory() ??
          await pp.getApplicationDocumentsDirectory();
    } else {
      dir = await pp.getTemporaryDirectory();
    }

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final fileName =
        'acc_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';
    final file = File(p.join(dir.path, fileName));

    try {
      _fileSink = file.openWrite();
    } catch (e) {
      debugPrint('CsvService: Failed to open file: $e');
      return false;
    }

    _csvBuffer.writeln('timestamp,raw_acc_x,raw_acc_y,raw_acc_z,filteredMag');
    _hasPendingCsvData = true;
    _lastCsvPath = file.path;
    _csvFlushTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _flushCsvBuffer(),
    );
    return true;
  }

  Future<bool> stopRecording() async {
    if (!isRecording) return true;

    _csvFlushTimer?.cancel();
    await _flushCsvBuffer();
    await _fileSink?.flush();
    await _fileSink?.close();
    _fileSink = null;

    try {
      if (Platform.isAndroid) {
        final ok = await Permission.manageExternalStorage.status;
        if (!ok.isGranted) {
          debugPrint('CsvService: “All files” permission missing.');
          return false;
        }
      }
      final downloadsPath =
          await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOWNLOAD,
      );

      final newPath = p.join(downloadsPath, p.basename(_lastCsvPath!));
      if (_lastCsvPath != newPath) {
        final newFile = await File(_lastCsvPath!).copy(newPath);
        _lastCsvPath = newFile.path;
      } else {
        debugPrint('CsvService: File already in Downloads folder.');
      }

      debugPrint('CsvService: File saved to Downloads: $_lastCsvPath');
      return true;
    } catch (e) {
      debugPrint('CsvService: Failed to move file to Downloads: $e');
      return false;
    }
  }

  void addCsvRow(String row) {
    if (!isRecording) return;
    _csvBuffer.writeln(row);
    _hasPendingCsvData = true;
  }

  Future<void> _flushCsvBuffer() async {
    if (_fileSink == null || !_hasPendingCsvData) return;
    _fileSink!.write(_csvBuffer.toString());
    _csvBuffer.clear();
    _hasPendingCsvData = false;
  }

  Future<void> dispose() async {
    _csvFlushTimer?.cancel();
    await _fileSink?.flush();
    await _fileSink?.close();
  }
}
