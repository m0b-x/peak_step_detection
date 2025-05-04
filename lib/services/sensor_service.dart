import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:iirjdart/butterworth.dart';
import 'package:study_step_detection/services/csv_service.dart';
import 'package:study_step_detection/utils/acc_sample.dart';
import 'package:study_step_detection/utils/raw_accelerometer_sample.dart';
import 'package:study_step_detection/utils/sensor_utils.dart';
import '../config/sensor_config.dart';
import '../utils/circular_buffer.dart';

class SensorService extends ChangeNotifier {
  SensorService(this._config, this._csvService) {
    _initDebounce();
    _initBuffers();
    _initSensors();
  }

  int _lastNotifyTimeMs = 0;
  int _minNotifyIntervalMs = 16;
  bool _updateScheduled = false;
  final CsvService _csvService;
  Timer? _updateTimer;
  Timer? _warmupTimer;
  bool _accDirty = false, _gyroDirty = false, _magDirty = false;
  final ValueNotifier<bool> _isWarmingUp = ValueNotifier(true);
  final ValueNotifier<bool> isTracking = ValueNotifier(false);

  ValueNotifier<bool> get isWarmingUp => _isWarmingUp;

  final ValueNotifier<List<RawAccelerometerSample>> rawAccSeries =
      ValueNotifier([]);
  late final CircularBuffer<RawAccelerometerSample> _rawAccBuffer;
  final CircularBuffer<AccSample> _ramBuffer =
      CircularBuffer<AccSample>(120 * 100);
  List<AccSample> get recentAccSamples => _ramBuffer.toList(growable: false);
  final ValueNotifier<bool> isRecording = ValueNotifier(false);
  final ValueNotifier<bool> peakDetectedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> endDetectedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> fakePeakDetectedNotifier = ValueNotifier(false);

  final List<double> _accGraphBuffer = List.filled(_maxGraphPoints, 0.0);
  final List<double> _gyroGraphBuffer = List.filled(_maxGraphPoints, 0.0);
  final List<double> _magGraphBuffer = List.filled(_maxGraphPoints, 0.0);

  AccelerometerEvent? _lastAcc;
  GyroscopeEvent? _lastGyro;
  MagnetometerEvent? _lastMag;
  AccelerometerEvent? get latestAcc => _lastAcc;
  GyroscopeEvent? get latestGyro => _lastGyro;
  MagnetometerEvent? get latestMag => _lastMag;
  double _currentAccZMax = double.negativeInfinity;
  double _currentAccZMin = double.infinity;

  double get accMagnitude => _lastAcc == null
      ? 0
      : sqrt(
          SensorUtils.vectorNormSquared(_lastAcc!.x, _lastAcc!.y, _lastAcc!.z));
  double get gyroMagnitude => _lastGyro == null
      ? 0
      : sqrt(SensorUtils.vectorNormSquared(
          _lastGyro!.x, _lastGyro!.y, _lastGyro!.z));
  double get magMagnitude => _lastMag == null
      ? 0
      : sqrt(
          SensorUtils.vectorNormSquared(_lastMag!.x, _lastMag!.y, _lastMag!.z));

  double _filteredAcc = 0.0;
  double get filteredAcc => _filteredAcc;

  double _gyroAbsNet = 0.0;
  double get gyroAbsNet => _gyroAbsNet;

  double _avgAccMag = 0, _avgGyroMag = 0, _avgMagMag = 0;
  double get accAvgMagnitude => _avgAccMag;
  double get gyroAvgMagnitude => _avgGyroMag;
  double get magAvgMagnitude => _avgMagMag;

  double get accNetMagnitude => accMagnitude - _avgAccMag;
  double get gyroNetMagnitude => gyroMagnitude - _avgGyroMag;
  double get magNetMagnitude => magMagnitude - _avgMagMag;

  SensorConfig _config;
  SensorConfig get currentConfig => _config;

  final ValueNotifier<List<double>> accSeries = ValueNotifier(<double>[]);
  final ValueNotifier<List<double>> gyroSeries = ValueNotifier(<double>[]);
  final ValueNotifier<List<double>> magSeries = ValueNotifier(<double>[]);

  static const int _maxGraphPoints = 100;
  late final CircularBuffer<double> _accelerometerHistory =
      CircularBuffer<double>(_maxGraphPoints);
  late final CircularBuffer<double> _gyroHistory =
      CircularBuffer<double>(_maxGraphPoints);
  late final CircularBuffer<double> _magnetometerHistory =
      CircularBuffer<double>(_maxGraphPoints);

  int get _maxAvgCount => _config.maxWindowSize;
  late CircularBuffer<double> _accWinBuffer =
      CircularBuffer<double>(_maxAvgCount);
  late CircularBuffer<double> _gyroWinBuffer =
      CircularBuffer<double>(_maxAvgCount);
  late CircularBuffer<double> _magWinBuffer =
      CircularBuffer<double>(_maxAvgCount);

  double _accWinSum = 0;
  double _gyroWinSum = 0;
  double _magWinSum = 0;

  int _stepCount = 0;
  double _distance = 0.0;
  int get stepCount => _stepCount;
  double get distance => _distance;

  late final CircularBuffer<double> _startVector;
  late final CircularBuffer<double> _peakVector;
  late final CircularBuffer<double> _endVector;
  late final CircularBuffer<double> _magnitudeSampleBuffer;

  bool _peakDetected = false;

  int _lastStepTimestamp = 0;
  int get _minStepGapMs => _config.minStepGapMs;

  late Butterworth _lowPass;
  late Butterworth _highPass;
  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  static const double _maleStepLengthFactor = 0.415;
  static const double _femaleStepLengthFactor = 0.413;

  void _initDebounce() {
    final view = ui.PlatformDispatcher.instance.views.firstOrNull;
    if (view != null) {
      final rate = view.display.refreshRate;
      if (rate > 1.0) {
        _minNotifyIntervalMs = (1000 / rate).round();
      }
    }
  }

  void _initBuffers() {
    _startVector = CircularBuffer<double>(_config.startVectorSize);
    _peakVector = CircularBuffer<double>(_config.peakVectorSize);
    _endVector = CircularBuffer<double>(_config.endVectorSize);
    _magnitudeSampleBuffer = CircularBuffer<double>(
        (_config.startVectorSize + _config.endVectorSize));
    _rawAccBuffer = CircularBuffer<RawAccelerometerSample>(100);
  }

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

    if (_config.useLowPassFilter) {
      _lowPass = Butterworth()
        ..lowPass(
          _config.lowPassFilterOrder,
          fs,
          _config.lowPassFilterCutoffFreq,
        );
    }

    if (_config.useHighPassFilter) {
      _highPass = Butterworth()
        ..highPass(
          _config.highPassFilterOrder,
          fs,
          _config.highPassFilterCutoffFreq,
        );
    }
  }

  void toggleTracking() {
    isTracking.value = !isTracking.value;
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
    _csvService.dispose();
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
      accSeries.value = _accelerometerHistory.toList(growable: false);
      gyroSeries.value = _gyroHistory.toList(growable: false);
      magSeries.value = _magnetometerHistory.toList(growable: false);
    }
  }

  Future<bool> startRecording() async {
    if (isRecording.value) return true;
    final ok = await _csvService.startRecording();
    if (ok) {
      isRecording.value = true;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> stopRecording() async {
    if (!isRecording.value) return true;
    final ok = await _csvService.stopRecording();
    if (ok) {
      isRecording.value = false;
      notifyListeners();
    }
    return ok;
  }

  void _copyInto(CircularBuffer<double> src, List<double> target) {
    for (int i = 0; i < src.length; i++) {
      target[i] = src[i];
    }
  }

  bool updateConfig(SensorConfig newConfig) {
    newConfig = newConfig.copyWith(
      accScale: SensorUtils.sanitizePos(newConfig.accScale),
      gyroScale: SensorUtils.sanitizePos(newConfig.gyroScale),
      magScale: SensorUtils.sanitizePos(newConfig.magScale),
      accThreshold: SensorUtils.sanitizePos(newConfig.accThreshold),
      gyroThreshold: SensorUtils.sanitizePos(newConfig.gyroThreshold),
    );
    final vectorSizeChanged =
        newConfig.startVectorSize != _config.startVectorSize ||
            newConfig.endVectorSize != _config.endVectorSize;

    final pollingChanged = newConfig.pollingIntervalMs !=
            _config.pollingIntervalMs ||
        newConfig.useSystemDefaultInterval != _config.useSystemDefaultInterval;
    final filterChanged = newConfig.lowPassFilterOrder !=
            _config.lowPassFilterOrder ||
        newConfig.lowPassFilterCutoffFreq != _config.lowPassFilterCutoffFreq ||
        newConfig.highPassFilterOrder != _config.highPassFilterOrder ||
        newConfig.highPassFilterCutoffFreq !=
            _config.highPassFilterCutoffFreq ||
        newConfig.useLowPassFilter != _config.useLowPassFilter ||
        newConfig.useHighPassFilter != _config.useHighPassFilter;

    final uiIntervalChanged = newConfig.userInterfaceUpdateIntervalMs !=
        _config.userInterfaceUpdateIntervalMs;
    final windowChanged = newConfig.maxWindowSize != _config.maxWindowSize;

    _config = newConfig;
    if (vectorSizeChanged) {
      _startVector = CircularBuffer<double>(_config.startVectorSize);
      _endVector = CircularBuffer<double>(_config.endVectorSize);
      _peakVector.clear();
    }

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
    if (windowChanged) {
      _accWinBuffer = CircularBuffer<double>(_maxAvgCount);
      _gyroWinBuffer = CircularBuffer<double>(_maxAvgCount);
      _magWinBuffer = CircularBuffer<double>(_maxAvgCount);
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
    _warmupTimer?.cancel();
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

  void _onAccelerometer(AccelerometerEvent accEvent) {
    _lastAcc = accEvent;
    final magSq =
        SensorUtils.vectorNormSquared(accEvent.x, accEvent.y, accEvent.z);
    if (!SensorUtils.isFinite(magSq)) return;

    final mag = sqrt(magSq);

    _accWinSum += mag;
    if (_accWinBuffer.length == _accWinBuffer.capacity) {
      _accWinSum -= _accWinBuffer[0];
    }
    SensorUtils.pushWindow(_accWinBuffer, mag);
    _avgAccMag = _accWinSum / _accWinBuffer.length;

    final netMag = mag - _avgAccMag;
    double filtered = netMag;
    if (_config.useHighPassFilter) {
      filtered = _highPass.filter(filtered);
    }
    if (_config.useLowPassFilter) {
      filtered = _lowPass.filter(filtered);
    }
    _filteredAcc = filtered;

    if (isRecording.value) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      _csvService.addCsvRow(
          '$ts,${accEvent.x},${accEvent.y},${accEvent.z},$_filteredAcc');
    }

    SensorUtils.pushGraph(
        _accelerometerHistory, _config.accScale * _filteredAcc);
    _accDirty = true;

    final rawSample =
        RawAccelerometerSample(accEvent.x, accEvent.y, accEvent.z);
    _rawAccBuffer.add(rawSample);
    rawAccSeries.value = _rawAccBuffer.toList(growable: false);
    if (isTracking.value && !_isWarmingUp.value) {
      _detectStep(_filteredAcc, accEvent.z);
    }
  }

  void _onGyroscope(GyroscopeEvent e) {
    _lastGyro = e;
    final magSq = SensorUtils.vectorNormSquared(e.x, e.y, e.z);
    final mag = sqrt(magSq);

    _gyroWinSum += mag;
    if (_gyroWinBuffer.length == _gyroWinBuffer.capacity) {
      _gyroWinSum -= _gyroWinBuffer[0];
    }
    SensorUtils.pushWindow(_gyroWinBuffer, mag);
    _avgGyroMag = _gyroWinSum / _gyroWinBuffer.length;

    _gyroAbsNet = (mag - _avgGyroMag).abs();

    SensorUtils.pushGraph(_gyroHistory, _config.gyroScale * _gyroAbsNet);
    _gyroDirty = true;
  }

  void _onMagnetometer(MagnetometerEvent e) {
    _lastMag = e;
    final magSq = SensorUtils.vectorNormSquared(e.x, e.y, e.z);
    final mag = sqrt(magSq);

    _magWinSum += mag;
    if (_magWinBuffer.length == _magWinBuffer.capacity) {
      _magWinSum -= _magWinBuffer[0];
    }
    SensorUtils.pushWindow(_magWinBuffer, mag);
    _avgMagMag = _magWinSum / _magWinBuffer.length;

    SensorUtils.pushGraph(_magnetometerHistory, _config.magScale * _avgMagMag);
    _magDirty = true;
  }

  void _detectStep(
      double filteredNetMagnitude, double zAccelerometerComponent) {
    final now = DateTime.now().millisecondsSinceEpoch;

    _startVector.add(filteredNetMagnitude);
    _magnitudeSampleBuffer.add(filteredNetMagnitude);

    if (zAccelerometerComponent > _currentAccZMax) {
      _currentAccZMax = zAccelerometerComponent;
    }
    if (zAccelerometerComponent < _currentAccZMin) {
      _currentAccZMin = zAccelerometerComponent;
    }

    if (SensorUtils.isRising(_startVector) &&
        filteredNetMagnitude > _config.accThreshold) {
      _peakDetected = true;
      _peakVector.add(filteredNetMagnitude);
      peakDetectedNotifier.value = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        peakDetectedNotifier.value = false;
      });
    }

    if (_peakDetected) {
      _endVector.add(filteredNetMagnitude);

      if (SensorUtils.isFalling(_endVector)) {
        final timeSinceLastStep = now - _lastStepTimestamp;

        if (_avgGyroMag >= _config.gyroThreshold) {
          _onFakePeakDetected();
          return;
        }

        if (timeSinceLastStep >= _minStepGapMs) {
          final stepLength = _estimateStepLength(
              _currentAccZMax, _currentAccZMin, _magnitudeSampleBuffer);
          _distance += stepLength;
          _stepCount++;
          _lastStepTimestamp = now;
          notifyListeners();
        }
        _resetAfterValidStep();
      } else if (_endVector.length >= _config.endVectorSize) {
        _onFakePeakDetected();
      }
    }
  }

  void _onFakePeakDetected() {
    fakePeakDetectedNotifier.value = true;
    Future.delayed(const Duration(milliseconds: 300), () {
      fakePeakDetectedNotifier.value = false;
    });

    _peakVector.clear();
    _endVector.clear();
    _peakDetected = false;

    _currentAccZMax = double.negativeInfinity;
    _currentAccZMin = double.infinity;
    _magnitudeSampleBuffer.clear();
  }

  void _resetAfterValidStep() {
    _peakVector.clear();
    _peakDetected = false;
    endDetectedNotifier.value = true;

    _currentAccZMax = double.negativeInfinity;
    _currentAccZMin = double.infinity;
    _magnitudeSampleBuffer.clear();

    Future.delayed(const Duration(milliseconds: 300), () {
      endDetectedNotifier.value = false;
    });
  }

  double _estimateStepLength(
      double amax, double amin, CircularBuffer<double> verticalAccSamples) {
    var kGenderFactor =
        (_config.isMale ? _maleStepLengthFactor : _femaleStepLengthFactor);

    switch (_config.stepModel) {
      case StepModel.staticHeightAndGender:
        return kGenderFactor * _config.heightMeters;

      case StepModel.weinbergMethod:
        final diff = amax - amin;
        return kGenderFactor * pow(diff, 1 / 4);

      case StepModel.meanAbs:
        double sumAbs = 0.0;
        for (var i = 0; i < verticalAccSamples.length; i++) {
          sumAbs += verticalAccSamples[i].abs();
        }
        final meanAbs = sumAbs / verticalAccSamples.length;
        return _config.accMeanKConstant * pow(meanAbs, 1 / 3);
    }
  }

  void _flushSensorUpdates() {
    if (_updateScheduled) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - _lastNotifyTimeMs;

    if (elapsed < _minNotifyIntervalMs) {
      // Not enough time passed => schedule later
      final delay = Duration(milliseconds: _minNotifyIntervalMs - elapsed);
      _updateScheduled = true;
      Future.delayed(delay, _flushSensorUpdates);
      return;
    }

    _lastNotifyTimeMs = now;
    _updateScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;

      bool any = false;
      if (_accDirty) {
        _copyInto(_accelerometerHistory, _accGraphBuffer);
        accSeries.value =
            _accGraphBuffer.sublist(0, _accelerometerHistory.length);

        _accDirty = false;
        any = true;
      }
      if (_gyroDirty) {
        _copyInto(_gyroHistory, _gyroGraphBuffer);
        gyroSeries.value = _gyroGraphBuffer.sublist(0, _gyroHistory.length);
        _gyroDirty = false;
        any = true;
      }
      if (_magDirty) {
        _copyInto(_magnetometerHistory, _magGraphBuffer);
        magSeries.value =
            _magGraphBuffer.sublist(0, _magnetometerHistory.length);
        _magDirty = false;
        any = true;
      }
      if (any) {
        notifyListeners();
      }
    });
  }
}
