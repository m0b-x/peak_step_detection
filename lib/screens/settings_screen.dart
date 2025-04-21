// lib/settings_screen.dart
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

  @override
  void initState() {
    super.initState();
    final current = context.read<SensorService>().currentConfig;
    draft = current;
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
            _intField(
              label: 'Polling interval (ms)',
              initial: draft.pollingIntervalMs,
              onSaved: (v) => draft = draft.copyWith(pollingIntervalMs: v),
            ),
            SwitchListTile(
              title: const Text('Wait for sensors to warm up'),
              value: draft.warmUpSensors,
              onChanged: (val) => setState(
                () => draft = draft.copyWith(warmUpSensors: val),
              ),
            ),
            ListTile(
              title: const Text('Warm-up duration (ms)'),
              subtitle: Text('${draft.warmUpDurationMs} ms'),
              trailing: SizedBox(
                width: 100,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(hintText: '${draft.warmUpDurationMs}'),
                  onSubmitted: (val) {
                    final parsed = int.tryParse(val);
                    if (parsed != null) {
                      setState(() {
                        draft = draft.copyWith(warmUpDurationMs: parsed);
                      });
                    }
                  },
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('Use system default interval'),
              value: draft.useSystemDefaultInterval,
              onChanged: (val) => setState(
                () => draft = draft.copyWith(useSystemDefaultInterval: val),
              ),
            ),
            const _SectionHeader('Filters'),
            _intField(
              label: 'Butterworth order',
              initial: draft.filterOrder,
              onSaved: (v) => draft = draft.copyWith(filterOrder: v),
            ),
            _doubleField(
              label: 'Cut‑off freq',
              initial: draft.filterCutoffFreq,
              onSaved: (v) => draft = draft.copyWith(filterCutoffFreq: v),
            ),
            const _SectionHeader('Thresholds'),
            _doubleField(
              label: 'Acc threshold',
              initial: draft.accThreshold,
              onSaved: (v) => draft = draft.copyWith(accThreshold: v),
            ),
            _doubleField(
              label: 'Gyro threshold',
              initial: draft.gyroThreshold,
              onSaved: (v) => draft = draft.copyWith(gyroThreshold: v),
            ),
            const _SectionHeader('Scaling factors'),
            _tripleRow(
              children: [
                _doubleFieldMini(
                  label: 'Acc',
                  initial: draft.accelerometerScale,
                  onSaved: (v) => draft = draft.copyWith(accScale: v),
                ),
                _doubleFieldMini(
                  label: 'Gyro',
                  initial: draft.gyroScale,
                  onSaved: (v) => draft = draft.copyWith(gyroScale: v),
                ),
                _doubleFieldMini(
                  label: 'Mag',
                  initial: draft.magScale,
                  onSaved: (v) => draft = draft.copyWith(magScale: v),
                ),
              ],
            ),
            const _SectionHeader('Step lengths (m)'),
            _tripleRow(
              children: [
                _doubleFieldMini(
                  label: 'Short',
                  initial: draft.shortStep,
                  onSaved: (v) => draft = draft.copyWith(shortStep: v),
                ),
                _doubleFieldMini(
                  label: 'Medium',
                  initial: draft.mediumStep,
                  onSaved: (v) => draft = draft.copyWith(mediumStep: v),
                ),
                _doubleFieldMini(
                  label: 'Long',
                  initial: draft.longStep,
                  onSaved: (v) => draft = draft.copyWith(longStep: v),
                ),
              ],
            ),
            const _SectionHeader('Step thresholds'),
            _doubleField(
              label: 'Big‑step threshold',
              initial: draft.bigStepThreshold,
              onSaved: (v) => draft = draft.copyWith(bigStepThreshold: v),
            ),
            _doubleField(
              label: 'Medium‑step threshold',
              initial: draft.mediumStepThreshold,
              onSaved: (v) => draft = draft.copyWith(mediumStepThreshold: v),
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

  /* ───────────────────── helpers ───────────────────── */

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // push new config into service
    context.read<SensorService>().updateConfig(draft);
    Navigator.of(context).pop();
  }

  Widget _intField({
    required String label,
    required int initial,
    required void Function(int) onSaved,
  }) =>
      TextFormField(
        initialValue: initial.toString(),
        decoration: InputDecoration(
          labelText: label,
          hintText: initial.toString(),
        ),
        keyboardType: TextInputType.number,
        validator: (v) =>
            int.tryParse(v ?? '') == null ? 'Enter integer' : null,
        onSaved: (v) => onSaved(int.parse(v!)),
      );

  Widget _doubleField({
    required String label,
    required double initial,
    required void Function(double) onSaved,
  }) =>
      TextFormField(
        initialValue: initial.toString(),
        decoration: InputDecoration(
          labelText: label,
          hintText: initial.toString(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) =>
            double.tryParse(v ?? '') == null ? 'Enter number' : null,
        onSaved: (v) => onSaved(double.parse(v!)),
      );

  Widget _doubleFieldMini({
    required String label,
    required double initial,
    required void Function(double) onSaved,
  }) =>
      Expanded(
        child: _doubleField(label: label, initial: initial, onSaved: onSaved),
      );

  Widget _tripleRow({required List<Widget> children}) => Padding(
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
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(fontWeight: FontWeight.bold)),
      );
}
