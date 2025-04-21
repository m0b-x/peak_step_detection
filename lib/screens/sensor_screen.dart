import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../services/sensor_service.dart';
import 'settings_screen.dart';
import '../widgets/graph_painter.dart';
import 'graph_detail_screen.dart';

class SensorScreen extends StatelessWidget {
  const SensorScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              _buildSensorSection(context, svc, 'Accelerometer', Colors.blue),
              const SizedBox(height: 16),
              _buildSensorSection(context, svc, 'Gyroscope', Colors.green),
              const SizedBox(height: 16),
              _buildSensorSection(context, svc, 'Magnetometer', Colors.red),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.save_alt),
                label: const Text("Save All Graphs as CSV"),
                onPressed: () async {
                  final results = await _saveAllGraphsToCsv({
                    'Accelerometer': svc.accSeries.value,
                    'Gyroscope': svc.gyroSeries.value,
                    'Magnetometer': svc.magSeries.value,
                  });

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              results ? 'Saved all graphs' : 'Save failed')),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
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

  Widget _buildSensorSection(
      BuildContext context, SensorService svc, String type, Color color) {
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
        detailBuilder: () => _sensorDetail(
          title: type,
          latest: data['latest'],
          magnitude: data['magnitude'] as double,
          average: data['average'] as double,
          net: data['net'] as double,
        ),
      ),
    );
  }
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
      };
    case 'Gyroscope':
      return {
        'series': svc.gyroSeries,
        'latest': svc.latestGyro,
        'magnitude': svc.gyroMagnitude,
        'average': svc.gyroAvgMagnitude,
        'net': svc.gyroNetMagnitude,
      };
    case 'Magnetometer':
      return {
        'series': svc.magSeries,
        'latest': svc.latestMag,
        'magnitude': svc.magMagnitude,
        'average': svc.magAvgMagnitude,
        'net': svc.magNetMagnitude,
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
      ],
    ),
  );
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.title,
    required this.notifier,
    required this.color,
    required this.detailBuilder,
  });

  final String title;
  final ValueListenable<List<double>> notifier;
  final Color color;
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
                  painter: GraphPainter(data, color),
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

Future<bool> _saveAllGraphsToCsv(Map<String, List<double>> dataMap) async {
  try {
    final dir = await getApplicationDocumentsDirectory();

    for (final entry in dataMap.entries) {
      final file = File('${dir.path}/${entry.key.toLowerCase()}.csv');
      final csv = StringBuffer('Index,Value\n');
      for (int i = 0; i < entry.value.length; i++) {
        csv.writeln('$i,${entry.value[i].toStringAsFixed(6)}');
      }
      await file.writeAsString(csv.toString());
    }

    return true;
  } catch (e) {
    debugPrint('CSV export failed: $e');
    return false;
  }
}
