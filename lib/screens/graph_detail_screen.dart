import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/graph_painter.dart';
import '../services/sensor_service.dart';
import 'sensor_screen.dart';

class GraphDetailScreen extends StatelessWidget {
  final String title;
  final ValueListenable<List<double>> notifier;
  final Color color;

  const GraphDetailScreen({
    super.key,
    required this.title,
    required this.notifier,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('$title Graph')),
      body: Consumer<SensorService>(
        builder: (_, svc, __) {
          final data = getSensorData(svc, title);
          final latest = data['latest'];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '$title Readings',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              if (latest != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'X: ${latest.x.toStringAsFixed(4)}  Y: ${latest.y.toStringAsFixed(4)}  Z: ${latest.z.toStringAsFixed(4)}',
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Magnitude: ${data['magnitude'].toStringAsFixed(4)}',
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Average: ${data['average'].toStringAsFixed(4)}',
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Net: ${data['net'].toStringAsFixed(4)}',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              ] else ...[
                const Text('No data')
              ],
              const SizedBox(height: 50),
              SizedBox(
                height: 400,
                child: ValueListenableBuilder<List<double>>(
                  valueListenable: notifier,
                  builder: (_, points, __) => CustomPaint(
                    painter: GraphPainter(points, color),
                    child: Container(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
