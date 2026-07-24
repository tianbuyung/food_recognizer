// Test untuk fitur nutrisi Gemini (Kriteria 3 Advanced).
//
// Memakai http MockClient — TIDAK memanggil Gemini sungguhan (tak perlu API key
// & tak kena kuota). Respons Gemini dipalsukan.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:food_recognizer/controller/nutrition_controller.dart';
import 'package:food_recognizer/model/nutrition.dart';
import 'package:food_recognizer/service/nutrition_service.dart';

/// Respons Gemini yang valid: candidates[0].content.parts[0].text = JSON string.
String _geminiResponse() => jsonEncode({
  'candidates': [
    {
      'content': {
        'parts': [
          {
            'text': jsonEncode({
              'calories': 400,
              'carbohydrates': 50,
              'fat': 14,
              'fiber': 3,
              'protein': 12,
            }),
          },
        ],
      },
    },
  ],
});

void main() {
  group('Nutrition.fromJson', () {
    test('mengurai 5 angka gizi', () {
      final n = Nutrition.fromJson({
        'calories': 400,
        'carbohydrates': 50,
        'fat': 14,
        'fiber': 3,
        'protein': 12,
      });
      expect(n.calories, 400);
      expect(n.protein, 12);
    });

    test('field hilang → 0', () {
      final n = Nutrition.fromJson({'calories': 100});
      expect(n.calories, 100);
      expect(n.fat, 0);
    });
  });

  group('NutritionService', () {
    test('mengembalikan Nutrition saat Gemini sukses', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'generativelanguage.googleapis.com');
        expect(request.url.queryParameters['key'], 'KEY123');
        return http.Response(_geminiResponse(), 200);
      });
      final service = NutritionService(apiKey: 'KEY123', client: client);

      final n = await service.fetchNutrition('Nasi lemak');

      expect(n.calories, 400);
      expect(n.carbohydrates, 50);
    });

    test('melempar MissingApiKeyException saat key kosong', () async {
      final service = NutritionService(apiKey: '');
      expect(
        () => service.fetchNutrition('x'),
        throwsA(isA<MissingApiKeyException>()),
      );
    });

    test(
      'melempar MissingApiKeyException saat key masih placeholder',
      () async {
        final service = NutritionService(apiKey: 'YOUR_GEMINI_API_KEY_HERE');
        expect(
          () => service.fetchNutrition('x'),
          throwsA(isA<MissingApiKeyException>()),
        );
      },
    );

    test('melempar saat HTTP non-200 (mis. 429 kuota habis)', () async {
      final client = MockClient((_) async => http.Response('quota', 429));
      final service = NutritionService(apiKey: 'KEY123', client: client);
      expect(() => service.fetchNutrition('x'), throwsException);
    });
  });

  group('NutritionController', () {
    test('status done + isi nutrition saat sukses', () async {
      final client = MockClient(
        (_) async => http.Response(_geminiResponse(), 200),
      );
      final controller = NutritionController(
        service: NutritionService(apiKey: 'KEY123', client: client),
      );

      await controller.fetch('Nasi lemak');

      expect(controller.status, NutritionStatus.done);
      expect(controller.nutrition?.calories, 400);
    });

    test('status error + pesan saat key belum diatur', () async {
      final controller = NutritionController(
        service: NutritionService(apiKey: ''),
      );

      await controller.fetch('x');

      expect(controller.status, NutritionStatus.error);
      expect(controller.errorMessage, contains('API key'));
    });
  });
}
