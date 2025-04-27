import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/raw_accelerometer_sample.dart';
import '../widgets/raw_acc_graph_painter.dart';

class RawGraphDetailScreen extends StatelessWidget {
  final String title;
  final ValueListenable<List<RawAccelerometerSample>> samplesNotifier;
  final Color color;

  const RawGraphDetailScreen({
    super.key,
    required this.title,
    required this.samplesNotifier,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$title (Raw Data)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder<List<RawAccelerometerSample>>(
          valueListenable: samplesNotifier,
          builder: (_, samples, __) {
            final latest = samples.isNotEmpty ? samples.last : null;

            return ListView(
              children: [
                if (latest != null) ...[
                  const Text(
                    'Latest Raw Values',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20, // Larger font
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'X: ${latest.x.toStringAsFixed(4)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24, // Bigger number
                      fontWeight: FontWeight.w600,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Y: ${latest.y.toStringAsFixed(4)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Z: ${latest.z.toStringAsFixed(4)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'No data yet',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 400,
                  child: CustomPaint(
                    painter: RawAccGraphPainter(samples, color),
                    child: Container(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
