import 'package:flutter/foundation.dart';

import 'package:food_recognizer/model/recipe.dart';
import 'package:food_recognizer/service/recipe_service.dart';

/// Status pencarian resep untuk ditampilkan UI.
enum RecipeStatus {
  /// Belum mulai.
  idle,

  /// Sedang mengambil dari MealDB.
  loading,

  /// Selesai, ada hasil.
  done,

  /// Selesai, tapi MealDB tak punya resep untuk makanan ini (wajar — DB terbatas).
  empty,

  /// Gagal (jaringan/HTTP).
  error,
}

/// Controller untuk bagian resep di [ResultPage].
///
/// Memakai [RecipeService] bersama (dari root app via Provider).
class RecipeController extends ChangeNotifier {
  // named param privat tak diizinkan, jadi assign eksplisit satu-satunya cara.
  // ignore: prefer_initializing_formals
  RecipeController({required RecipeService service}) : _service = service;

  final RecipeService _service;

  RecipeStatus _status = RecipeStatus.idle;
  RecipeStatus get status => _status;

  List<Recipe> _recipes = const [];
  List<Recipe> get recipes => _recipes;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Mencari resep untuk [foodName] (nama makanan hasil prediksi).
  Future<void> fetch(String foodName) async {
    _status = RecipeStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _recipes = await _service.searchByName(foodName);
      _status = _recipes.isEmpty ? RecipeStatus.empty : RecipeStatus.done;
    } catch (e) {
      _errorMessage = 'Gagal memuat resep.';
      _status = RecipeStatus.error;
    }
    notifyListeners();
  }
}
