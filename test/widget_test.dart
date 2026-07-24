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

/// Pengganti [ImageService] saat test: tanpa dialog sistem apa pun.
///
/// - [pickImage] mengembalikan [file] atau melempar [error].
/// - [cropImage] mengembalikan [cropped]; bila [cropReturnsNull] `true` ia
///   mengembalikan `null` (meniru user membatalkan crop).
class _FakeImageService extends ImageService {
  _FakeImageService({
    this.file,
    this.cropped,
    this.cropReturnsNull = false,
    this.error,
    this.cameraPermissionError,
  });

  final XFile? file;
  final XFile? cropped;
  final bool cropReturnsNull;
  final Object? error;

  /// Bila diisi, [ensureCameraPermission] melemparnya (meniru izin ditolak).
  final Object? cameraPermissionError;

  @override
  Future<XFile?> pickImage(ImageSource source) async {
    if (error != null) throw error!;
    return file;
  }

  @override
  Future<XFile?> cropImage(String sourcePath) async {
    if (cropReturnsNull) return null;
    // Default: kembalikan file crop; kalau tak diberi, pantulkan path asal.
    return cropped ?? XFile(sourcePath);
  }

  @override
  Future<void> ensureCameraPermission() async {
    if (cameraPermissionError != null) throw cameraPermissionError!;
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
  late XFile fotoCrop;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('food_recognizer_test');
    final file = File('${tempDir.path}/uji.png');
    await file.writeAsBytes(base64Decode(_pngBase64));
    fotoUji = XFile(file.path);

    // File terpisah untuk meniru "hasil crop" yang berbeda dari foto asli.
    final crop = File('${tempDir.path}/uji_crop.png');
    await crop.writeAsBytes(base64Decode(_pngBase64));
    fotoCrop = XFile(crop.path);
  });

  tearDownAll(() async => tempDir.delete(recursive: true));

  testWidgets('HomePage tampil dengan judul & tombol Ambil Gambar', (
    tester,
  ) async {
    await tester.pumpWidget(const FoodRecognizerApp());

    expect(find.text('Food Recognizer'), findsOneWidget);
    expect(find.text('Ambil Gambar'), findsOneWidget);
  });

  testWidgets('bottom sheet menampilkan 3 sumber gambar', (tester) async {
    await tester.pumpWidget(
      _wrap(HomeController(imageService: ImageService())),
    );

    await tester.tap(find.text('Ambil Gambar'));
    await tester.pumpAndSettle();

    expect(find.text('Kamera Live'), findsOneWidget);
    expect(find.text('Kamera Cepat'), findsOneWidget);
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

  testWidgets('hasil crop (bukan foto asli) yang disimpan sebagai preview', (
    tester,
  ) async {
    // pickImage → fotoUji, cropImage → fotoCrop. State harus memakai hasil crop.
    final controller = HomeController(
      imageService: _FakeImageService(file: fotoUji, cropped: fotoCrop),
    );
    await tester.pumpWidget(_wrap(controller));

    await _pickFrom(tester, 'Galeri');

    expect(controller.selectedImage?.path, fotoCrop.path);
    expect(controller.selectedImage?.path, isNot(fotoUji.path));
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('user membatalkan crop: foto asli yang dipakai', (tester) async {
    // cropReturnsNull meniru user menutup layar crop tanpa memangkas.
    final controller = HomeController(
      imageService: _FakeImageService(file: fotoUji, cropReturnsNull: true),
    );
    await tester.pumpWidget(_wrap(controller));

    await _pickFrom(tester, 'Galeri');

    expect(controller.selectedImage?.path, fotoUji.path);
    expect(find.byType(Image), findsOneWidget);
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

    await _pickFrom(tester, 'Kamera Cepat');

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

    await _pickFrom(tester, 'Kamera Cepat');

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Buka Pengaturan'), findsNothing);
  });

  // --- Kamera live (tier Advanced) ---
  //
  // CameraPage butuh plugin `camera` native yang tak tersedia di `flutter test`,
  // jadi jepretan diuji langsung lewat controller (bukan menekan tombol shutter).

  test('onLiveCameraCaptured: jepretan di-crop lalu jadi preview', () async {
    final controller = HomeController(
      imageService: _FakeImageService(cropped: fotoCrop),
    );

    await controller.onLiveCameraCaptured(fotoUji);

    // Hasil crop yang disimpan, bukan frame mentah.
    expect(controller.selectedImage?.path, fotoCrop.path);
  });

  test('onLiveCameraCaptured: batal crop → frame asli dipakai', () async {
    final controller = HomeController(
      imageService: _FakeImageService(cropReturnsNull: true),
    );

    await controller.onLiveCameraCaptured(fotoUji);

    expect(controller.selectedImage?.path, fotoUji.path);
  });

  test('ensureCameraReady: izin diberikan → true, tanpa error', () async {
    final controller = HomeController(imageService: _FakeImageService());

    final ready = await controller.ensureCameraReady();

    expect(ready, isTrue);
    expect(controller.errorMessage, isNull);
  });

  test(
    'ensureCameraReady: izin ditolak permanen → false + error permanen',
    () async {
      final controller = HomeController(
        imageService: _FakeImageService(
          cameraPermissionError: const CameraPermissionDeniedException(
            isPermanent: true,
          ),
        ),
      );

      final ready = await controller.ensureCameraReady();

      expect(ready, isFalse);
      expect(controller.isPermissionPermanentlyDenied, isTrue);
      expect(controller.errorMessage, isNotNull);
    },
  );
}
