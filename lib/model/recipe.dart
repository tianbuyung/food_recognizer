/// Satu bahan resep: nama + takaran.
class RecipeIngredient {
  const RecipeIngredient({required this.name, required this.measure});

  final String name;
  final String measure;
}

/// Resep dari MealDB API.
///
/// MealDB mengembalikan bahan sebagai 20 pasang field terpisah
/// (`strIngredient1..20` + `strMeasure1..20`); [fromJson] merapikannya menjadi
/// satu list [ingredients], membuang yang kosong.
class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    required this.category,
    required this.area,
    required this.instructions,
    required this.ingredients,
    this.youtubeUrl,
  });

  final String id;
  final String name;
  final String thumbnailUrl;
  final String category;
  final String area;
  final String instructions;
  final List<RecipeIngredient> ingredients;
  final String? youtubeUrl;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final ingredients = <RecipeIngredient>[];
    // MealDB: strIngredient1..strIngredient20 (+ strMeasure...).
    for (var i = 1; i <= 20; i++) {
      final name = (json['strIngredient$i'] as String?)?.trim() ?? '';
      final measure = (json['strMeasure$i'] as String?)?.trim() ?? '';
      // Slot kosong ditandai "" atau null → dilewati.
      if (name.isEmpty) continue;
      ingredients.add(RecipeIngredient(name: name, measure: measure));
    }

    final youtube = (json['strYoutube'] as String?)?.trim();

    return Recipe(
      id: json['idMeal'] as String? ?? '',
      name: json['strMeal'] as String? ?? '(tanpa nama)',
      thumbnailUrl: json['strMealThumb'] as String? ?? '',
      category: json['strCategory'] as String? ?? '-',
      area: json['strArea'] as String? ?? '-',
      instructions: (json['strInstructions'] as String? ?? '').trim(),
      ingredients: ingredients,
      youtubeUrl: (youtube == null || youtube.isEmpty) ? null : youtube,
    );
  }
}
