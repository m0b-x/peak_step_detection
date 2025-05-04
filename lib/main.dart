import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_step_detection/services/csv_service.dart';

import 'config/sensor_config.dart';
import 'config/graph_visibility_config.dart';
import 'services/sensor_service.dart';
import 'screens/sensor_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => CsvService()),
        ChangeNotifierProvider(
          create: (context) => SensorService(
            defaultSensorConfig,
            context.read<CsvService>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => defaultGraphVisibilityConfig),
      ],
      child: const MyApp(),
    ),
  );
}

const SensorConfig defaultSensorConfig = SensorConfig();

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
