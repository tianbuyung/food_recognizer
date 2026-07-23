import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:food_recognizer/controller/home_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // context.read: ambil controller TANPA ikut rebuild saat state-nya berubah.
    // Cocok dipakai di dalam callback (mis. onPressed), bukan untuk menampilkan
    // data yang berubah — untuk itu nanti pakai context.watch / Consumer.
    final controller = context.read<HomeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Food Recognizer')),
      // SingleChildScrollView mencegah overflow di layar kecil/keyboard muncul.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
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
              const SizedBox(height: 24),
              FilledButton.icon(
                // Placeholder: alur ambil gambar + inferensi ML menyusul.
                onPressed: () => controller.goToResultPage(context),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Ambil Gambar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
