import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/sensor_config.dart';
import 'services/sensor_service.dart';
import 'screens/sensor_screen.dart';

void main() {
  const SensorConfig defaultConfig = SensorConfig();
  runApp(
    ChangeNotifierProvider(
      create: (_) => SensorService(defaultConfig),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Step Counter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const SensorScreen(),
    );
  }
}
