import 'package:flutter/material.dart';
import 'dart:math' show max;

class GraphPainter extends CustomPainter {
  GraphPainter(this.points, this.color, {this.threshold});

  final List<double> points;
  final Color color;
  final double? threshold;

  /* simple cache: yScale*100 → list of 6 label painters */
  static final _cache = <int, List<TextPainter>>{};

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    const leftPad = 45.0;
    final graphW = size.width - leftPad;

    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.4)
      ..strokeWidth = .5;
    final axisPaint = Paint()..color = Colors.grey;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dx = graphW / (points.length - 1);
    final maxVal = points.fold<double>(0, (m, e) => max(m, e.abs()));
    final yScale = maxVal == 0 ? 1 : maxVal;

    if (threshold != null && threshold!.abs() <= yScale) {
      final thresholdY = size.height * (0.5 - threshold! / yScale / 2);
      final thresholdPaint = Paint()
        ..color = Colors.black87
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(leftPad, thresholdY),
        Offset(size.width, thresholdY),
        thresholdPaint,
      );
    }

    /* ───── grid & labels ───── */
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
            color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold));
    _drawStaticLabel(canvas, 'Time →', Offset(size.width - 55, midY + 4),
        const TextStyle(color: Colors.grey, fontSize: 12));

    /* line path */
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = leftPad + i * dx;
      final y = size.height * (0.5 - points[i] / yScale / 2);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, linePaint);
  }

  void _drawStaticLabel(Canvas c, String txt, Offset pos, TextStyle style) {
    final tp = TextPainter(
        text: TextSpan(text: txt, style: style),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(c, pos);
  }

  @override
  bool shouldRepaint(GraphPainter old) =>
      old.points != points || old.color != color || old.threshold != threshold;
}
