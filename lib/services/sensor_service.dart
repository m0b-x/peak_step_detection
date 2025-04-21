import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:iirjdart/butterworth.dart';

import '../config/sensor_config.dart';

class SensorService extends ChangeNotifier {
  SensorService(this._config) {
    _initSensors();
  }

  Timer? _updateTimer;
  Timer? _warmupTimer;
  bool _accDirty = false, _gyroDirty = false, _magDirty = false;

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
  double get gyroMagnitude => _lastGyro == null
      ? 0
      : _vectorNorm(_lastGyro!.x, _lastGyro!.y, _lastGyro!.z);
  double get magMagnitude =>
      _lastMag == null ? 0 : _vectorNorm(_lastMag!.x, _lastMag!.y, _lastMag!.z);

  double get accAvgMagnitude => _avgAccMag;
  double get gyroAvgMagnitude => _avgGyroMag;
  double get magAvgMagnitude => _avgMagMag;

  double get accNetMagnitude => accMagnitude - _avgAccMag;
  double get gyroNetMagnitude => gyroMagnitude - _avgGyroMag;
  double get magNetMagnitude => magMagnitude - _avgMagMag;

  double _avgAccMag = 0, _avgGyroMag = 0, _avgMagMag = 0;

  SensorConfig _config;
  SensorConfig get currentConfig => _config;

  final ValueNotifier<List<double>> accSeries = ValueNotifier(<double>[]);
  final ValueNotifier<List<double>> gyroSeries = ValueNotifier(<double>[]);
  final ValueNotifier<List<double>> magSeries = ValueNotifier(<double>[]);

  final _accelerometerHistory = <double>[];
  final _gyroHistory = <double>[];
  final _magnetometerHistory = <double>[];

  int _stepCount = 0;
  double _distance = 0.0;
  int get stepCount => _stepCount;
  double get distance => _distance;

  static const int _vecLen = 3;
  final _startVector = <double>[];
  final _peakVector = <double>[];
  final _endVector = <double>[];
  bool _peakDetected = false;

  late Butterworth _lowPass;

  static const int _maxAvgCount = 3;
  static const int _maxGraphPoints = 100;

  final _accWinBuffer = <double>[];
  final _gyroWinBuffer = <double>[];
  final _magWinBuffer = <double>[];

  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  Future<void> _initSensors() async {
    _initFilters();

    _isWarmingUp.value = _config.warmUpSensors;
    _subscribeSensors();

    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(
      Duration(milliseconds: _config.userInterfaceUpdateIntervalMs),
      (_) => _flushSensorUpdates(),
    );

    if (_config.warmUpSensors) {
      await Future.delayed(Duration(milliseconds: _config.warmUpDurationMs));
    }

    _isWarmingUp.value = false;
    notifyListeners();
  }

  void _initFilters() {
    final fs = 1000 / _config.pollingIntervalMs;
    _lowPass = Butterworth()
      ..lowPass(_config.filterOrder, fs, _config.filterCutoffFreq);
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
    _updateTimer?.cancel();
    _warmupTimer?.cancel();
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
    _distance = 0;
    notifyListeners();
  }

  void resetGraphs() {
    _accelerometerHistory.clear();
    _gyroHistory.clear();
    _magnetometerHistory.clear();
    if (!isWarmingUp.value) {
      accSeries.value = List.unmodifiable(_accelerometerHistory);
      gyroSeries.value = List.unmodifiable(_gyroHistory);
      magSeries.value = List.unmodifiable(_magnetometerHistory);
    }
  }

  bool updateConfig(SensorConfig newConfig) {
    newConfig = newConfig.copyWith(
      accScale: _sanitizePos(newConfig.accelerometerScale),
      gyroScale: _sanitizePos(newConfig.gyroScale),
      magScale: _sanitizePos(newConfig.magScale),
      accThreshold: _sanitizePos(newConfig.accThreshold),
      gyroThreshold: _sanitizePos(newConfig.gyroThreshold),
    );

    final pollingChanged = newConfig.pollingIntervalMs !=
            _config.pollingIntervalMs ||
        newConfig.useSystemDefaultInterval != _config.useSystemDefaultInterval;
    final filterChanged = newConfig.filterOrder != _config.filterOrder ||
        newConfig.filterCutoffFreq != _config.filterCutoffFreq;
    final uiIntervalChanged = newConfig.userInterfaceUpdateIntervalMs !=
        _config.userInterfaceUpdateIntervalMs;

    _config = newConfig;

    if (pollingChanged) {
      _accSub?.cancel();
      _gyroSub?.cancel();
      _magSub?.cancel();
      _subscribeSensors();
    }
    if (filterChanged) {
      _initFilters();
      _accWinBuffer.clear();
      _gyroWinBuffer.clear();
      _magWinBuffer.clear();
      _startVector.clear();
      _peakVector.clear();
      _endVector.clear();
    }
    if (uiIntervalChanged) {
      _updateTimer?.cancel();
      _updateTimer = Timer.periodic(
        Duration(milliseconds: newConfig.userInterfaceUpdateIntervalMs),
        (_) => _flushSensorUpdates(),
      );
    }

    final needsWarm =
        (pollingChanged || filterChanged) && newConfig.warmUpSensors;
    _warmupTimer?.cancel(); // cancel any previous warm‑up
    if (needsWarm) {
      _isWarmingUp.value = true;
      _warmupTimer = Timer(
        Duration(milliseconds: newConfig.warmUpDurationMs),
        _initSensors,
      );
    } else {
      _isWarmingUp.value = false;
    }
    return needsWarm;
  }

  double _sanitizePos(double v) => v <= 0 ? 1.0 : v;

  void _onAccelerometer(AccelerometerEvent e) {
    _lastAcc = e;
    final mag = _vectorNorm(e.x, e.y, e.z);
    if (!_isFinite(mag)) return;

    _pushWindow(_accWinBuffer, mag);
    _avgAccMag = _avgWindow(_accWinBuffer);
    final filtered = _lowPass.filter(mag - _avgAccMag);

    _pushGraph(_accelerometerHistory, _config.accelerometerScale * filtered);
    _accDirty = true;
    _detectStep(filtered);
  }

  void _onGyroscope(GyroscopeEvent e) {
    _lastGyro = e;
    final mag = _vectorNorm(e.x, e.y, e.z);
    _pushWindow(_gyroWinBuffer, mag);
    _avgGyroMag = _avgWindow(_gyroWinBuffer);
    _pushGraph(_gyroHistory, _config.gyroScale * (mag - _avgGyroMag).abs());
    _gyroDirty = true;
  }

  void _onMagnetometer(MagnetometerEvent e) {
    _lastMag = e;
    final mag = _vectorNorm(e.x, e.y, e.z);
    _pushWindow(_magWinBuffer, mag);
    _avgMagMag = _avgWindow(_magWinBuffer);
    _pushGraph(
        _magnetometerHistory, _config.magScale * (mag - _avgMagMag).abs());
    _magDirty = true;
  }

  void _detectStep(double v) {
    _startVector.add(v);
    if (_startVector.length > _vecLen) _startVector.removeAt(0);

    if (_isRising(_startVector) && v > _config.accThreshold) {
      _peakDetected = true;
      _peakVector.add(v);
      if (_peakVector.length > _vecLen) _peakVector.removeAt(0);
    }

    if (_peakDetected) {
      _endVector.add(v);
      if (_endVector.length > _vecLen) _endVector.removeAt(0);

      if (_isFalling(_endVector)) {
        final maxPeak = _peakVector.reduce(max);
        final stepLen = maxPeak > _config.bigStepThreshold
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

  bool _isRising(List<double> v) =>
      v.length >= 2 &&
      List.generate(v.length - 1, (i) => v[i + 1] > v[i]).every((e) => e);
  bool _isFalling(List<double> v) =>
      v.length >= 2 &&
      List.generate(v.length - 1, (i) => v[i + 1] < v[i]).every((e) => e);

  static double _vectorNorm(num x, num y, num z) =>
      sqrt((x * x + y * y + z * z).toDouble());
  static bool _isFinite(double v) => v.isFinite && v < double.maxFinite;

  static void _pushWindow(List<double> b, double v) {
    b.add(v);
    if (b.length > _maxAvgCount) b.removeAt(0);
  }

  static double _avgWindow(List<double> b) =>
      b.isEmpty ? 0 : b.reduce((a, b) => a + b) / b.length;

  static void _pushGraph(List<double> buf, double v) {
    buf.add(v);
    if (buf.length > _maxGraphPoints) {
      buf.removeRange(0, buf.length - _maxGraphPoints);
    }
  }

  void _flushSensorUpdates() {
    bool any = false;
    if (_accDirty) {
      accSeries.value = List.unmodifiable(_accelerometerHistory);
      _accDirty = false;
      any = true;
    }
    if (_gyroDirty) {
      gyroSeries.value = List.unmodifiable(_gyroHistory);
      _gyroDirty = false;
      any = true;
    }
    if (_magDirty) {
      magSeries.value = List.unmodifiable(_magnetometerHistory);
      _magDirty = false;
      any = true;
    }
    if (any) notifyListeners();
  }
}
