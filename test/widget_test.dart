// Test untuk food_recognizer.
//
// Catatan belajar: [ImageService] sengaja bisa diganti lewat konstruktor
// [HomeController] (dependency injection). Berkat itu, test di bawah bisa
// memakai service palsu dan TIDAK pernah menyentuh kamera/galeri asli —
// plugin platform memang tidak tersedia di lingkungan `flutter test`.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:food_recognizer/controller/home_controller.dart';
import 'package:food_recognizer/main.dart';
import 'package:food_recognizer/service/image_service.dart';
import 'package:food_recognizer/ui/home_page.dart';

/// PNG 1x1 transparan — cukup untuk membuat file gambar sungguhan di disk.
const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQ'
    'DwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

/// Pengganti [ImageService] saat test: mengembalikan [file] atau melempar
/// [error], tanpa dialog sistem apa pun.
class _FakeImageService extends ImageService {
  _FakeImageService({this.file, this.error});

  final XFile? file;
  final Object? error;

  @override
  Future<XFile?> pickImage(ImageSource source) async {
    if (error != null) throw error!;
    return file;
  }
}

/// Membungkus [HomePage] dengan Provider + MaterialApp seperti di aplikasi asli.
Widget _wrap(HomeController controller) {
  return ChangeNotifierProvider<HomeController>.value(
    value: controller,
    child: const MaterialApp(home: HomePage()),
  );
}

/// Menekan tombol lalu memilih satu item di bottom sheet.
Future<void> _pickFrom(WidgetTester tester, String sumber) async {
  await tester.tap(find.text('Ambil Gambar'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(sumber));
  await tester.pumpAndSettle();
}

void main() {
  late Directory tempDir;
  late XFile fotoUji;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('food_recognizer_test');
    final file = File('${tempDir.path}/uji.png');
    await file.writeAsBytes(base64Decode(_pngBase64));
    fotoUji = XFile(file.path);
  });

  tearDownAll(() async => tempDir.delete(recursive: true));

  testWidgets('HomePage tampil dengan judul & tombol Ambil Gambar', (
    tester,
  ) async {
    await tester.pumpWidget(const FoodRecognizerApp());

    expect(find.text('Food Recognizer'), findsOneWidget);
    expect(find.text('Ambil Gambar'), findsOneWidget);
  });

  testWidgets('bottom sheet menampilkan pilihan Kamera & Galeri', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(HomeController(imageService: ImageService())),
    );

    await tester.tap(find.text('Ambil Gambar'));
    await tester.pumpAndSettle();

    expect(find.text('Kamera'), findsOneWidget);
    expect(find.text('Galeri'), findsOneWidget);
  });

  testWidgets('setelah gambar dipilih: preview muncul & tombol berganti', (
    tester,
  ) async {
    final controller = HomeController(
      imageService: _FakeImageService(file: fotoUji),
    );
    await tester.pumpWidget(_wrap(controller));

    // Kondisi awal: belum ada gambar.
    expect(find.byType(Image), findsNothing);
    expect(find.text('Ganti Gambar'), findsNothing);

    await _pickFrom(tester, 'Galeri');

    expect(controller.selectedImage?.path, fotoUji.path);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Ganti Gambar'), findsOneWidget);
    expect(find.text('Analisis'), findsOneWidget);
    expect(find.text('Ambil Gambar'), findsNothing);
  });

  testWidgets('user membatalkan: tidak ada perubahan & tidak ada SnackBar', (
    tester,
  ) async {
    // file: null meniru user menutup galeri tanpa memilih.
    final controller = HomeController(imageService: _FakeImageService());
    await tester.pumpWidget(_wrap(controller));

    await _pickFrom(tester, 'Galeri');

    expect(controller.selectedImage, isNull);
    expect(controller.errorMessage, isNull);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Ambil Gambar'), findsOneWidget);
  });

  testWidgets('izin kamera ditolak permanen: SnackBar + aksi Buka Pengaturan', (
    tester,
  ) async {
    final controller = HomeController(
      imageService: _FakeImageService(
        error: const CameraPermissionDeniedException(isPermanent: true),
      ),
    );
    await tester.pumpWidget(_wrap(controller));

    await _pickFrom(tester, 'Kamera');

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('Izin kamera ditolak permanen. Aktifkan lewat Pengaturan.'),
      findsOneWidget,
    );
    expect(find.text('Buka Pengaturan'), findsOneWidget);
    // Error sudah dibersihkan agar tidak tampil dua kali.
    expect(controller.errorMessage, isNull);
  });

  testWidgets('izin kamera ditolak sementara: SnackBar tanpa aksi', (
    tester,
  ) async {
    final controller = HomeController(
      imageService: _FakeImageService(
        error: const CameraPermissionDeniedException(isPermanent: false),
      ),
    );
    await tester.pumpWidget(_wrap(controller));

    await _pickFrom(tester, 'Kamera');

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Buka Pengaturan'), findsNothing);
  });
}
