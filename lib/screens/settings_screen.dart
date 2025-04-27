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
  late bool _isMale;

  @override
  void initState() {
    super.initState();
    final current = context.read<SensorService>().currentConfig;
    draft = current;
    _isMale = draft.isMale;
    _initControllers();
  }

  void _initControllers() {
    _controllers['pollingIntervalMs'] =
        TextEditingController(text: draft.pollingIntervalMs.toString());
    _controllers['userInterfaceUpdateIntervalMs'] = TextEditingController(
        text: draft.userInterfaceUpdateIntervalMs.toString());
    _controllers['detectedLabelDuration'] =
        TextEditingController(text: draft.detectedLabelDuration.toString());
    _controllers['warmUpDurationMs'] =
        TextEditingController(text: draft.warmUpDurationMs.toString());
    _controllers['minStepGapMs'] =
        TextEditingController(text: draft.minStepGapMs.toString());
    _controllers['startVectorSize'] =
        TextEditingController(text: draft.startVectorSize.toString());
    _controllers['peakVectorSize'] =
        TextEditingController(text: draft.peakVectorSize.toString());
    _controllers['endVectorSize'] =
        TextEditingController(text: draft.endVectorSize.toString());
    _controllers['peakDiffK'] =
        TextEditingController(text: draft.weinbergKPowFactor.toString());
    _controllers['meanAbsK'] =
        TextEditingController(text: draft.accMeanKConstant.toString());
    _controllers['maxWindowSize'] =
        TextEditingController(text: draft.maxWindowSize.toString());
    _controllers['filterOrder'] =
        TextEditingController(text: draft.filterOrder.toString());
    _controllers['filterCutoffFreq'] =
        TextEditingController(text: draft.filterCutoffFreq.toString());
    _controllers['accThreshold'] =
        TextEditingController(text: draft.accThreshold.toString());
    _controllers['gyroThreshold'] =
        TextEditingController(text: draft.gyroThreshold.toString());
    _controllers['accScale'] =
        TextEditingController(text: draft.accScale.toString());
    _controllers['gyroScale'] =
        TextEditingController(text: draft.gyroScale.toString());
    _controllers['magScale'] =
        TextEditingController(text: draft.magScale.toString());
    _controllers['heightMeters'] =
        TextEditingController(text: draft.heightMeters.toStringAsFixed(2));
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
            const _SectionHeader('Sampling & UI'),
            _intField('Polling interval (ms)', 'pollingIntervalMs'),
            _intField(
                'UI update interval (ms)', 'userInterfaceUpdateIntervalMs'),
            _intField('Detected label flash (ms)', 'detectedLabelDuration'),
            SwitchListTile(
              title: const Text('Use system default interval'),
              value: draft.useSystemDefaultInterval,
              onChanged: (val) => setState(
                  () => draft = draft.copyWith(useSystemDefaultInterval: val)),
            ),
            const _SectionHeader('Warm-up'),
            SwitchListTile(
              title: const Text('Wait for sensors to warm up'),
              value: draft.warmUpSensors,
              onChanged: (val) =>
                  setState(() => draft = draft.copyWith(warmUpSensors: val)),
            ),
            _intField('Warm-up duration (ms)', 'warmUpDurationMs'),
            const _SectionHeader('Step Detection'),
            _intField('Min Step Gap (ms)', 'minStepGapMs'),
            _tripleRow([
              _intFieldMini('Start vector', 'startVectorSize'),
              _intFieldMini('Peak vector', 'peakVectorSize'),
              _intFieldMini('End vector', 'endVectorSize'),
            ]),
            const _SectionHeader('Step-length Model'),
            DropdownButtonFormField<StepModel>(
              decoration: const InputDecoration(labelText: 'Model'),
              value: draft.stepModel,
              items: const [
                DropdownMenuItem(
                    value: StepModel.staticHeightAndGender,
                    child: Text('Static (height)')),
                DropdownMenuItem(
                    value: StepModel.weinbergMethod,
                    child: Text('Peak Δa (eq 3)')),
                DropdownMenuItem(
                    value: StepModel.meanAbs, child: Text('Mean |a| (eq 4)')),
              ],
              onChanged: (m) =>
                  setState(() => draft = draft.copyWith(stepModel: m)),
            ),
            if (draft.stepModel == StepModel.weinbergMethod)
              _doubleField('k2 (peak-diff scale)', 'peakDiffK',
                  requiresPositive: true),
            if (draft.stepModel == StepModel.meanAbs)
              _doubleField('k3 (mean-abs scale)', 'meanAbsK',
                  requiresPositive: true),
            const _SectionHeader('Filters'),
            Row(
              children: [
                Expanded(
                    child: _intField(
                        'Running-mean window (samples)', 'maxWindowSize')),
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: () => _showInfoBox(
                      context,
                      'Lowpass Filter Settings',
                      'Filter Order: Typically 2-4 for basic smoothing.\nCutoff Frequency: 2-4 Hz works well for normal walking.\nA lower cutoff removes more noise but can delay detection. Higher order filters are sharper but heavier.'),
                ),
              ],
            ),
            _intField('Butterworth order', 'filterOrder'),
            _doubleField('Cut-off frequency (Hz)', 'filterCutoffFreq'),
            const _SectionHeader('Thresholds'),
            _doubleField('Accelerometer threshold', 'accThreshold'),
            _doubleField('Gyroscope threshold', 'gyroThreshold'),
            const _SectionHeader('Scaling Factors'),
            _tripleRow([
              _doubleFieldMini('Acc', 'accScale', requiresPositive: true),
              _doubleFieldMini('Gyro', 'gyroScale', requiresPositive: true),
              _doubleFieldMini('Mag', 'magScale', requiresPositive: true),
            ]),
            const _SectionHeader('User Details'),
            _doubleField('Height (m)', 'heightMeters', requiresPositive: true),
            DropdownButtonFormField<bool>(
              decoration: const InputDecoration(labelText: 'Gender'),
              value: _isMale,
              items: const [
                DropdownMenuItem(value: true, child: Text('Male')),
                DropdownMenuItem(value: false, child: Text('Female')),
              ],
              onChanged: (val) => setState(() => _isMale = val ?? true),
            ),
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

  void _showInfoBox(BuildContext context, String title, String text) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
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
        weinbergKPowFactor:
            double.parse(_controllers['peakDiffK']!.text.trim()),
        accMeanKConstant: double.parse(_controllers['meanAbsK']!.text.trim()),
        maxWindowSize: int.parse(_controllers['maxWindowSize']!.text.trim()),
        filterOrder: int.parse(_controllers['filterOrder']!.text.trim()),
        filterCutoffFreq:
            double.parse(_controllers['filterCutoffFreq']!.text.trim()),
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

    final didWarmup = context.read<SensorService>().updateConfig(draft);

    if (!didWarmup && context.mounted) {
      _showToast(context, 'Settings applied instantly');
    }

    Navigator.of(context).pop();
  }

  void _showToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: MediaQuery.of(context).size.width * 0.25,
        width: MediaQuery.of(context).size.width * 0.5,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2))
        .then((_) => overlayEntry.remove());
  }

  Widget _intField(String label, String key) => TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        validator: (v) =>
            int.tryParse(v ?? '') == null ? 'Enter an integer' : null,
      );

  Widget _intFieldMini(String label, String key) =>
      Expanded(child: _intField(label, key));

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
