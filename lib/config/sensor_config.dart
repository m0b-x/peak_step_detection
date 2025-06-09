enum StepModel { staticHeightAndGender, weinbergMethod, meanAbs }

enum SmartphonePosition { pocket, handReading, handSwinging, bag }

enum WalkingSpeed { slow, normal, fast }

class SensorConfig {
  final String name;
  final SmartphonePosition smartphonePosition;
  final WalkingSpeed walkingSpeed;
  final double pathLength;
  final double legLength;

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

  final double accMeanKConstant;

  final int maxWindowSize;

  final bool useLowPassFilter;
  final int lowPassFilterOrder;
  final double lowPassFilterCutoffFreq;

  final bool useHighPassFilter;
  final int highPassFilterOrder;
  final double highPassFilterCutoffFreq;

  final double accThreshold;
  final double gyroThreshold;

  final double accScale;
  final double gyroScale;
  final double magScale;

  final bool isMale;
  final double heightMeters;

  const SensorConfig({
    this.name = 'person1',
    this.smartphonePosition = SmartphonePosition.handReading,
    this.walkingSpeed = WalkingSpeed.normal,
    this.pathLength = 100,
    this.legLength = -1,
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
    this.accMeanKConstant = 0.75,
    this.maxWindowSize = 15,
    this.useLowPassFilter = true,
    this.lowPassFilterOrder = 3,
    this.lowPassFilterCutoffFreq = 1.0,
    this.useHighPassFilter = false,
    this.highPassFilterOrder = 1,
    this.highPassFilterCutoffFreq = 0.3,
    this.accThreshold = 0.75,
    this.gyroThreshold = 1.5,
    this.accScale = 1.0,
    this.gyroScale = 1.0,
    this.magScale = 1.0,
    this.isMale = true,
    this.heightMeters = 1.78,
  });

  SensorConfig copyWith({
    String? name,
    SmartphonePosition? smartphonePosition,
    WalkingSpeed? walkingSpeed,
    double? pathLength,
    double? legLength,
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
    double? accMeanKConstant,
    int? maxWindowSize,
    bool? useLowPassFilter,
    int? lowPassFilterOrder,
    double? lowPassFilterCutoffFreq,
    bool? useHighPassFilter,
    int? highPassFilterOrder,
    double? highPassFilterCutoffFreq,
    double? accThreshold,
    double? gyroThreshold,
    double? accScale,
    double? gyroScale,
    double? magScale,
    bool? isMale,
    double? heightMeters,
  }) {
    return SensorConfig(
      name: name ?? this.name,
      smartphonePosition: smartphonePosition ?? this.smartphonePosition,
      walkingSpeed: walkingSpeed ?? this.walkingSpeed,
      pathLength: pathLength ?? this.pathLength,
      legLength: legLength ?? this.legLength,
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
      accMeanKConstant: accMeanKConstant ?? this.accMeanKConstant,
      maxWindowSize: maxWindowSize ?? this.maxWindowSize,
      useLowPassFilter: useLowPassFilter ?? this.useLowPassFilter,
      lowPassFilterOrder: lowPassFilterOrder ?? this.lowPassFilterOrder,
      lowPassFilterCutoffFreq:
          lowPassFilterCutoffFreq ?? this.lowPassFilterCutoffFreq,
      useHighPassFilter: useHighPassFilter ?? this.useHighPassFilter,
      highPassFilterOrder: highPassFilterOrder ?? this.highPassFilterOrder,
      highPassFilterCutoffFreq:
          highPassFilterCutoffFreq ?? this.highPassFilterCutoffFreq,
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
