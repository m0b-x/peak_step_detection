import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/sensor_service.dart';
import '../config/sensor_config.dart';
import '../utils/settings_screen_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SensorConfig draft;
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  late bool _isMale;
  final Map<String, bool> _expandedSections = {};

  @override
  void initState() {
    super.initState();
    draft = context.read<SensorService>().currentConfig;
    _isMale = draft.isMale;
    _initControllers();

    const titles = [
      'User Interface',
      'Sampling',
      'Filtering',
      'Step Detection',
      'Step Length Estimation',
    ];
    _expandedSections.addEntries(titles.map((t) => MapEntry(t, false)));
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _allExpanded() =>
      _expandedSections.values.isNotEmpty &&
      _expandedSections.values.every((e) => e);

  void _toggleAll() {
    final expand = !_allExpanded();
    setState(() {
      for (final k in _expandedSections.keys) {
        _expandedSections[k] = expand;
      }
    });
  }

  Widget _intField(String label, String key) =>
      SettingsFieldUtils.intField(controller: _controllers[key]!, label: label);

  Widget _doubleField(String label, String key, {bool positive = false}) =>
      SettingsFieldUtils.doubleField(
        controller: _controllers[key]!,
        label: label,
        requiresPositive: positive,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            tooltip: _allExpanded() ? 'Collapse All' : 'Expand All',
            icon: Icon(_allExpanded() ? Icons.expand_less : Icons.expand_more),
            onPressed: _toggleAll,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Save & Restart Sensors'),
          onPressed: _save,
          style:
              ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _card('User Interface', [
              Text('UI Refresh Rate',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _intField(
                  'UI update interval (ms)', 'userInterfaceUpdateIntervalMs'),
              const Divider(height: 24),
              Text('Flashing Time',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _intField('Detected label flash (ms)', 'detectedLabelDuration'),
              const Divider(height: 24),
              Text('Scaling Factors',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SettingsFieldUtils.tripleRow([
                _doubleField('Acc', 'accScale', positive: true),
                _doubleField('Gyro', 'gyroScale', positive: true),
                _doubleField('Mag', 'magScale', positive: true),
              ]),
            ]),
            _card('Sampling', [
              Text('Sensor Sampling Rate',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _intField('Polling interval (ms)', 'pollingIntervalMs'),
              SwitchListTile(
                title: const Text('Use system default interval'),
                value: draft.useSystemDefaultInterval,
                onChanged: (v) => setState(
                    () => draft = draft.copyWith(useSystemDefaultInterval: v)),
              ),
            ]),
            _card('Filtering', [
              Text('Warm-up',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Wait for sensors to warm up'),
                value: draft.warmUpSensors,
                onChanged: (v) =>
                    setState(() => draft = draft.copyWith(warmUpSensors: v)),
              ),
              _intField('Warm-up duration (ms)', 'warmUpDurationMs'),
              const Divider(height: 24),
              Text('Window Size',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _intField('Running-mean window (samples)', 'maxWindowSize'),
              const Divider(height: 24),
              Text('Low Pass Filter',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Use low-pass Butterworth filter'),
                value: draft.useLowPassFilter,
                onChanged: (v) =>
                    setState(() => draft = draft.copyWith(useLowPassFilter: v)),
              ),
              SettingsFieldUtils.tripleRow([
                _intField('LP Order', 'lowPassFilterOrder'),
                _doubleField('LP Cutoff (Hz)', 'lowPassFilterCutoffFreq',
                    positive: true),
                const SizedBox(),
              ]),
              Text('HIgh Pass FIlter',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.bold)),
              SwitchListTile(
                title: const Text('Use high-pass Butterworth filter'),
                value: draft.useHighPassFilter,
                onChanged: (v) => setState(
                    () => draft = draft.copyWith(useHighPassFilter: v)),
              ),
              SettingsFieldUtils.tripleRow([
                _intField('HP Order', 'highPassFilterOrder'),
                _doubleField('HP Cutoff (Hz)', 'highPassFilterCutoffFreq',
                    positive: true),
                const SizedBox(),
              ]),
            ]),
            _card('Step Detection', [
              Text('Detection Threshold',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _doubleField('Accelerometer threshold', 'accThreshold'),
              const SizedBox(height: 24),
              Text('Vector Size',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SettingsFieldUtils.tripleRow([
                _intField('Start vector', 'startVectorSize'),
                _intField('Peak vector', 'peakVectorSize'),
                _intField('End vector', 'endVectorSize'),
              ]),
              const SizedBox(height: 24),
              Text('Fake Step Detection',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _doubleField('Gyroscope threshold', 'gyroThreshold'),
              _intField('Min Step Gap (ms)', 'minStepGapMs'),
            ]),
            _card('Step Length Estimation', [
              Text('Step Length Model',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<StepModel>(
                decoration: const InputDecoration(labelText: 'Model'),
                value: draft.stepModel,
                items: const [
                  DropdownMenuItem(
                    value: StepModel.staticHeightAndGender,
                    child: Text('Height * k(Gender Factor)'),
                  ),
                  DropdownMenuItem(
                    value: StepModel.weinbergMethod,
                    child: Text('Ls = k × (amax - amin)^(1/4)'),
                  ),
                  DropdownMenuItem(
                    value: StepModel.meanAbs,
                    child: Text('Ls = k × (∑|aᵢ|/N)^(1/3)'),
                  ),
                ],
                onChanged: (m) =>
                    setState(() => draft = draft.copyWith(stepModel: m)),
              ),
              if (draft.stepModel == StepModel.weinbergMethod)
                _doubleField('k2 (peak-diff scale)', 'peakDiffK',
                    positive: true),
              if (draft.stepModel == StepModel.meanAbs)
                _doubleField('k3 (mean-abs scale)', 'meanAbsK', positive: true),
              const SizedBox(height: 32),
              Text('User Details',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _doubleField('Height (m)', 'heightMeters', positive: true),
              DropdownButtonFormField<bool>(
                decoration: const InputDecoration(labelText: 'Gender'),
                value: _isMale,
                items: const [
                  DropdownMenuItem(value: true, child: Text('Male')),
                  DropdownMenuItem(value: false, child: Text('Female')),
                ],
                onChanged: (v) => setState(() => _isMale = v ?? true),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    final expanded = _expandedSections[title] ?? false;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expanded,
          onExpansionChanged: (v) =>
              setState(() => _expandedSections[title] = v),
          title: Row(
            children: [
              Icon(Icons.label_important,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children),
            ),
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
        detectedLabelDuration:
            int.parse(_controllers['detectedLabelDuration']!.text.trim()),
        warmUpDurationMs:
            int.parse(_controllers['warmUpDurationMs']!.text.trim()),
        minStepGapMs: int.parse(_controllers['minStepGapMs']!.text.trim()),
        startVectorSize:
            int.parse(_controllers['startVectorSize']!.text.trim()),
        peakVectorSize: int.parse(_controllers['peakVectorSize']!.text.trim()),
        endVectorSize: int.parse(_controllers['endVectorSize']!.text.trim()),
        accMeanKConstant: double.parse(_controllers['meanAbsK']!.text.trim()),
        maxWindowSize: int.parse(_controllers['maxWindowSize']!.text.trim()),
        useLowPassFilter: draft.useLowPassFilter,
        lowPassFilterOrder:
            int.parse(_controllers['lowPassFilterOrder']!.text.trim()),
        lowPassFilterCutoffFreq:
            double.parse(_controllers['lowPassFilterCutoffFreq']!.text.trim()),
        useHighPassFilter: draft.useHighPassFilter,
        highPassFilterOrder:
            int.parse(_controllers['highPassFilterOrder']!.text.trim()),
        highPassFilterCutoffFreq:
            double.parse(_controllers['highPassFilterCutoffFreq']!.text.trim()),
        accThreshold: double.parse(_controllers['accThreshold']!.text.trim()),
        gyroThreshold: double.parse(_controllers['gyroThreshold']!.text.trim()),
        accScale: double.parse(_controllers['accScale']!.text.trim()),
        gyroScale: double.parse(_controllers['gyroScale']!.text.trim()),
        magScale: double.parse(_controllers['magScale']!.text.trim()),
        heightMeters: double.parse(_controllers['heightMeters']!.text.trim()),
        isMale: _isMale,
        stepModel: draft.stepModel,
      );
    });

    final needsWarmup = context.read<SensorService>().updateConfig(draft);
    if (!needsWarmup && context.mounted) {
      SettingsFieldUtils.showToast(context, 'Settings applied instantly');
    }

    Navigator.of(context).pop();
  }

  void _initControllers() {
    void add(String k, dynamic v) =>
        _controllers[k] = TextEditingController(text: v.toString());

    add('pollingIntervalMs', draft.pollingIntervalMs);
    add('userInterfaceUpdateIntervalMs', draft.userInterfaceUpdateIntervalMs);
    add('detectedLabelDuration', draft.detectedLabelDuration);
    add('warmUpDurationMs', draft.warmUpDurationMs);
    add('minStepGapMs', draft.minStepGapMs);
    add('startVectorSize', draft.startVectorSize);
    add('peakVectorSize', draft.peakVectorSize);
    add('endVectorSize', draft.endVectorSize);
    add('meanAbsK', draft.accMeanKConstant);
    add('maxWindowSize', draft.maxWindowSize);
    add('lowPassFilterOrder', draft.lowPassFilterOrder);
    add('lowPassFilterCutoffFreq', draft.lowPassFilterCutoffFreq);
    add('highPassFilterOrder', draft.highPassFilterOrder);
    add('highPassFilterCutoffFreq', draft.highPassFilterCutoffFreq);
    add('accThreshold', draft.accThreshold);
    add('gyroThreshold', draft.gyroThreshold);
    add('accScale', draft.accScale);
    add('gyroScale', draft.gyroScale);
    add('magScale', draft.magScale);
    add('heightMeters', draft.heightMeters.toStringAsFixed(2));
  }
}
