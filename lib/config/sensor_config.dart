enum StepModel { staticHeightAndGender, weinbergMethod, meanAbs }

class SensorConfig {
  final bool useSystemDefaultInterval;
  final int pollingIntervalMs;
  final int userInterfaceUpdateIntervalMs;
  final int detectedLabelDuration;

  final bool warmUpSensors;
  final int warmUpDurationMs;

  final int minStepGapMs;
  final StepModel stepModel;
  final int startVectorSize;
  final int peakVectorSize;
  final int endVectorSize;

  final double weinbergKPowFactor;
  final double accMeanKConstant;

  final int filterOrder;
  final double filterCutoffFreq;
  final int maxWindowSize;

  final double accThreshold;
  final double gyroThreshold;

  final double accScale;
  final double gyroScale;
  final double magScale;

  final bool isMale;
  final double heightMeters;

  const SensorConfig({
    this.useSystemDefaultInterval = false,
    this.pollingIntervalMs = 100,
    this.userInterfaceUpdateIntervalMs = 100,
    this.detectedLabelDuration = 200,
    this.warmUpSensors = true,
    this.warmUpDurationMs = 5000,
    this.minStepGapMs = 300,
    this.stepModel = StepModel.staticHeightAndGender,
    this.startVectorSize = 3,
    this.peakVectorSize = 3,
    this.endVectorSize = 2,
    this.weinbergKPowFactor = 0.25,
    this.accMeanKConstant = 0.75,
    this.filterOrder = 3,
    this.filterCutoffFreq = 1.0,
    this.maxWindowSize = 15,
    this.accThreshold = 0.75,
    this.gyroThreshold = 1.5,
    this.accScale = 1.0,
    this.gyroScale = 1.0,
    this.magScale = 1.0,
    this.isMale = true,
    this.heightMeters = 1.78,
  });

  SensorConfig copyWith({
    bool? useSystemDefaultInterval,
    int? pollingIntervalMs,
    int? userInterfaceUpdateIntervalMs,
    int? detectedLabelDuration,
    bool? warmUpSensors,
    int? warmUpDurationMs,
    int? minStepGapMs,
    StepModel? stepModel,
    int? startVectorSize,
    int? peakVectorSize,
    int? endVectorSize,
    double? weinbergKPowFactor,
    double? accMeanKConstant,
    int? filterOrder,
    double? filterCutoffFreq,
    int? maxWindowSize,
    double? accThreshold,
    double? gyroThreshold,
    double? accScale,
    double? gyroScale,
    double? magScale,
    bool? isMale,
    double? heightMeters,
  }) {
    return SensorConfig(
      useSystemDefaultInterval:
          useSystemDefaultInterval ?? this.useSystemDefaultInterval,
      pollingIntervalMs: pollingIntervalMs ?? this.pollingIntervalMs,
      userInterfaceUpdateIntervalMs:
          userInterfaceUpdateIntervalMs ?? this.userInterfaceUpdateIntervalMs,
      detectedLabelDuration:
          detectedLabelDuration ?? this.detectedLabelDuration,
      warmUpSensors: warmUpSensors ?? this.warmUpSensors,
      warmUpDurationMs: warmUpDurationMs ?? this.warmUpDurationMs,
      minStepGapMs: minStepGapMs ?? this.minStepGapMs,
      stepModel: stepModel ?? this.stepModel,
      startVectorSize: startVectorSize ?? this.startVectorSize,
      peakVectorSize: peakVectorSize ?? this.peakVectorSize,
      endVectorSize: endVectorSize ?? this.endVectorSize,
      weinbergKPowFactor: weinbergKPowFactor ?? this.weinbergKPowFactor,
      accMeanKConstant: accMeanKConstant ?? this.accMeanKConstant,
      filterOrder: filterOrder ?? this.filterOrder,
      filterCutoffFreq: filterCutoffFreq ?? this.filterCutoffFreq,
      maxWindowSize: maxWindowSize ?? this.maxWindowSize,
      accThreshold: accThreshold ?? this.accThreshold,
      gyroThreshold: gyroThreshold ?? this.gyroThreshold,
      accScale: accScale ?? this.accScale,
      gyroScale: gyroScale ?? this.gyroScale,
      magScale: magScale ?? this.magScale,
      isMale: isMale ?? this.isMale,
      heightMeters: heightMeters ?? this.heightMeters,
    );
  }
}
