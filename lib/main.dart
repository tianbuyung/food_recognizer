import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:food_recognizer/controller/home_controller.dart';
import 'package:food_recognizer/ui/home_page.dart';

void main() {
  runApp(const FoodRecognizerApp());
}

class FoodRecognizerApp extends StatelessWidget {
  const FoodRecognizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider = tempat mendaftarkan semua "controller" (state) aplikasi.
    // Tiap controller adalah ChangeNotifier; nanti tinggal tambah entri baru
    // di sini saat fitur bertambah (mis. controller ML, controller resep).
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => HomeController())],
      child: MaterialApp(
        title: 'Food Recognizer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}
