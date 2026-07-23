import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Prediksi')),
      body: const Center(
        // Placeholder: nanti diisi foto + nama makanan + confidence,
        // lalu resep (MealDB) & nutrisi (Gemini).
        child: Text('Halaman hasil prediksi belum diisi.'),
      ),
    );
  }
}
