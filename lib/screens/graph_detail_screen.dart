import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/raw_accelerometer_sample.dart'; // Import this!
import '../widgets/graph_painter.dart';
import '../widgets/raw_acc_graph_painter.dart';
import '../services/sensor_service.dart';
import 'sensor_screen.dart';

class GraphDetailScreen extends StatelessWidget {
  final String title;
  final ValueListenable notifier;
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
      appBar: AppBar(
        title: Text(
          '$title Graph',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatusLight(
                      'Peak Detected', svc.peakDetectedNotifier, Colors.green),
                  const SizedBox(width: 16),
                  _buildStatusLightWithFakePeak('End Detected',
                      svc.endDetectedNotifier, svc.fakePeakDetectedNotifier),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 400,
                child: ValueListenableBuilder(
                  valueListenable: notifier,
                  builder: (_, value, __) {
                    if (value is List<double>) {
                      return CustomPaint(
                        painter: GraphPainter(value, color),
                        child: Container(),
                      );
                    } else if (value is List<RawAccelerometerSample>) {
                      return CustomPaint(
                        painter: RawAccGraphPainter(value, color),
                        child: Container(),
                      );
                    } else {
                      return const Center(
                          child: Text('Unsupported graph type'));
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusLight(
      String label, ValueListenable<bool> notifier, Color activeColor) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (_, active, __) => Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: active ? activeColor : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStatusLightWithFakePeak(String label,
      ValueListenable<bool> endNotifier, ValueListenable<bool> fakeNotifier) {
    return ValueListenableBuilder2<bool, bool>(
      first: endNotifier,
      second: fakeNotifier,
      builder: (_, endActive, fakeActive, __) => Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: fakeActive
                  ? Colors.red
                  : endActive
                      ? Colors.green
                      : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext, A, B, Widget?) builder;

  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, firstValue, _) => ValueListenableBuilder<B>(
        valueListenable: second,
        builder: (context, secondValue, __) =>
            builder(context, firstValue, secondValue, null),
      ),
    );
  }
}
