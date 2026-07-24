import 'package:flutter/material.dart';

/// Widget reusable untuk menampilkan satu hasil klasifikasi:
/// nama makanan + tingkat keyakinan (confidence) dari model.
class ClassificationItem extends StatelessWidget {
  const ClassificationItem({
    super.key,
    required this.label,
    required this.confidence,
  });

  /// Nama kelas makanan hasil prediksi model.
  final String label;

  /// Skor keyakinan 0.0–1.0 (ditampilkan sebagai persen).
  final double confidence;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.fastfood),
      title: Text(label),
      trailing: Text('${(confidence * 100).toStringAsFixed(1)}%'),
    );
  }
}
