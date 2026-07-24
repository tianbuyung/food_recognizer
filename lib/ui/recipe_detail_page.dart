import 'package:flutter/material.dart';

import 'package:food_recognizer/model/recipe.dart';

/// Halaman detail satu resep: foto, kategori/area, bahan, langkah.
class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(recipe.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Foto resep, kotak membulat anti-overflow.
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: recipe.thumbnailUrl.isEmpty
                    ? Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                      )
                    : Image.network(
                        recipe.thumbnailUrl,
                        fit: BoxFit.cover,
                        // Placeholder saat memuat / gagal — jangan sampai error.
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                            ? child
                            : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (_, _, _) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image, size: 48),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              recipe.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Chip kategori & asal.
            Wrap(
              spacing: 8,
              children: [
                if (recipe.category != '-') Chip(label: Text(recipe.category)),
                if (recipe.area != '-') Chip(label: Text(recipe.area)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Bahan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final ing in recipe.ingredients)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(
                      child: Text(
                        ing.measure.isEmpty
                            ? ing.name
                            : '${ing.measure} ${ing.name}',
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Text('Langkah', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              recipe.instructions.isEmpty
                  ? 'Tidak ada langkah.'
                  : recipe.instructions,
              style: const TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
