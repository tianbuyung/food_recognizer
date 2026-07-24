import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:food_recognizer/service/image_service.dart';

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

  /// Mencegah proses ambil/proses gambar berjalan dobel.
  bool _isPicking = false;
  bool get isPicking => _isPicking;

  /// Ambil foto dari [source] (kamera cepat `image_picker` / galeri), lalu crop.
  Future<void> pickImage(ImageSource source) async {
    if (_isPicking) return;
    _beginPicking();
    try {
      final picked = await _imageService.pickImage(source);
      // picked == null berarti user membatalkan — bukan error, foto lama dibiarkan.
      if (picked != null) await _applyImage(picked);
    } on CameraPermissionDeniedException catch (e) {
      _setPermissionError(e);
    } on PlatformException catch (e) {
      _errorMessage = e.message ?? 'Gagal mengambil gambar.';
    } finally {
      _endPicking();
    }
  }

  /// Memproses jepretan dari halaman kamera live: crop lalu jadikan preview.
  ///
  /// Izin kamera sudah dipastikan lewat [ensureCameraReady] sebelum halaman
  /// kamera dibuka, jadi di sini tinggal crop seperti sumber gambar lainnya.
  Future<void> onLiveCameraCaptured(XFile captured) async {
    if (_isPicking) return;
    _beginPicking();
    try {
      await _applyImage(captured);
    } on PlatformException catch (e) {
      _errorMessage = e.message ?? 'Gagal memproses gambar.';
    } finally {
      _endPicking();
    }
  }

  /// Memastikan izin kamera sebelum membuka halaman kamera live.
  ///
  /// Mengembalikan `true` bila boleh lanjut; `false` bila ditolak (pesan error
  /// diset agar UI menampilkan SnackBar + aksi "Buka Pengaturan" bila permanen).
  Future<bool> ensureCameraReady() async {
    _errorMessage = null;
    _isPermissionPermanentlyDenied = false;
    try {
      await _imageService.ensureCameraPermission();
      return true;
    } on CameraPermissionDeniedException catch (e) {
      _setPermissionError(e);
      notifyListeners();
      return false;
    }
  }

  /// Crop [picked] (dikunci 1:1); bila user membatalkan crop, pakai foto asli
  /// supaya alur tidak buntu. Dipakai bersama oleh semua sumber gambar.
  Future<void> _applyImage(XFile picked) async {
    final cropped = await _imageService.cropImage(picked.path);
    _selectedImage = cropped ?? picked;
  }

  void _beginPicking() {
    _isPicking = true;
    _errorMessage = null;
    _isPermissionPermanentlyDenied = false;
    notifyListeners();
  }

  void _endPicking() {
    _isPicking = false;
    notifyListeners();
  }

  void _setPermissionError(CameraPermissionDeniedException e) {
    _errorMessage = e.message;
    _isPermissionPermanentlyDenied = e.isPermanent;
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
}
