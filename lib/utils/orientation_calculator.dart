import 'dart:math';

class OrientationCalculator {
  OrientationCalculator({
    required this.ax,
    required this.ay,
    required this.az,
    required this.mx,
    required this.my,
    required this.mz,
    required this.L,
  }) : assert(L > 1e-6, 'Vector magnitude L must be non‑zero');

  double ax, ay, az, mx, my, mz, L;

  double calculateYaw() {
    return atan2(
      (ax * mz - az * mx) * L,
      my * (pow(az, 2) + pow(ax, 2)) - ay * (az * mz + ax * my),
    );
  }

  double calculatePitch() {
    return -asin(ay / L);
  }

  double calculateRoll() {
    return -atan2(ax, az);
  }

  List<double> calculateQuaternion() {
    double yaw = calculateYaw();
    double pitch = calculatePitch();
    double roll = calculateRoll();

    double cy = cos(yaw / 2);
    double sy = sin(yaw / 2);
    double cp = cos(pitch / 2);
    double sp = sin(pitch / 2);
    double cr = cos(roll / 2);
    double sr = sin(roll / 2);

    double q0 = cy * cp * cr - sy * sp * sr;
    double q1 = cy * sp * cr + sy * cp * sr;
    double q2 = sy * cp * cr - cy * sp * sr;
    double q3 = cy * cp * sr + sy * sp * cr;

    // Normalize the quaternion
    double norm = sqrt(q0 * q0 + q1 * q1 + q2 * q2 + q3 * q3);
    q0 /= norm;
    q1 /= norm;
    q2 /= norm;
    q3 /= norm;

    return [q0, q1, q2, q3];
  }

  List<List<double>> calculateRotationMatrix() {
    List<double> q = calculateQuaternion();
    double q0 = q[0];
    double q1 = q[1];
    double q2 = q[2];
    double q3 = q[3];

    // Compute the rotation matrix T
    List<List<double>> T = [
      [
        q0 * q0 + q1 * q1 - q2 * q2 - q3 * q3,
        2 * (q1 * q2 - q0 * q3),
        2 * (q1 * q3 + q0 * q2)
      ],
      [
        2 * (q1 * q2 + q0 * q3),
        q0 * q0 - q1 * q1 + q2 * q2 - q3 * q3,
        2 * (q2 * q3 - q0 * q1)
      ],
      [
        2 * (q1 * q3 - q0 * q2),
        2 * (q2 * q3 + q0 * q1),
        q0 * q0 - q1 * q1 - q2 * q2 + q3 * q3
      ]
    ];

    return T;
  }
}
//Compute Quat and rotation matrix
