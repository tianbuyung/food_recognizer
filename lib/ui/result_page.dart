import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:food_recognizer/controller/nutrition_controller.dart';
import 'package:food_recognizer/controller/recipe_controller.dart';
import 'package:food_recognizer/controller/result_controller.dart';
import 'package:food_recognizer/model/nutrition.dart';
import 'package:food_recognizer/model/recipe.dart';
import 'package:food_recognizer/service/ml_service.dart';
import 'package:food_recognizer/service/nutrition_service.dart';
import 'package:food_recognizer/service/recipe_service.dart';
import 'package:food_recognizer/ui/recipe_detail_page.dart';
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
        const SizedBox(height: 24),
        // Nutrisi dari Gemini (Kriteria 3 Advanced).
        _NutritionSection(foodName: top.label),
        const SizedBox(height: 24),
        // Resep terkait dari MealDB (Kriteria 3 Skilled).
        _RecipeSection(foodName: top.label),
      ],
    );
  }
}

/// Bagian nutrisi: otomatis mengambil estimasi gizi untuk [foodName] via Gemini.
class _NutritionSection extends StatelessWidget {
  const _NutritionSection({required this.foodName});

  final String foodName;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NutritionController>(
      create: (ctx) =>
          NutritionController(service: ctx.read<NutritionService>())
            ..fetch(foodName),
      child: const _NutritionSectionBody(),
    );
  }
}

class _NutritionSectionBody extends StatelessWidget {
  const _NutritionSectionBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NutritionController>();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Nutrisi (perkiraan per porsi)',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        switch (controller.status) {
          NutritionStatus.loading => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
          NutritionStatus.error => Text(
            controller.errorMessage ?? 'Gagal memuat nutrisi.',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          NutritionStatus.done => _NutritionGrid(
            nutrition: controller.nutrition!,
          ),
          NutritionStatus.idle => const SizedBox.shrink(),
        },
      ],
    );
  }
}

/// Menampilkan 5 angka gizi sebagai kartu-kartu kecil.
class _NutritionGrid extends StatelessWidget {
  const _NutritionGrid({required this.nutrition});

  final Nutrition nutrition;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, String value})>[
      (label: 'Kalori', value: '${nutrition.calories.round()} kkal'),
      (label: 'Karbohidrat', value: '${nutrition.carbohydrates.round()} g'),
      (label: 'Lemak', value: '${nutrition.fat.round()} g'),
      (label: 'Serat', value: '${nutrition.fiber.round()} g'),
      (label: 'Protein', value: '${nutrition.protein.round()} g'),
    ];

    // Wrap = otomatis pindah baris di layar kecil → anti-overflow.
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final it in items) _NutritionChip(item: it)],
    );
  }
}

class _NutritionChip extends StatelessWidget {
  const _NutritionChip({required this.item});

  final ({String label, String value}) item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          Text(
            item.value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bagian resep: otomatis mencari resep untuk [foodName] saat dibuat.
///
/// Membuat [RecipeController] lokal (pakai [RecipeService] bersama dari root).
class _RecipeSection extends StatelessWidget {
  const _RecipeSection({required this.foodName});

  final String foodName;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RecipeController>(
      create: (ctx) =>
          RecipeController(service: ctx.read<RecipeService>())..fetch(foodName),
      child: const _RecipeSectionBody(),
    );
  }
}

class _RecipeSectionBody extends StatelessWidget {
  const _RecipeSectionBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RecipeController>();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Resep', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        switch (controller.status) {
          RecipeStatus.loading => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
          RecipeStatus.empty => Text(
            'Belum ada resep untuk makanan ini di MealDB.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          RecipeStatus.error => Text(
            controller.errorMessage ?? 'Gagal memuat resep.',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          RecipeStatus.done => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final r in controller.recipes) _RecipeCard(recipe: r),
            ],
          ),
          RecipeStatus.idle => const SizedBox.shrink(),
        },
      ],
    );
  }
}

/// Kartu resep ringkas; tap → halaman detail.
class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 56,
            height: 56,
            child: recipe.thumbnailUrl.isEmpty
                ? const Icon(Icons.restaurant)
                : Image.network(
                    recipe.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.restaurant),
                  ),
          ),
        ),
        title: Text(recipe.name),
        subtitle: Text('${recipe.area} · ${recipe.category}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeDetailPage(recipe: recipe)),
        ),
      ),
    );
  }
}
