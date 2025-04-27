import 'package:flutter/foundation.dart';

class GraphVisibilityConfig with ChangeNotifier {
  bool showAccelerometer;
  bool showRawAccelerometer;
  bool showGyroscope;
  bool showMagnetometer;

  GraphVisibilityConfig({
    this.showAccelerometer = true,
    this.showRawAccelerometer = true,
    this.showGyroscope = true,
    this.showMagnetometer = false,
  });

  void toggle(String graphName) {
    switch (graphName) {
      case 'Accelerometer':
        showAccelerometer = !showAccelerometer;
        break;
      case 'RawAccelerometer':
        showRawAccelerometer = !showRawAccelerometer;
        break;
      case 'Gyroscope':
        showGyroscope = !showGyroscope;
        break;
      case 'Magnetometer':
        showMagnetometer = !showMagnetometer;
        break;
    }
    notifyListeners();
  }

  GraphVisibilityConfig copyWith({
    bool? showAccelerometer,
    bool? showRawAccelerometer,
    bool? showGyroscope,
    bool? showMagnetometer,
  }) {
    return GraphVisibilityConfig(
      showAccelerometer: showAccelerometer ?? this.showAccelerometer,
      showRawAccelerometer: showRawAccelerometer ?? this.showRawAccelerometer,
      showGyroscope: showGyroscope ?? this.showGyroscope,
      showMagnetometer: showMagnetometer ?? this.showMagnetometer,
    );
  }
}

final GraphVisibilityConfig defaultGraphVisibilityConfig =
    GraphVisibilityConfig();
