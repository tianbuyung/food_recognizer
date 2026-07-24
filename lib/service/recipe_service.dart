import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:food_recognizer/model/recipe.dart';

/// Akses ke MealDB API (gratis, tanpa API key).
///
/// Endpoint yang dipakai: **Search Meal by Name** — sudah mengembalikan detail
/// lengkap (bahan + langkah), jadi tak perlu lookup-by-id terpisah.
class RecipeService {
  /// [client] bisa diganti saat test (mock HTTP).
  RecipeService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _base = 'https://www.themealdb.com/api/json/v1/1';

  /// Mencari resep berdasarkan [name] (mis. nama makanan hasil prediksi).
  ///
  /// Mengembalikan list resep (bisa kosong bila MealDB tak punya). Melempar
  /// [Exception] bila jaringan/HTTP gagal.
  Future<List<Recipe>> searchByName(String name) async {
    final uri = Uri.parse(
      '$_base/search.php?s=${Uri.encodeQueryComponent(name)}',
    );
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('MealDB gagal (HTTP ${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    // "meals" bernilai null bila tidak ada hasil.
    final meals = data['meals'] as List<dynamic>?;
    if (meals == null) return const [];

    return meals
        .map((m) => Recipe.fromJson(m as Map<String, dynamic>))
        .toList();
  }
}
