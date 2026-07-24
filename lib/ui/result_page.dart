import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:food_recognizer/controller/result_controller.dart';
import 'package:food_recognizer/service/ml_service.dart';
import 'package:food_recognizer/widget/classification_item.dart';

/// Halaman hasil prediksi: foto yang dianalisis + nama makanan + confidence.
///
/// Membuat [ResultController] lokal (memakai [MlService] bersama dari root) dan
/// langsung memulai analisis begitu halaman dibuka.
class ResultPage extends StatelessWidget {
  const ResultPage({super.key, required this.imagePath});

  /// Path gambar (hasil crop/jepret) yang akan diklasifikasi.
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ResultController>(
      // `..analyze` memicu proses sekali saat controller dibuat.
      create: (ctx) =>
          ResultController(mlService: ctx.read<MlService>())
            ..analyze(imagePath),
      child: Scaffold(
        appBar: AppBar(title: const Text('Hasil Prediksi')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ResultImage(imagePath: imagePath),
                const SizedBox(height: 24),
                _AnalysisSection(imagePath: imagePath),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Foto yang dianalisis, kotak 1:1 anti-overflow.
class _ResultImage extends StatelessWidget {
  const _ResultImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(File(imagePath), fit: BoxFit.cover),
      ),
    );
  }
}

/// Bagian yang berubah sesuai status: unduh model / analisis / hasil / error.
class _AnalysisSection extends StatelessWidget {
  const _AnalysisSection({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ResultController>();

    switch (controller.status) {
      case AnalysisStatus.downloadingModel:
        return _Busy(
          message:
              'Mengunduh model AI… ${(controller.downloadProgress * 100).toStringAsFixed(0)}%',
          progress: controller.downloadProgress > 0
              ? controller.downloadProgress
              : null,
        );

      case AnalysisStatus.classifying:
        return const _Busy(message: 'Menganalisis gambar…');

      case AnalysisStatus.error:
        return _ErrorView(
          message: controller.errorMessage ?? 'Terjadi kesalahan.',
          onRetry: () => context.read<ResultController>().analyze(imagePath),
        );

      case AnalysisStatus.done:
        return _Results(controller: controller);

      case AnalysisStatus.idle:
        return const SizedBox.shrink();
    }
  }
}

/// Indikator sibuk (unduh/analisis).
class _Busy extends StatelessWidget {
  const _Busy({required this.message, this.progress});

  final String message;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        if (progress != null)
          LinearProgressIndicator(value: progress)
        else
          const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
      ],
    );
  }
}

/// Tampilan error + tombol coba lagi.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(Icons.error_outline, size: 48, color: colorScheme.error),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Coba Lagi'),
        ),
      ],
    );
  }
}

/// Hasil prediksi: juara ditonjolkan + daftar alternatif.
class _Results extends StatelessWidget {
  const _Results({required this.controller});

  final ResultController controller;

  @override
  Widget build(BuildContext context) {
    final top = controller.topResult;
    if (top == null) {
      return const Text('Tidak ada prediksi.', textAlign: TextAlign.center);
    }

    final theme = Theme.of(context);
    final alternatives = controller.alternatives;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Juara — ditonjolkan.
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Prediksi',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  top.label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keyakinan ${top.confidencePercent}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (alternatives.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Kemungkinan lain', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          // Widget reusable dari Tahap 0.
          for (final c in alternatives)
            ClassificationItem(label: c.label, confidence: c.confidence),
        ],
      ],
    );
  }
}
