/// Kandungan gizi makanan (hasil estimasi Gemini API).
///
/// Semua nilai gram, kecuali [calories] (kkal). Sesuai kriteria: kalori,
/// karbohidrat, lemak, serat, protein.
class Nutrition {
  const Nutrition({
    required this.calories,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.protein,
  });

  /// Kalori (kkal).
  final double calories;

  /// Karbohidrat (gram).
  final double carbohydrates;

  /// Lemak (gram).
  final double fat;

  /// Serat (gram).
  final double fiber;

  /// Protein (gram).
  final double protein;

  factory Nutrition.fromJson(Map<String, dynamic> json) {
    double num_(Object? v) => (v as num?)?.toDouble() ?? 0;
    return Nutrition(
      calories: num_(json['calories']),
      carbohydrates: num_(json['carbohydrates']),
      fat: num_(json['fat']),
      fiber: num_(json['fiber']),
      protein: num_(json['protein']),
    );
  }
}
