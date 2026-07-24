import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
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

/// Pembungkus tipis di atas package `image_picker`, `permission_handler`, dan
/// `image_cropper`.
///
/// Semua urusan "dunia luar" (dialog sistem, izin, layar crop) berhenti di
/// sini, sehingga controller cukup memanggil [pickImage] / [cropImage] tanpa
/// tahu detail platform.
class ImageService {
  /// [picker] & [cropper] bisa diisi saat test untuk menggantikan yang asli.
  ImageService({ImagePicker? picker, ImageCropper? cropper})
    : _picker = picker ?? ImagePicker(),
      _cropper = cropper ?? ImageCropper();

  final ImagePicker _picker;
  final ImageCropper _cropper;

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

  /// Membuka layar crop untuk gambar di [sourcePath], dikunci rasio 1:1.
  ///
  /// Rasio 1:1 dipilih karena model TFLite memakai input 224x224 (persegi) dan
  /// preview app juga 1:1 — jadi hasil crop konsisten ujung ke ujung.
  ///
  /// Mengembalikan [XFile] hasil crop, atau `null` bila user membatalkan crop.
  /// Nilai dikembalikan sebagai [XFile] (bukan [CroppedFile]) agar tipe state
  /// di controller tetap seragam dengan hasil [pickImage].
  Future<XFile?> cropImage(String sourcePath) async {
    final cropped = await _cropper.cropImage(
      sourcePath: sourcePath,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Pangkas Makanan',
          toolbarColor: Colors.green,
          toolbarWidgetColor: Colors.white,
          // Kunci rasio: user hanya bisa geser/zoom, tak bisa ubah bentuk.
          lockAspectRatio: true,
          hideBottomControls: true,
        ),
        IOSUiSettings(
          title: 'Pangkas Makanan',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (cropped == null) return null;
    return XFile(cropped.path);
  }

  /// Membuka halaman Pengaturan aplikasi (untuk kasus izin ditolak permanen).
  Future<bool> openSettings() => openAppSettings();
}
