import 'package:flutter/material.dart';
import 'dart:math' show max;

import 'package:study_step_detection/utils/raw_accelerometer_sample.dart';

class RawAccGraphPainter extends CustomPainter {
  RawAccGraphPainter(this.samples, this.color);

  final List<RawAccelerometerSample>
      samples; // [RawAccelerometerSample(x, y, z), ...]
  final Color color;

  static final _cache = <int, List<TextPainter>>{};

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    const leftPad = 45.0;
    final graphW = size.width - leftPad;
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;
    final axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0;

    final paints = [
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
      Paint()
        ..color = Colors.green
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
      Paint()
        ..color = Colors.red
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    ];

    final maxVal = samples.fold<double>(
      0.0,
      (m, s) => max(m, max(max(s.x.abs(), s.y.abs()), s.z.abs())),
    );
    final yScale = maxVal == 0 ? 1 : maxVal;

    /* grid + labels */
    const gridLines = 5;
    final cacheKey = (yScale * 100).round();
    final labels = _cache.putIfAbsent(cacheKey, () {
      const style = TextStyle(color: Colors.black87, fontSize: 12);
      return List.generate(gridLines + 1, (i) {
        final value = (0.5 - i / gridLines) * 2 * yScale;
        final tp = TextPainter(
          text: TextSpan(text: value.toStringAsFixed(2), style: style),
          textAlign: TextAlign.right,
          textDirection: TextDirection.ltr,
        )..layout(minWidth: 0, maxWidth: leftPad - 4);
        return tp;
      });
    });

    for (var i = 0; i <= gridLines; i++) {
      final y = size.height * i / gridLines;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      labels[i].paint(canvas, Offset(0, y - labels[i].height / 2));
    }

    /* axes */
    final midY = size.height / 2;
    canvas.drawLine(Offset(leftPad, midY), Offset(size.width, midY), axisPaint);

    _drawStaticLabel(
      canvas,
      'Y',
      const Offset(8, 4),
      const TextStyle(
          color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
    );
    _drawStaticLabel(
      canvas,
      'Time →',
      Offset(size.width - 55, midY + 4),
      const TextStyle(color: Colors.grey, fontSize: 12),
    );

    /* lines: x, y, z */
    final dx = graphW / (samples.length - 1);

    for (int axis = 0; axis < 3; axis++) {
      final path = Path();
      for (int i = 0; i < samples.length; i++) {
        final sample = samples[i];
        final x = leftPad + i * dx;
        final value = axis == 0 ? sample.x : (axis == 1 ? sample.y : sample.z);
        final y = size.height * (0.5 - value / yScale / 2);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paints[axis]);
    }
  }

  void _drawStaticLabel(Canvas c, String txt, Offset pos, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: txt, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, pos);
  }

  @override
  bool shouldRepaint(covariant RawAccGraphPainter old) =>
      old.samples != samples || old.color != color;
}
