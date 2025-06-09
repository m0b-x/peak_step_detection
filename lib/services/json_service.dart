import 'dart:convert';
import 'dart:io';
import 'package:external_path/external_path.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:study_step_detection/config/sensor_config.dart';

class JsonService {
  static Future<void> saveJson({
    required String name,
    required String smartphonePosition,
    required String walkingSpeed,
    required double height,
    required double legLength,
    required String gender,
    required List<double> xData,
    required List<double> yData,
    required List<double> zData,
    double? pathLength,
    List<double>? strideLengths,
  }) async {
    final jsonData = {
      'name': name,
      'smartphone_position': smartphonePosition,
      'walking_speed': walkingSpeed,
      if (walkingSpeed == 'preferred' && pathLength != null)
        'path_length': pathLength,
      if (walkingSpeed != 'preferred' && strideLengths != null)
        'stride_lengths': strideLengths,
      'height': height,
      'leg_length': legLength,
      'gender': gender,
      'sampling_frequency': 100,
      'linear_acceleration': {
        'x': xData,
        'y': yData,
        'z': zData,
      }
    };

    try {
      String dirPath;

      if (Platform.isAndroid) {
        final status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          debugPrint('JsonService: Permission missing to write to Downloads');
          return;
        }

        dirPath = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_DOWNLOAD,
        );
      } else {
        dirPath = (await getApplicationDocumentsDirectory()).path;
      }

      final baseName =
          'person_${smartphonePosition}_$walkingSpeed'.toLowerCase();
      final extension = '.json';
      String fileName = '$baseName$extension';
      File file = File('$dirPath/$fileName');

      int counter = 1;
      while (await file.exists()) {
        fileName = '$baseName ($counter)$extension';
        file = File('$dirPath/$fileName');
        counter++;
      }

      await file.writeAsString(jsonEncode(jsonData));
      debugPrint('JsonService: Saved JSON to ${file.path}');
    } catch (e) {
      debugPrint('JsonService: Failed to save JSON - $e');
    }
  }

  static Future<void> convertCsvToJson(
      String csvPath, SensorConfig config) async {
    final file = File(csvPath);
    if (!await file.exists()) {
      debugPrint('JsonService: CSV file does not exist at $csvPath');
      return;
    }

    final lines = await file.readAsLines();
    if (lines.length <= 1) {
      debugPrint('JsonService: CSV file is empty or lacks data');
      return;
    }

    final xData = <double>[];
    final yData = <double>[];
    final zData = <double>[];

    for (var i = 1; i < lines.length; i++) {
      final parts = lines[i].split(',');
      if (parts.length >= 4) {
        try {
          xData.add(double.parse(parts[1]));
          yData.add(double.parse(parts[2]));
          zData.add(double.parse(parts[3]));
        } catch (e) {
          debugPrint(
              'JsonService: Skipped line $i due to parse error: ${lines[i]}');
        }
      } else {
        debugPrint(
            'JsonService: Skipped line $i - not enough columns: ${lines[i]}');
      }
    }

    debugPrint('JsonService: Parsed ${xData.length} accelerometer entries');

    await saveJson(
      name: config.name,
      smartphonePosition: config.smartphonePosition.name,
      walkingSpeed: config.walkingSpeed.name,
      height: config.heightMeters,
      legLength: config.legLength,
      gender: config.isMale ? 'male' : 'female',
      xData: xData,
      yData: yData,
      zData: zData,
      pathLength:
          config.walkingSpeed == WalkingSpeed.normal ? config.pathLength : null,
    );
  }
}
