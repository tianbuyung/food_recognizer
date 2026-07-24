import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:food_recognizer/model/nutrition.dart';

/// Dilempar saat GEMINI_API_KEY belum diisi di file `.env`.
class MissingApiKeyException implements Exception {
  const MissingApiKeyException();
  @override
  String toString() => 'GEMINI_API_KEY belum diisi di file .env.';
}

/// Mengambil estimasi nutrisi makanan dari **Gemini API** (REST).
///
/// Memakai *structured output* (responseSchema) agar Gemini mengembalikan JSON
/// dengan 5 angka gizi — bukan teks bebas yang harus di-parse manual.
///
/// Konfigurasi (system instruction + prompt) mengikuti tips resmi Dicoding.
class NutritionService {
  // _apiKey privat → named param tak boleh privat, jadi assign eksplisit.
  NutritionService({required String apiKey, http.Client? client})
    // ignore: prefer_initializing_formals
    : _apiKey = apiKey,
      _client = client ?? http.Client();

  final String _apiKey;
  final http.Client _client;

  // 'gemini-flash-latest' = alias ke model flash stabil terbaru. Dipilih agar
  // tetap tersedia untuk key/project baru (mis. key reviewer) — model versi
  // spesifik seperti gemini-2.5-flash bisa "not available to new users".
  static const _model = 'gemini-flash-latest';
  static const _host = 'generativelanguage.googleapis.com';

  static const _systemInstruction =
      'Saya adalah suatu mesin yang mampu mengidentifikasi nutrisi atau '
      'kandungan gizi pada makanan layaknya uji laboratorium makanan. Hal yang '
      'bisa diidentifikasi adalah kalori, karbohidrat, lemak, serat, dan protein '
      'pada makanan untuk satu porsi. Kalori dalam kkal; karbohidrat, lemak, '
      'serat, dan protein dalam gram.';

  /// Skema output: objek 5 angka. Gemini dijamin mengembalikan bentuk ini.
  static const Map<String, dynamic> _responseSchema = {
    'type': 'OBJECT',
    'properties': {
      'calories': {'type': 'NUMBER'},
      'carbohydrates': {'type': 'NUMBER'},
      'fat': {'type': 'NUMBER'},
      'fiber': {'type': 'NUMBER'},
      'protein': {'type': 'NUMBER'},
    },
    'required': ['calories', 'carbohydrates', 'fat', 'fiber', 'protein'],
  };

  /// Estimasi nutrisi untuk [foodName] (nama makanan hasil prediksi).
  Future<Nutrition> fetchNutrition(String foodName) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw const MissingApiKeyException();
    }

    final uri = Uri.https(_host, '/v1beta/models/$_model:generateContent', {
      'key': _apiKey,
    });

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': _systemInstruction},
        ],
      },
      'contents': [
        {
          'parts': [
            {'text': 'Nama makanannya adalah $foodName.'},
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': _responseSchema,
      },
    });

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini gagal (HTTP ${response.statusCode}).');
    }

    // Struktur respons Gemini: candidates[0].content.parts[0].text = JSON string.
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini tidak mengembalikan hasil.');
    }
    final parts =
        ((candidates.first as Map)['content'] as Map)['parts'] as List<dynamic>;
    final text = (parts.first as Map)['text'] as String;

    return Nutrition.fromJson(jsonDecode(text) as Map<String, dynamic>);
  }
}
