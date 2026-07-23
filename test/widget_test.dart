// Smoke test dasar untuk food_recognizer.

import 'package:flutter_test/flutter_test.dart';

import 'package:food_recognizer/main.dart';

void main() {
  testWidgets('HomePage tampil dengan judul & tombol Ambil Gambar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FoodRecognizerApp());

    // Judul aplikasi di AppBar dan teks tombol placeholder harus muncul.
    expect(find.text('Food Recognizer'), findsOneWidget);
    expect(find.text('Ambil Gambar'), findsOneWidget);
  });
}
