import 'package:flutter/material.dart';

class SettingsFieldUtils {
  const SettingsFieldUtils._();

  static Widget intField({
    required TextEditingController controller,
    required String label,
  }) =>
      TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        validator: (v) =>
            int.tryParse(v ?? '') == null ? 'Enter an integer' : null,
      );

  static Widget doubleField({
    required TextEditingController controller,
    required String label,
    bool requiresPositive = false,
  }) =>
      TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true, signed: false),
        validator: (v) {
          final val = double.tryParse(v ?? '');
          if (val == null) return 'Enter a number';
          if (requiresPositive && val <= 0) return 'Enter a positive number';
          return null;
        },
      );

  static Widget tripleRow(List<Widget> children) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: children[i]),
            ]
          ],
        ),
      );

  static void showToast(BuildContext context, String message) {
    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 100,
        left: MediaQuery.of(context).size.width * 0.1,
        width: MediaQuery.of(context).size.width * 0.8,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(message,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2)).then((_) => entry.remove());
  }
}
