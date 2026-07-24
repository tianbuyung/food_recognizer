import 'package:flutter/material.dart';

import 'package:food_recognizer/ui/result_page.dart';

/// Controller untuk [HomePage].
///
/// Meng-extends [ChangeNotifier] supaya bisa menyimpan state dan memberi tahu
/// UI lewat [notifyListeners] setiap kali state berubah. Untuk sekarang baru
/// berisi navigasi; state gambar terpilih & hasil inferensi ML menyusul.
class HomeController extends ChangeNotifier {
  /// Pindah ke halaman hasil prediksi.
  void goToResultPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ResultPage()),
    );
  }
}
