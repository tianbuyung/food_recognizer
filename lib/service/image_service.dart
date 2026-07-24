import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Dilempar saat izin kamera tidak diberikan user.
///
/// Dibuat sebagai exception tersendiri (bukan sekadar `return null`) supaya
/// pemanggil bisa membedakan tiga hal: user batal memilih (hasil `null`),
/// izin ditolak (exception ini), dan error platform lain ([PlatformException]).
class CameraPermissionDeniedException implements Exception {
  const CameraPermissionDeniedException({required this.isPermanent});

  /// `true` bila user memilih "jangan tanya lagi" / menolak lewat Pengaturan.
  /// Satu-satunya jalan keluar adalah membuka Pengaturan aplikasi.
  final bool isPermanent;

  String get message => isPermanent
      ? 'Izin kamera ditolak permanen. Aktifkan lewat Pengaturan.'
      : 'Izin kamera dibutuhkan untuk memotret makanan.';

  @override
  String toString() => 'CameraPermissionDeniedException: $message';
}

/// Pembungkus tipis di atas package `image_picker` + `permission_handler`.
///
/// Semua urusan "dunia luar" (dialog sistem, izin) berhenti di sini, sehingga
/// controller cukup memanggil [pickImage] tanpa tahu detail platform.
class ImageService {
  /// [picker] bisa diisi saat unit test untuk menggantikan picker asli.
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Izin runtime hanya ada di Android & iOS. Di web/desktop, plugin
  /// permission_handler tidak tersedia sehingga pemanggilannya justru error —
  /// karena itu langkah izin dilewati di platform tersebut.
  bool get _needsRuntimePermission =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Membuka kamera atau galeri sesuai [source].
  ///
  /// Mengembalikan `null` bila user membatalkan (bukan error).
  /// Melempar [CameraPermissionDeniedException] bila izin kamera ditolak.
  Future<XFile?> pickImage(ImageSource source) async {
    if (source == ImageSource.camera && _needsRuntimePermission) {
      await _ensureCameraPermission();
    }
    return _picker.pickImage(source: source);
  }

  Future<void> _ensureCameraPermission() async {
    // request() mengembalikan status yang sudah ada bila izin pernah diberikan,
    // jadi dialog sistem tidak muncul berulang kali.
    final status = await Permission.camera.request();
    if (status.isGranted || status.isLimited) return;

    throw CameraPermissionDeniedException(
      isPermanent: status.isPermanentlyDenied || status.isRestricted,
    );
  }

  /// Membuka halaman Pengaturan aplikasi (untuk kasus izin ditolak permanen).
  Future<bool> openSettings() => openAppSettings();
}
