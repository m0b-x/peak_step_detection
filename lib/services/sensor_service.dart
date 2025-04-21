import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:iirjdart/butterworth.dart';
import 'package:simple_kalman/simple_kalman.dart';

import '../config/sensor_config.dart';

class SensorService extends ChangeNotifier {
  SensorService(this._config) {
    _initSensors();
  }

  final ValueNotifier<bool> _isWarmingUp = ValueNotifier(true);
  ValueNotifier<bool> get isWarmingUp => _isWarmingUp;

  AccelerometerEvent? _lastAcc;
  GyroscopeEvent? _lastGyro;
  MagnetometerEvent? _lastMag;

  AccelerometerEvent? get latestAcc => _lastAcc;
  GyroscopeEvent? get latestGyro => _lastGyro;
  MagnetometerEvent? get latestMag => _lastMag;

  double get accMagnitude =>
      _lastAcc == null ? 0 : _vectorNorm(_lastAcc!.x, _lastAcc!.y, _lastAcc!.z);
  double get accAvgMagnitude => _avgAccMag;
  double get accNetMagnitude => accMagnitude - _avgAccMag;

  double get gyroMagnitude => _lastGyro == null
      ? 0
      : _vectorNorm(_lastGyro!.x, _lastGyro!.y, _lastGyro!.z);
  double get gyroAvgMagnitude => _avgGyroMag;
  double get gyroNetMagnitude => gyroMagnitude - _avgGyroMag;

  double get magMagnitude =>
      _lastMag == null ? 0 : _vectorNorm(_lastMag!.x, _lastMag!.y, _lastMag!.z);
  double get magAvgMagnitude => _avgMagMag;
  double get magNetMagnitude => magMagnitude - _avgMagMag;

  double _avgAccMag = 0;
  double _avgGyroMag = 0;
  double _avgMagMag = 0;

  SensorConfig _config;
  SensorConfig get currentConfig => _config;

  final ValueNotifier<List<double>> accSeries = ValueNotifier(<double>[]);
  final ValueNotifier<List<double>> gyroSeries = ValueNotifier(<double>[]);
  final ValueNotifier<List<double>> magSeries = ValueNotifier(<double>[]);

  final List<double> _accelerometerHistory = [];
  final List<double> _gyroHistory = [];
  final List<double> _magnetometerHistory = [];

  int _stepCount = 0;
  double _distance = 0.0;
  int get stepCount => _stepCount;
  double get distance => _distance;

  late Butterworth _lowPass;
  // ignore: unused_field
  final SimpleKalman _kalman = SimpleKalman(
    errorMeasure: 2,
    errorEstimate: 2,
    q: 0.01,
  );

  static const int _maxAvgCount = 3;
  static const int _maxGraphPoints = 100;
  final List<double> _accWinBuffer = [];
  final List<double> _gyroWinBuffer = [];
  final List<double> _magWinBuffer = [];

  static const int _vecLen = 3;
  final List<double> _startVector = [];
  final List<double> _peakVector = [];
  final List<double> _endVector = [];
  bool _peakDetected = false;

  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  Future<void> _initSensors() async {
    _initFilters();

    _isWarmingUp.value = _config.warmUpSensors;

    _subscribeSensors();

    if (_config.warmUpSensors) {
      await Future.delayed(Duration(milliseconds: _config.warmUpDurationMs));
    }

    _isWarmingUp.value = false;
    notifyListeners();
  }

  void _initFilters() {
    final sampleRate = 1000.0 / _config.pollingIntervalMs;
    _lowPass = Butterworth()
      ..lowPass(_config.filterOrder, sampleRate, _config.filterCutoffFreq);
  }

  void _subscribeSensors() {
    final interval = _config.useSystemDefaultInterval
        ? SensorInterval.normalInterval
        : Duration(milliseconds: _config.pollingIntervalMs);

    _accSub = accelerometerEventStream(samplingPeriod: interval)
        .listen(_onAccelerometer);
    _gyroSub =
        gyroscopeEventStream(samplingPeriod: interval).listen(_onGyroscope);
    _magSub = magnetometerEventStream(samplingPeriod: interval)
        .listen(_onMagnetometer);
  }

  @override
  void dispose() {
    _accSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    accSeries.dispose();
    gyroSeries.dispose();
    magSeries.dispose();
    super.dispose();
  }

  void resetSteps() {
    _stepCount = 0;
    _distance = 0.0;
    notifyListeners();
  }

  void resetGraphs() {
    _accelerometerHistory.clear();
    _gyroHistory.clear();
    _magnetometerHistory.clear();

    if (!_isWarmingUp.value) {
      accSeries.value = List.unmodifiable(_accelerometerHistory);
      gyroSeries.value = List.unmodifiable(_gyroHistory);
      magSeries.value = List.unmodifiable(_magnetometerHistory);
    }
  }

  void updateConfig(SensorConfig newConfig) {
    _config = newConfig;
    _accSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    _isWarmingUp.value = true;
    _initSensors();
  }

  void _onAccelerometer(AccelerometerEvent e) {
    _lastAcc = e;
    final mag = _vectorNorm(e.x, e.y, e.z);
    if (!_isFinite(mag)) return;

    _pushWindow(_accWinBuffer, mag);
    final avg = _avgWindow(_accWinBuffer);
    _avgAccMag = avg;
    final net = mag - avg;
    final filtered = _lowPass.filter(net);

    _pushGraph(_accelerometerHistory, _config.accelerometerScale * filtered);

    accSeries.value = List.unmodifiable(_accelerometerHistory);
    _detectStep(filtered);
    notifyListeners();
  }

  void _onGyroscope(GyroscopeEvent e) {
    _lastGyro = e;
    final mag = _vectorNorm(e.x, e.y, e.z);
    _pushWindow(_gyroWinBuffer, mag);
    final avg = _avgWindow(_gyroWinBuffer);
    _avgGyroMag = avg;
    final net = mag - avg;

    _pushGraph(_gyroHistory, _config.gyroScale * net.abs());

    gyroSeries.value = List.unmodifiable(_gyroHistory);
    notifyListeners();
  }

  void _onMagnetometer(MagnetometerEvent e) {
    _lastMag = e;
    final mag = _vectorNorm(e.x, e.y, e.z);
    _pushWindow(_magWinBuffer, mag);
    final avg = _avgWindow(_magWinBuffer);
    _avgMagMag = avg;
    final net = mag - avg;

    _pushGraph(_magnetometerHistory, _config.magScale * net.abs());

    magSeries.value = List.unmodifiable(_magnetometerHistory);
    notifyListeners();
  }

  void _detectStep(double v) {
    _startVector.add(v);
    if (_startVector.length > _vecLen) _startVector.removeAt(0);

    bool rising = true;
    for (int i = 1; i < _startVector.length; i++) {
      if (_startVector[i] <= _startVector[i - 1]) {
        rising = false;
        break;
      }
    }

    if (rising && v > _config.accThreshold) {
      _peakDetected = true;
      _peakVector.add(v);
      if (_peakVector.length > _vecLen) _peakVector.removeAt(0);
    }

    if (_peakDetected) {
      _endVector.add(v);
      if (_endVector.length > _vecLen) _endVector.removeAt(0);

      bool descending = true;
      for (int i = 1; i < _endVector.length; i++) {
        if (_endVector[i] >= _endVector[i - 1]) {
          descending = false;
          break;
        }
      }

      if (descending && _peakVector.isNotEmpty) {
        final maxPeak = _peakVector.reduce(max);
        double stepLen = maxPeak > _config.bigStepThreshold
            ? _config.longStep
            : maxPeak > _config.mediumStepThreshold
                ? _config.mediumStep
                : _config.shortStep;

        _distance += stepLen;
        _stepCount++;
        notifyListeners();

        _peakVector.clear();
        _peakDetected = false;
      }
    }
  }

  static double _vectorNorm(num x, num y, num z) =>
      sqrt((x * x + y * y + z * z).toDouble());

  static bool _isFinite(double v) => v.isFinite && v < double.maxFinite;

  static void _pushWindow(List<double> buffer, double v) {
    buffer.add(v);
    if (buffer.length > _maxAvgCount) buffer.removeAt(0);
  }

  static double _avgWindow(List<double> buffer) =>
      buffer.isEmpty ? 0 : buffer.reduce((a, b) => a + b) / buffer.length;

  static void _pushGraph(List<double> buf, double v) {
    buf.add(v);
    if (buf.length > _maxGraphPoints) {
      buf.removeRange(0, buf.length - _maxGraphPoints);
    }
  }
}
