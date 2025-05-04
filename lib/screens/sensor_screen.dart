import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:study_step_detection/config/graph_visibility_config.dart';
import 'package:study_step_detection/screens/raw_graph_detail_screen.dart';
import 'package:study_step_detection/services/csv_service.dart';
import 'package:study_step_detection/utils/raw_accelerometer_sample.dart';
import '../services/sensor_service.dart';
import '../widgets/graph_painter.dart';
import '../widgets/raw_acc_graph_painter.dart';
import 'graph_detail_screen.dart';
import 'settings_screen.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  @override
  void initState() {
    super.initState();
    _requestStoragePermission();
  }

  Future<void> _requestStoragePermission() async {
    if (!await _needsManageStoragePermission()) return;

    final status = await Permission.manageExternalStorage.request();

    if (!mounted) return;

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage permission is required to save recordings.'),
        ),
      );
    }
  }

  Future<bool> _needsManageStoragePermission() async {
    return Platform.isAndroid &&
        (await Permission.manageExternalStorage.status).isDenied;
  }

  @override
  Widget build(BuildContext context) {
    final visibility = context.watch<GraphVisibilityConfig>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step Counter',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<SensorService>(
        builder: (context, svc, _) {
          if (svc.isWarmingUp.value) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Stabilizing Filters...',
                      style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _bigNumber('Steps', svc.stepCount.toString()),
              const SizedBox(height: 12),
              _bigNumber('Distance (m)', svc.distance.toStringAsFixed(2)),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _graphToggleColumn(
                        'Filtered Accel',
                        visibility.showAccelerometer,
                        (v) =>
                            setState(() => visibility.showAccelerometer = v)),
                    _graphToggleColumn(
                        'Raw Accel',
                        visibility.showRawAccelerometer,
                        (v) => setState(
                            () => visibility.showRawAccelerometer = v)),
                    _graphToggleColumn('Gyroscope', visibility.showGyroscope,
                        (v) => setState(() => visibility.showGyroscope = v)),
                    _graphToggleColumn(
                        'Magnetometer',
                        visibility.showMagnetometer,
                        (v) => setState(() => visibility.showMagnetometer = v)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (visibility.showAccelerometer)
                _buildSensorSection(
                  context,
                  svc,
                  'Accelerometer',
                  Colors.blue,
                  threshold: svc.currentConfig.accThreshold /
                      svc.currentConfig.accScale,
                ),
              if (visibility.showRawAccelerometer)
                _buildRawAccSection(
                    context, svc, 'Raw Accelerometer', Colors.blue),
              if (visibility.showGyroscope)
                _buildSensorSection(
                  context,
                  svc,
                  'Gyroscope',
                  Colors.green,
                  threshold: svc.currentConfig.gyroThreshold /
                      svc.currentConfig.gyroScale,
                ),
              if (visibility.showMagnetometer)
                _buildSensorSection(context, svc, 'Magnetometer', Colors.red),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                      onPressed: svc.resetSteps,
                      child: const Text('Reset steps')),
                  OutlinedButton(
                      onPressed: svc.resetGraphs,
                      child: const Text('Clear graphs')),
                ],
              ),
              const SizedBox(height: 36),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<SensorService>(
        builder: (context, svc, _) {
          return BottomAppBar(
            shape: const CircularNotchedRectangle(),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    Expanded(
                      child: Tooltip(
                        message: svc.isWarmingUp.value
                            ? 'Please wait, filters are still warming up'
                            : svc.isTracking.value
                                ? 'Stop tracking'
                                : 'Start tracking',
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: svc.isWarmingUp.value
                                ? Colors.grey
                                : svc.isTracking.value
                                    ? Colors.redAccent
                                    : Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: svc.isTracking.value
                                ? const Icon(Icons.power_settings_new,
                                    key: ValueKey('on'))
                                : const Icon(Icons.play_arrow,
                                    key: ValueKey('off')),
                          ),
                          label: Text(svc.isTracking.value
                              ? 'Stop Tracking'
                              : 'Start Tracking'),
                          onPressed:
                              svc.isWarmingUp.value ? null : svc.toggleTracking,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Tooltip(
                        message: svc.isWarmingUp.value
                            ? 'Please wait, filters are still warming up'
                            : svc.isRecording.value
                                ? 'Stop recording'
                                : 'Start recording',
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: svc.isWarmingUp.value
                                ? Colors.grey
                                : svc.isRecording.value
                                    ? Colors.red
                                    : Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          icon: Icon(
                            svc.isRecording.value
                                ? Icons.stop
                                : Icons.fiber_manual_record,
                          ),
                          label: Text(svc.isRecording.value
                              ? 'Stop Recording'
                              : 'Start Recording'),
                          onPressed: svc.isWarmingUp.value
                              ? null
                              : () async {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  final csvService = context.read<CsvService>();

                                  if (svc.isRecording.value) {
                                    final ok = await svc.stopRecording();
                                    if (!context.mounted) return;

                                    if (!ok) {
                                      messenger.showSnackBar(const SnackBar(
                                          content: Text(
                                              'Could not stop & save file')));
                                      return;
                                    }

                                    final name = p
                                        .basename(csvService.lastCsvPath ?? '');
                                    messenger
                                      ..clearSnackBars()
                                      ..showSnackBar(
                                        SnackBar(
                                          content: Text('Saved $name'),
                                          action: SnackBarAction(
                                            label: 'Open',
                                            onPressed: () {
                                              _openCsvFileSafely(context,
                                                  csvService.lastCsvPath);
                                            },
                                          ),
                                        ),
                                      );
                                  } else {
                                    final ok = await svc.startRecording();
                                    if (!context.mounted) return;

                                    if (!ok) {
                                      messenger.showSnackBar(const SnackBar(
                                          content: Text(
                                              'Recording could not start')));
                                      return;
                                    }

                                    messenger
                                      ..clearSnackBars()
                                      ..showSnackBar(
                                        const SnackBar(
                                            content: Text('Recording started')),
                                      );
                                  }
                                },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _bigNumber(String label, String value) => Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 16)),
        ],
      );
  Widget _graphToggleColumn(
      String label, bool value, Function(bool) onChanged) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Checkbox(
          value: value,
          onChanged: (v) => onChanged(v ?? false),
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          splashRadius: 16,
        ),
      ],
    );
  }

  Widget _buildSensorSection(
    BuildContext context,
    SensorService svc,
    String type,
    Color color, {
    double? threshold,
  }) {
    final data = getSensorData(svc, type);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GraphDetailScreen(
              title: type,
              notifier: data['series'],
              color: color,
            ),
          ),
        );
      },
      child: _SensorCard(
        title: type,
        notifier: data['series'] as ValueListenable<List<double>>,
        color: color,
        threshold: threshold,
        detailBuilder: () => _sensorDetail(
          title: type,
          latest: data['latest'],
          magnitude: data['magnitude'] as double,
          average: data['average'] as double,
          net: data['net'] as double,
          extra: data['extra'] as String?,
        ),
      ),
    );
  }
}

Widget _buildRawAccSection(
    BuildContext context, SensorService svc, String title, Color color) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RawGraphDetailScreen(
            title: title,
            samplesNotifier: svc.rawAccSeries,
            color: color,
          ),
        ),
      );
    },
    child: Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: ValueListenableBuilder<List<RawAccelerometerSample>>(
                valueListenable: svc.rawAccSeries,
                builder: (_, samples, __) {
                  return CustomPaint(
                    painter: RawAccGraphPainter(samples, color),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Map<String, dynamic> getSensorData(SensorService svc, String type) {
  switch (type) {
    case 'Accelerometer':
      return {
        'series': svc.accSeries,
        'latest': svc.latestAcc,
        'magnitude': svc.accMagnitude,
        'average': svc.accAvgMagnitude,
        'net': svc.accNetMagnitude,
        'extra': 'Filtered: ${svc.filteredAcc.toStringAsFixed(4)}',
      };
    case 'Gyroscope':
      return {
        'series': svc.gyroSeries,
        'latest': svc.latestGyro,
        'magnitude': svc.gyroMagnitude,
        'average': svc.gyroAvgMagnitude,
        'net': svc.gyroNetMagnitude,
        'extra': 'Abs(Net): ${svc.gyroAbsNet.toStringAsFixed(4)}',
      };
    case 'Magnetometer':
      return {
        'series': svc.magSeries,
        'latest': svc.latestMag,
        'magnitude': svc.magMagnitude,
        'average': svc.magAvgMagnitude,
        'net': svc.magNetMagnitude,
        'extra': 'Avg Only: ${svc.magAvgMagnitude.toStringAsFixed(4)}',
      };
    default:
      return {};
  }
}

Widget _sensorDetail({
  required String title,
  required dynamic latest,
  required double magnitude,
  required double average,
  required double net,
  String? extra,
}) {
  if (latest == null) return const Center(child: Text('No data'));

  return Center(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$title Readings:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text(
            'X: ${latest.x.toStringAsFixed(4)}  Y: ${latest.y.toStringAsFixed(4)}  Z: ${latest.z.toStringAsFixed(4)}'),
        Text('Magnitude: ${magnitude.toStringAsFixed(4)}'),
        Text('Average: ${average.toStringAsFixed(4)}'),
        Text('Net: ${net.toStringAsFixed(4)}'),
        if (extra != null) Text(extra),
      ],
    ),
  );
}

Future<void> _openCsvFileSafely(BuildContext context, String? path) async {
  if (path == null) return;
  final file = File(path);
  final exists = await file.exists();
  if (!context.mounted) return;

  if (!exists) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File does not exist: $path')),
    );
    return;
  }

  final result = await OpenFilex.open(path);
  if (!context.mounted) return;

  if (result.type != ResultType.done) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open file: ${result.message}')),
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.title,
    required this.notifier,
    required this.color,
    required this.detailBuilder,
    this.threshold,
  });

  final String title;
  final ValueListenable<List<double>> notifier;
  final Color color;
  final double? threshold;
  final Widget Function() detailBuilder;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: ValueListenableBuilder<List<double>>(
                valueListenable: notifier,
                builder: (_, data, __) => CustomPaint(
                  painter: GraphPainter(data, color, threshold: threshold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            detailBuilder(),
          ],
        ),
      ),
    );
  }
}
