import 'package:flutter/material.dart';

class GraphPainter extends CustomPainter {
  final List<double> points;
  final Color color;

  GraphPainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    const double leftPadding = 45;
    final graphWidth = size.width - leftPadding;

    final Paint gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    final Paint axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;

    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textAlign: TextAlign.right,
      textDirection: TextDirection.ltr,
    );

    final double dx = graphWidth / (points.length - 1);
    final double maxVal =
        points.map((e) => e.abs()).reduce((a, b) => a > b ? a : b);
    final yScale = maxVal == 0 ? 1 : maxVal;

    const int gridLines = 5;
    for (int i = 0; i <= gridLines; i++) {
      double y = size.height * i / gridLines;
      canvas.drawLine(Offset(leftPadding, y), Offset(size.width, y), gridPaint);

      // Y-axis label
      final double value = (0.5 - i / gridLines) * 2 * yScale;
      textPainter.text = TextSpan(
        text: value.toStringAsFixed(2),
        style: const TextStyle(color: Colors.black87, fontSize: 12),
      );
      textPainter.layout(minWidth: 0, maxWidth: leftPadding - 4);
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    // Draw central horizontal X-axis
    final midY = size.height / 2;
    canvas.drawLine(
        Offset(leftPadding, midY), Offset(size.width, midY), axisPaint);

    // Y-axis label
    textPainter.text = const TextSpan(
      text: 'Y',
      style: TextStyle(
        color: Colors.grey,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(8, 4));

    // X-axis label
    textPainter.text = const TextSpan(
      text: 'Time →',
      style: TextStyle(color: Colors.grey, fontSize: 12),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - 55, midY + 4));

    // Draw graph path
    final Path path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = leftPadding + i * dx;
      final y = size.height * (0.5 - points[i] / yScale / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(GraphPainter old) =>
      old.points != points || old.color != color;
}
