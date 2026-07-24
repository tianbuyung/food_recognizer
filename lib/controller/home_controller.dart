import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:food_recognizer/service/image_service.dart';
import 'package:food_recognizer/ui/result_page.dart';

/// Controller untuk [HomePage].
///
/// Meng-extends [ChangeNotifier] supaya bisa menyimpan state dan memberi tahu
/// UI lewat [notifyListeners] setiap kali state berubah.
class HomeController extends ChangeNotifier {
  /// [imageService] bisa diganti saat test (dependency injection sederhana).
  HomeController({ImageService? imageService})
    : _imageService = imageService ?? ImageService();

  final ImageService _imageService;

  /// Foto yang sedang dipilih. `null` berarti belum ada foto.
  ///
  /// Disimpan sebagai [XFile] (tipe bawaan image_picker) — bukan `dart:io File`
  /// — supaya lapisan state tetap netral terhadap platform.
  XFile? _selectedImage;
  XFile? get selectedImage => _selectedImage;

  /// Pesan error terakhir yang belum ditampilkan ke user. Dibersihkan UI lewat
  /// [clearError] setelah SnackBar tampil.
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Menandai error terakhir adalah izin yang ditolak permanen, sehingga UI
  /// bisa menawarkan tombol "Buka Pengaturan".
  bool _isPermissionPermanentlyDenied = false;
  bool get isPermissionPermanentlyDenied => _isPermissionPermanentlyDenied;

  /// Mencegah dialog sistem terbuka dua kali kalau tombol ditekan cepat.
  bool _isPicking = false;
  bool get isPicking => _isPicking;

  /// Mengambil foto dari [source] lalu menyimpannya ke [selectedImage].
  Future<void> pickImage(ImageSource source) async {
    if (_isPicking) return;

    _isPicking = true;
    _errorMessage = null;
    _isPermissionPermanentlyDenied = false;
    notifyListeners();

    try {
      final file = await _imageService.pickImage(source);
      // file == null berarti user membatalkan — bukan error, foto lama dibiarkan.
      if (file != null) _selectedImage = file;
    } on CameraPermissionDeniedException catch (e) {
      _errorMessage = e.message;
      _isPermissionPermanentlyDenied = e.isPermanent;
    } on PlatformException catch (e) {
      _errorMessage = e.message ?? 'Gagal mengambil gambar.';
    } finally {
      _isPicking = false;
      notifyListeners();
    }
  }

  /// Dipanggil UI setelah pesan error selesai ditampilkan.
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _isPermissionPermanentlyDenied = false;
    notifyListeners();
  }

  /// Membuka Pengaturan aplikasi agar user bisa mengaktifkan izin manual.
  Future<void> openAppSettingsPage() => _imageService.openSettings();

  /// Pindah ke halaman hasil prediksi. Belum dipakai — akan disambungkan ke
  /// tombol "Analisis" setelah inferensi ML siap (Tahap 2).
  void goToResultPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ResultPage()),
    );
  }
}
