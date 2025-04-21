class SensorConfig {
  final bool warmUpSensors;
  final int warmUpDurationMs;

  final bool useSystemDefaultInterval;
  final int pollingIntervalMs;
  final int userInterfaceUpdateIntervalMs;

  final int filterOrder;
  final double filterCutoffFreq;
  final double bandPassCenter;
  final double bandPassWidth;

  final double accThreshold;
  final double gyroThreshold;

  final double accelerometerScale;
  final double gyroScale;
  final double magScale;

  final double shortStep;
  final double mediumStep;
  final double longStep;
  final double bigStepThreshold;
  final double mediumStepThreshold;

  const SensorConfig({
    this.useSystemDefaultInterval = false,
    this.pollingIntervalMs = 200,
    this.userInterfaceUpdateIntervalMs = 100,
    this.filterOrder = 2,
    this.filterCutoffFreq = 2.0,
    this.bandPassCenter = 0.0,
    this.bandPassWidth = 1.0,
    this.accThreshold = 1.0,
    this.gyroThreshold = 1.0,
    this.accelerometerScale = 100.0,
    this.gyroScale = 1.0,
    this.magScale = 1.0,
    this.shortStep = 0.5,
    this.mediumStep = 1.0,
    this.longStep = 1.5,
    this.bigStepThreshold = 0.13,
    this.mediumStepThreshold = 0.1,
    this.warmUpSensors = true,
    this.warmUpDurationMs = 5000,
  });

  SensorConfig copyWith({
    // Sampling
    bool? useSystemDefaultInterval,
    int? pollingIntervalMs,
    int? userInterfaceUpdateIntervalMs,
    // Filter
    int? filterOrder,
    double? filterCutoffFreq,
    double? bandPassCenter,
    double? bandPassWidth,
    // Thresholds
    double? accThreshold,
    double? gyroThreshold,
    // Scaling
    double? accScale,
    double? gyroScale,
    double? magScale,
    // Step model
    double? shortStep,
    double? mediumStep,
    double? longStep,
    double? bigStepThreshold,
    double? mediumStepThreshold,
    // Warm-up
    bool? warmUpSensors,
    int? warmUpDurationMs,
  }) {
    return SensorConfig(
      useSystemDefaultInterval:
          useSystemDefaultInterval ?? this.useSystemDefaultInterval,
      pollingIntervalMs: pollingIntervalMs ?? this.pollingIntervalMs,
      userInterfaceUpdateIntervalMs:
          userInterfaceUpdateIntervalMs ?? this.userInterfaceUpdateIntervalMs,
      filterOrder: filterOrder ?? this.filterOrder,
      filterCutoffFreq: filterCutoffFreq ?? this.filterCutoffFreq,
      bandPassCenter: bandPassCenter ?? this.bandPassCenter,
      bandPassWidth: bandPassWidth ?? this.bandPassWidth,
      accThreshold: accThreshold ?? this.accThreshold,
      gyroThreshold: gyroThreshold ?? this.gyroThreshold,
      accelerometerScale: accScale ?? accelerometerScale,
      gyroScale: gyroScale ?? this.gyroScale,
      magScale: magScale ?? this.magScale,
      shortStep: shortStep ?? this.shortStep,
      mediumStep: mediumStep ?? this.mediumStep,
      longStep: longStep ?? this.longStep,
      bigStepThreshold: bigStepThreshold ?? this.bigStepThreshold,
      mediumStepThreshold: mediumStepThreshold ?? this.mediumStepThreshold,
      warmUpSensors: warmUpSensors ?? this.warmUpSensors,
      warmUpDurationMs: warmUpDurationMs ?? this.warmUpDurationMs,
    );
  }
}
