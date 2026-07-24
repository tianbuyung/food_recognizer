import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Halaman kamera live (Kriteria 1 — Advanced).
///
/// Menampilkan preview kamera realtime. Tombol shutter memotret satu frame dan
/// mengembalikannya sebagai [XFile] lewat `Navigator.pop`. Tombol flip berpindah
/// antar kamera (belakang/depan) bila perangkat punya lebih dari satu.
///
/// Izin kamera diasumsikan SUDAH diberikan sebelum halaman ini dibuka (dicek di
/// HomePage lewat `HomeController.ensureCameraReady`), jadi di sini tidak ada
/// lagi urusan izin.
class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

// `with WidgetsBindingObserver` supaya State ini menerima notifikasi siklus
// hidup app (background/foreground). Kamera adalah resource sistem yang harus
// dilepas saat app tidak aktif, lalu dipasang ulang saat kembali — kalau tidak,
// preview bisa freeze/crash saat resume.
class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = const [];
  int _activeIndex = 0;
  CameraController? _controller;
  bool _isTakingPicture = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      // App ke background → lepas kamera.
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Kembali ke foreground → pasang ulang kamera terakhir.
      _initController(_cameras[_activeIndex]);
    }
  }

  /// Cari daftar kamera lalu inisialisasi (utamakan kamera belakang).
  Future<void> _bootstrap() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      if (cameras.isEmpty) {
        setState(() => _error = 'Tidak ada kamera pada perangkat ini.');
        return;
      }
      final backIndex = cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      _cameras = cameras;
      _activeIndex = backIndex >= 0 ? backIndex : 0;
      await _initController(_cameras[_activeIndex]);
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _error = e.description ?? 'Gagal membuka kamera.');
      }
    }
  }

  Future<void> _initController(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false, // hanya butuh foto, tak perlu izin mikrofon.
    );
    _controller = controller;
    try {
      await controller.initialize();
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _error = e.description ?? 'Gagal menyiapkan kamera.');
      }
      return;
    }
    if (mounted) setState(() {});
  }

  /// Berpindah ke kamera berikutnya (belakang ↔ depan).
  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    await _controller?.dispose();
    setState(() {
      _activeIndex = (_activeIndex + 1) % _cameras.length;
      _controller = null; // tampilkan loading sementara kamera baru disiapkan.
    });
    await _initController(_cameras[_activeIndex]);
  }

  /// Memotret satu frame lalu kembalikan sebagai [XFile] ke pemanggil.
  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isTakingPicture) {
      return;
    }
    setState(() => _isTakingPicture = true);
    try {
      final file = await controller.takePicture();
      if (mounted) Navigator.pop(context, file);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _isTakingPicture = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.description ?? 'Gagal memotret.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Kamera Live'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(child: Center(child: CameraPreview(controller))),
        _buildControls(),
      ],
    );
  }

  Widget _buildControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Ruang kiri agar tombol shutter tetap di tengah.
            const SizedBox(width: 56),
            _ShutterButton(isBusy: _isTakingPicture, onTap: _takePicture),
            // Flip kamera — hanya bila ada >1 kamera.
            SizedBox(
              width: 56,
              child: _cameras.length > 1
                  ? IconButton(
                      onPressed: _switchCamera,
                      icon: const Icon(Icons.cameraswitch, color: Colors.white),
                      iconSize: 32,
                      tooltip: 'Ganti kamera',
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol shutter bulat; menampilkan spinner saat sedang memotret.
class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.isBusy, required this.onTap});

  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isBusy ? null : onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.green, width: 4),
        ),
        child: isBusy
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            : const Icon(Icons.camera_alt, color: Colors.green),
      ),
    );
  }
}
