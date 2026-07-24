// Test untuk fitur resep MealDB (Kriteria 3 Skilled).
//
// Memakai http MockClient supaya TIDAK memanggil jaringan sungguhan — respons
// MealDB dipalsukan, jadi test cepat & deterministik.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:food_recognizer/controller/recipe_controller.dart';
import 'package:food_recognizer/model/recipe.dart';
import 'package:food_recognizer/service/recipe_service.dart';

/// Satu meal MealDB minimal (dengan 2 bahan terisi + sisanya kosong).
Map<String, dynamic> _meal() => {
  'idMeal': '53051',
  'strMeal': 'Nasi lemak',
  'strCategory': 'Rice',
  'strArea': 'Malaysian',
  'strInstructions': 'Masak nasi dengan santan.',
  'strMealThumb': 'https://example.com/nasi.jpg',
  'strYoutube': '',
  'strIngredient1': 'Rice',
  'strMeasure1': '2 cups',
  'strIngredient2': 'Coconut milk',
  'strMeasure2': '1 cup',
  'strIngredient3': '',
  'strMeasure3': '',
};

void main() {
  group('Recipe.fromJson', () {
    test('mengurai bahan terisi & melewati slot kosong', () {
      final recipe = Recipe.fromJson(_meal());

      expect(recipe.name, 'Nasi lemak');
      expect(recipe.area, 'Malaysian');
      expect(recipe.ingredients.length, 2); // slot ke-3 kosong → dilewati
      expect(recipe.ingredients.first.name, 'Rice');
      expect(recipe.ingredients.first.measure, '2 cups');
      expect(recipe.youtubeUrl, isNull); // string kosong → null
    });
  });

  group('RecipeService.searchByName', () {
    test('mengembalikan daftar resep saat MealDB punya hasil', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'www.themealdb.com');
        expect(request.url.queryParameters['s'], 'Nasi lemak');
        return http.Response(
          jsonEncode({
            'meals': [_meal()],
          }),
          200,
        );
      });
      final service = RecipeService(client: client);

      final recipes = await service.searchByName('Nasi lemak');

      expect(recipes, hasLength(1));
      expect(recipes.first.name, 'Nasi lemak');
    });

    test('mengembalikan list kosong saat meals null', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'meals': null}), 200),
      );
      final service = RecipeService(client: client);

      expect(await service.searchByName('xyz'), isEmpty);
    });

    test('melempar saat HTTP non-200', () async {
      final client = MockClient((_) async => http.Response('err', 500));
      final service = RecipeService(client: client);

      expect(() => service.searchByName('x'), throwsException);
    });
  });

  group('RecipeController', () {
    test('status done + isi recipes saat ada hasil', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'meals': [_meal()],
          }),
          200,
        ),
      );
      final controller = RecipeController(
        service: RecipeService(client: client),
      );

      await controller.fetch('Nasi lemak');

      expect(controller.status, RecipeStatus.done);
      expect(controller.recipes, hasLength(1));
    });

    test('status empty saat MealDB tak punya resep', () async {
      final client = MockClient(
        (_) async => http.Response(jsonEncode({'meals': null}), 200),
      );
      final controller = RecipeController(
        service: RecipeService(client: client),
      );

      await controller.fetch('xyz');

      expect(controller.status, RecipeStatus.empty);
      expect(controller.recipes, isEmpty);
    });

    test('status error saat request gagal', () async {
      final client = MockClient((_) async => http.Response('err', 500));
      final controller = RecipeController(
        service: RecipeService(client: client),
      );

      await controller.fetch('x');

      expect(controller.status, RecipeStatus.error);
      expect(controller.errorMessage, isNotNull);
    });
  });
}
