/// Satu hasil klasifikasi dari model: nama makanan + tingkat keyakinan.
///
/// Class data murni (tanpa logika UI/ML) — dipakai controller & widget untuk
/// menampilkan prediksi.
class Classification {
  const Classification({required this.label, required this.confidence});

  /// Nama kelas makanan (mis. "Nasi Goreng").
  final String label;

  /// Skor keyakinan 0.0–1.0.
  final double confidence;

  /// Persentase untuk ditampilkan (mis. "87.5%").
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  @override
  String toString() => '$label ($confidencePercent)';
}
