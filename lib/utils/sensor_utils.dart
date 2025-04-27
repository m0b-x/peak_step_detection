import 'package:study_step_detection/utils/circular_buffer.dart';

class SensorUtils {
  static double vectorNormSquared(num x, num y, num z) =>
      (x * x + y * y + z * z).toDouble();

  static bool isFinite(double v) => v.isFinite && v < double.maxFinite;

  static void pushWindow(CircularBuffer<double> b, double v) => b.add(v);

  static void pushGraph(CircularBuffer<double> buf, double v) => buf.add(v);

  static double sanitizePos(double v) => v <= 0 ? 1.0 : v;

  static bool isRising(Iterable<double> v) {
    final it = v.iterator;
    if (!it.moveNext()) return false;

    double prev = it.current;
    while (it.moveNext()) {
      if (it.current < prev) return false;
      prev = it.current;
    }
    return true;
  }

  static bool isFalling(Iterable<double> v) {
    final it = v.iterator;
    if (!it.moveNext()) return false;

    double prev = it.current;
    while (it.moveNext()) {
      if (it.current > prev) return false;
      prev = it.current;
    }
    return true;
  }
}
