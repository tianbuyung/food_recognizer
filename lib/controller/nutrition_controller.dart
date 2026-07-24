import 'package:flutter/foundation.dart';

import 'package:food_recognizer/model/nutrition.dart';
import 'package:food_recognizer/service/nutrition_service.dart';

/// Status permintaan nutrisi ke Gemini.
enum NutritionStatus { idle, loading, done, error }

/// Controller untuk bagian nutrisi di [ResultPage].
///
/// Memakai [NutritionService] bersama (dari root app via Provider).
class NutritionController extends ChangeNotifier {
  // named param privat tak diizinkan, jadi assign eksplisit satu-satunya cara.
  // ignore: prefer_initializing_formals
  NutritionController({required NutritionService service}) : _service = service;

  final NutritionService _service;

  NutritionStatus _status = NutritionStatus.idle;
  NutritionStatus get status => _status;

  Nutrition? _nutrition;
  Nutrition? get nutrition => _nutrition;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Mengambil estimasi nutrisi untuk [foodName].
  Future<void> fetch(String foodName) async {
    _status = NutritionStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _nutrition = await _service.fetchNutrition(foodName);
      _status = NutritionStatus.done;
    } on MissingApiKeyException {
      _errorMessage = 'API key Gemini belum diatur (.env).';
      _status = NutritionStatus.error;
    } catch (e) {
      _errorMessage = 'Gagal memuat nutrisi.';
      _status = NutritionStatus.error;
    }
    notifyListeners();
  }
}
