class AccSample {
  final int t;
  final double x, y, z, m;
  const AccSample(this.t, this.x, this.y, this.z, this.m);

  String toCsv() => '$t,$x,$y,$z,$m\n';
}
