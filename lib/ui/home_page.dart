import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:food_recognizer/controller/home_controller.dart';
import 'package:food_recognizer/ui/camera_page.dart';

/// Tiga cara memasukkan gambar (dipilih lewat bottom sheet).
enum _PickSource {
  /// Kamera live (package `camera`) — preview realtime + jepret.
  liveCamera,

  /// Kamera cepat (package `image_picker`) — buka app kamera bawaan.
  quickCamera,

  /// Galeri (package `image_picker`).
  gallery,
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // context.watch: ikut rebuild setiap controller memanggil notifyListeners(),
    // jadi preview foto otomatis muncul setelah gambar dipilih.
    // (Bandingkan context.read yang dipakai di dalam callback — lihat _pickImage.)
    final controller = context.watch<HomeController>();
    final image = controller.selectedImage;

    return Scaffold(
      appBar: AppBar(title: const Text('Food Recognizer')),
      // SafeArea menghindari notch//home indicator; SingleChildScrollView
      // mencegah overflow di layar kecil (overflow = submission ditolak).
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (image == null)
                const _EmptyPlaceholder()
              else
                _ImagePreview(file: image),
              const SizedBox(height: 24),
              if (image == null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: controller.isPicking
                        ? null
                        : () => _pickImage(context),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Ambil Gambar'),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: controller.isPicking
                            ? null
                            : () => _pickImage(context),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Ganti Gambar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Tooltip(
                        message: 'Inferensi ML menyusul di Tahap 2',
                        child: FilledButton.icon(
                          // Sengaja null: tombol tampil tapi nonaktif sampai
                          // model TFLite siap dipasang.
                          onPressed: null,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Analisis'),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Menampilkan pilihan sumber gambar, lalu menjalankannya.
  Future<void> _pickImage(BuildContext context) async {
    final source = await _showSourceSheet(context);
    if (source == null) return; // user menutup sheet tanpa memilih

    // Setiap `await` berpotensi membuat widget sudah lepas dari tree, sehingga
    // context-nya tidak valid lagi. `context.mounted` adalah penjaga wajibnya.
    if (!context.mounted) return;

    // context.read dipakai di callback: kita hanya butuh memanggil method,
    // tidak perlu widget ini rebuild karenanya.
    final controller = context.read<HomeController>();

    switch (source) {
      case _PickSource.gallery:
        await controller.pickImage(ImageSource.gallery);
      case _PickSource.quickCamera:
        await controller.pickImage(ImageSource.camera);
      case _PickSource.liveCamera:
        await _openLiveCamera(context, controller);
    }

    if (!context.mounted) return;
    _showErrorIfAny(context, controller);
  }

  /// Cek izin → buka [CameraPage] → proses jepretan (crop → preview).
  Future<void> _openLiveCamera(
    BuildContext context,
    HomeController controller,
  ) async {
    final ready = await controller.ensureCameraReady();
    // ready == false berarti izin ditolak; pesan error sudah diset controller
    // dan akan ditampilkan oleh _showErrorIfAny di pemanggil.
    if (!ready || !context.mounted) return;

    final captured = await Navigator.push<XFile>(
      context,
      MaterialPageRoute(builder: (_) => const CameraPage()),
    );
    if (captured == null || !context.mounted) return;

    await controller.onLiveCameraCaptured(captured);
  }

  /// Menampilkan SnackBar bila controller punya pesan error yang belum tampil.
  void _showErrorIfAny(BuildContext context, HomeController controller) {
    final message = controller.errorMessage;
    if (message == null) return;

    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        action: controller.isPermissionPermanentlyDenied
            ? SnackBarAction(
                label: 'Buka Pengaturan',
                textColor: colorScheme.onError,
                onPressed: controller.openAppSettingsPage,
              )
            : null,
      ),
    );
    controller.clearError();
  }

  /// Sheet dari bawah berisi 3 sumber gambar.
  /// Mengembalikan `null` bila user menutupnya tanpa memilih.
  Future<_PickSource?> _showSourceSheet(BuildContext context) {
    return showModalBottomSheet<_PickSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Kamera Live'),
              subtitle: const Text('Preview realtime, lalu jepret'),
              // Navigator.pop dengan nilai: nilai itu jadi hasil Future di atas.
              onTap: () => Navigator.pop(sheetContext, _PickSource.liveCamera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Kamera Cepat'),
              subtitle: const Text('Buka aplikasi kamera bawaan'),
              onTap: () => Navigator.pop(sheetContext, _PickSource.quickCamera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              subtitle: const Text('Pilih foto yang sudah ada'),
              onTap: () => Navigator.pop(sheetContext, _PickSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tampilan saat belum ada foto dipilih.
class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.restaurant_menu,
          size: 96,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        const Text(
          'Ambil foto makanan untuk dikenali.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}

/// Pratinjau foto terpilih dalam kotak 1:1 bersudut membulat.
///
/// AspectRatio membuat tinggi selalu mengikuti lebar layar, sehingga tidak
/// pernah overflow di layar kecil. Rasio 1:1 juga sejalan dengan input model
/// yang 224x224.
class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        // XFile disimpan di state agar netral platform; baru di titik render
        // ini ia diubah jadi dart:io File (target submission: Android & iOS).
        child: Image.file(File(file.path), fit: BoxFit.cover),
      ),
    );
  }
}
