import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:food_recognizer/controller/home_controller.dart';
import 'package:food_recognizer/firebase_options.dart';
import 'package:food_recognizer/service/ml_service.dart';
import 'package:food_recognizer/ui/home_page.dart';

Future<void> main() async {
  // ensureInitialized wajib sebelum memanggil kode async (Firebase) di main.
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi Firebase — dipakai untuk mengunduh model ML dari Storage.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      providers: [
        ChangeNotifierProvider(create: (_) => HomeController()),
        // MlService dibagikan seluruh app (model cukup dimuat sekali).
        // Provider biasa (bukan ChangeNotifier) — ia bukan state yang di-observe,
        // hanya "mesin" yang dipanggil ResultController.
        Provider<MlService>(
          create: (_) => MlService(),
          dispose: (_, service) => service.dispose(),
        ),
      ],
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
