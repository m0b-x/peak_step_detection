import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sensor_service.dart';
import '../config/sensor_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SensorConfig draft;
  final _formKey = GlobalKey<FormState>();

  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    final current = context.read<SensorService>().currentConfig;
    draft = current;

    _initControllers();
  }

  void _initControllers() {
    _controllers['pollingIntervalMs'] =
        TextEditingController(text: draft.pollingIntervalMs.toString());
    _controllers['userInterfaceUpdateIntervalMs'] = TextEditingController(
        text: draft.userInterfaceUpdateIntervalMs.toString());
    _controllers['warmUpDurationMs'] =
        TextEditingController(text: draft.warmUpDurationMs.toString());

    _controllers['filterOrder'] =
        TextEditingController(text: draft.filterOrder.toString());
    _controllers['filterCutoffFreq'] =
        TextEditingController(text: draft.filterCutoffFreq.toString());

    _controllers['accThreshold'] =
        TextEditingController(text: draft.accThreshold.toString());
    _controllers['gyroThreshold'] =
        TextEditingController(text: draft.gyroThreshold.toString());

    _controllers['accScale'] =
        TextEditingController(text: draft.accelerometerScale.toString());
    _controllers['gyroScale'] =
        TextEditingController(text: draft.gyroScale.toString());
    _controllers['magScale'] =
        TextEditingController(text: draft.magScale.toString());

    _controllers['shortStep'] =
        TextEditingController(text: draft.shortStep.toString());
    _controllers['mediumStep'] =
        TextEditingController(text: draft.mediumStep.toString());
    _controllers['longStep'] =
        TextEditingController(text: draft.longStep.toString());

    _controllers['bigStepThreshold'] =
        TextEditingController(text: draft.bigStepThreshold.toString());
    _controllers['mediumStepThreshold'] =
        TextEditingController(text: draft.mediumStepThreshold.toString());
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionHeader('Sampling'),
            _intField('Polling interval (ms)', 'pollingIntervalMs'),
            _intField(
                'UI update interval (ms)', 'userInterfaceUpdateIntervalMs'),
            SwitchListTile(
              title: const Text('Wait for sensors to warm up'),
              value: draft.warmUpSensors,
              onChanged: (val) =>
                  setState(() => draft = draft.copyWith(warmUpSensors: val)),
            ),
            _intField('Warm-up duration (ms)', 'warmUpDurationMs'),
            SwitchListTile(
              title: const Text('Use system default interval'),
              value: draft.useSystemDefaultInterval,
              onChanged: (val) => setState(
                  () => draft = draft.copyWith(useSystemDefaultInterval: val)),
            ),
            const _SectionHeader('Filters'),
            _intField('Butterworth order', 'filterOrder'),
            _doubleField('Cut‑off freq', 'filterCutoffFreq'),
            const _SectionHeader('Thresholds'),
            _doubleField('Acc net magnitude threshold', 'accThreshold'),
            _doubleField('Gyro net magnitude threshold', 'gyroThreshold'),
            const _SectionHeader('Scaling factors'),
            _tripleRow([
              _doubleFieldMini('Acc', 'accScale', requiresPositive: true),
              _doubleFieldMini('Gyro', 'gyroScale', requiresPositive: true),
              _doubleFieldMini('Mag', 'magScale', requiresPositive: true),
            ]),
            const _SectionHeader('Step lengths (m)'),
            _tripleRow([
              _doubleFieldMini('Short', 'shortStep'),
              _doubleFieldMini('Medium', 'mediumStep'),
              _doubleFieldMini('Long', 'longStep'),
            ]),
            const _SectionHeader('Step thresholds'),
            _doubleField('Big‑step threshold', 'bigStepThreshold'),
            _doubleField('Medium‑step threshold', 'mediumStepThreshold'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save & Restart Sensors'),
              onPressed: _save,
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      draft = draft.copyWith(
        pollingIntervalMs:
            int.parse(_controllers['pollingIntervalMs']!.text.trim()),
        userInterfaceUpdateIntervalMs: int.parse(
            _controllers['userInterfaceUpdateIntervalMs']!.text.trim()),
        warmUpDurationMs:
            int.parse(_controllers['warmUpDurationMs']!.text.trim()),
        filterOrder: int.parse(_controllers['filterOrder']!.text.trim()),
        filterCutoffFreq:
            double.parse(_controllers['filterCutoffFreq']!.text.trim()),
        accThreshold: double.parse(_controllers['accThreshold']!.text.trim()),
        gyroThreshold: double.parse(_controllers['gyroThreshold']!.text.trim()),
        accScale: double.parse(_controllers['accScale']!.text.trim()),
        gyroScale: double.parse(_controllers['gyroScale']!.text.trim()),
        magScale: double.parse(_controllers['magScale']!.text.trim()),
        shortStep: double.parse(_controllers['shortStep']!.text.trim()),
        mediumStep: double.parse(_controllers['mediumStep']!.text.trim()),
        longStep: double.parse(_controllers['longStep']!.text.trim()),
        bigStepThreshold:
            double.parse(_controllers['bigStepThreshold']!.text.trim()),
        mediumStepThreshold:
            double.parse(_controllers['mediumStepThreshold']!.text.trim()),
      );
    });

    final didWarmup = context.read<SensorService>().updateConfig(draft);

    if (!didWarmup && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings applied instantly'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    Navigator.of(context).pop();
  }

  Widget _intField(String label, String key) => TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        validator: (v) =>
            int.tryParse(v ?? '') == null ? 'Enter an integer' : null,
      );

  Widget _doubleField(String label, String key,
          {bool requiresPositive = false}) =>
      TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(labelText: label),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) {
          final val = double.tryParse(v ?? '');
          if (val == null) return 'Enter a number';
          if (requiresPositive && val <= 0) return 'Enter a positive number';
          return null;
        },
      );

  Widget _doubleFieldMini(String label, String key,
          {bool requiresPositive = false}) =>
      Expanded(
        child: _doubleField(label, key, requiresPositive: requiresPositive),
      );

  Widget _tripleRow(List<Widget> children) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              children[i],
            ]
          ],
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleMedium!
              .copyWith(fontWeight: FontWeight.bold),
        ),
      );
}
