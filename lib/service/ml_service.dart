import 'dart:io';
import 'dart:isolate';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'package:food_recognizer/model/classification.dart';

/// Otak Machine Learning aplikasi.
///
/// Tanggung jawab:
/// 1. Mengunduh model TFLite dari **Firebase Storage** (sekali, lalu di-cache).
/// 2. Memuat model dengan **LiteRT** (`tflite_flutter`) + label makanan.
/// 3. Klasifikasi gambar → daftar prediksi teratas.
///
/// Fakta model (dari inspeksi file `.tflite` asli — BUKAN 224x224 seperti doс):
/// - Input  : [1, 192, 192, 3] uint8 (piksel mentah 0–255).
/// - Output : [1, 2024] uint8; confidence = nilai × [_outputScale].
/// - Indeks 0 = `__background__` (dilewati), 1–2023 = nama makanan.
class MlService {
  /// Path model di Firebase Storage (lihat bucket projecopedia-food-recognizer).
  static const _modelStoragePath = 'models/food-model-v1.tflite';

  /// Nama file cache lokal setelah diunduh.
  static const _modelFileName = 'food-model-v1.tflite';

  /// Aset label: CSV `id,name` (baris 0 = header).
  static const _labelAsset = 'assets/labels/aiy_food_V1_labelmap.csv';

  /// Sisi input model (192×192).
  static const _inputSize = 192;

  /// Faktor dequantisasi output (dari quant param model: scale = 1/256).
  static const _outputScale = 0.00390625;

  Interpreter? _interpreter;
  List<String>? _labels;

  /// `true` bila model & label sudah dimuat dan siap dipakai [classify].
  bool get isReady => _interpreter != null && _labels != null;

  /// Menyiapkan model: load label → pastikan model terunduh → load interpreter.
  ///
  /// Idempotent: aman dipanggil berkali-kali; kerja berat hanya sekali.
  /// [onDownloadProgress] memberi progres unduhan model (0.0–1.0) saat pertama.
  Future<void> prepare({
    void Function(double progress)? onDownloadProgress,
  }) async {
    if (isReady) return;
    _labels ??= await _loadLabels();
    final modelFile = await _ensureModelDownloaded(onDownloadProgress);
    _interpreter ??= Interpreter.fromFile(modelFile);
  }

  /// Mengunduh model dari Firebase Storage ke folder aplikasi, sekali saja.
  /// Kalau file cache sudah ada, langsung dipakai (tak mengunduh ulang).
  Future<File> _ensureModelDownloaded(void Function(double)? onProgress) async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/$_modelFileName');
    if (await file.exists() && await file.length() > 0) return file;

    final ref = FirebaseStorage.instance.ref(_modelStoragePath);
    final task = ref.writeToFile(file);
    if (onProgress != null) {
      task.snapshotEvents.listen((s) {
        if (s.totalBytes > 0) onProgress(s.bytesTransferred / s.totalBytes);
      });
    }
    await task;
    return file;
  }

  /// Memuat label dari aset CSV. Indeks list = indeks output model.
  Future<List<String>> _loadLabels() async {
    final raw = await rootBundle.loadString(_labelAsset);
    final lines = raw.split('\n');
    final labels = <String>[];
    // Lewati baris 0 (header "id,name").
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final comma = line.indexOf(',');
      labels.add(comma >= 0 ? line.substring(comma + 1) : line);
    }
    return labels;
  }

  /// Klasifikasi gambar di [imagePath].
  ///
  /// Mengembalikan [topK] prediksi teratas (urut menurun), tanpa
  /// `__background__`. Melempar [StateError] bila belum [prepare] atau gambar
  /// tidak terbaca.
  Future<List<Classification>> classify(
    String imagePath, {
    int topK = 5,
  }) async {
    final interpreter = _interpreter;
    final labels = _labels;
    if (interpreter == null || labels == null) {
      throw StateError('MlService belum siap — panggil prepare() dulu.');
    }

    // Kerja CPU-berat (decode, resize, susun input, interpreter.run, sort)
    // dijalankan di Isolate TERPISAH agar isolate utama (UI) tidak nge-freeze.
    // Interpreter native tak bisa dikirim antar-isolate, tapi ALAMAT memori-nya
    // (int) bisa — di dalam isolate direkonstruksi via Interpreter.fromAddress.
    final topIndexed = await Isolate.run(
      () => _runInferenceIsolate(
        imagePath: imagePath,
        interpreterAddress: interpreter.address,
        inputSize: _inputSize,
        outputSize: labels.length,
        take: topK + 1, // +1 penyangga bila __background__ ikut teratas
      ),
    );

    // Kembali di isolate utama: map indeks → label + dequantisasi, lewati
    // __background__ (idx 0). Kerja ringan ini aman di UI thread.
    final results = <Classification>[];
    for (final e in topIndexed) {
      if (e.index == 0) continue; // __background__
      if (e.index >= labels.length) continue;
      results.add(
        Classification(
          label: labels[e.index],
          confidence: e.score * _outputScale,
        ),
      );
      if (results.length >= topK) break;
    }
    return results;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

/// Dijalankan DI DALAM Isolate: decode gambar → inferensi → top (indeks, skor).
///
/// Harus fungsi top-level (bukan method) agar bisa dikirim ke [Isolate.run].
/// Mengembalikan list record sederhana (int) yang aman disalin antar-isolate.
/// [interpreterAddress] adalah alamat native interpreter yang dibuat di isolate
/// utama; di sini direkonstruksi tanpa memuat ulang model.
List<({int index, int score})> _runInferenceIsolate({
  required String imagePath,
  required int interpreterAddress,
  required int inputSize,
  required int outputSize,
  required int take,
}) {
  final interpreter = Interpreter.fromAddress(interpreterAddress);

  // Decode + resize ke inputSize×inputSize (versi sinkron, di isolate).
  final bytes = File(imagePath).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw StateError('Gambar tidak bisa dibaca.');
  final resized = img.copyResize(decoded, width: inputSize, height: inputSize);

  // Input uint8 [1, inputSize, inputSize, 3] (piksel mentah 0–255).
  final input = [
    List.generate(
      inputSize,
      (y) => List.generate(inputSize, (x) {
        final p = resized.getPixel(x, y);
        return [p.r.toInt(), p.g.toInt(), p.b.toInt()];
      }),
    ),
  ];
  final output = [List.filled(outputSize, 0)];

  interpreter.run(input, output);

  // Ambil [take] indeks berskor tertinggi (sort di sini, hemat data yang
  // dikirim balik ke isolate utama).
  final scores = output[0];
  final indices = List<int>.generate(scores.length, (i) => i)
    ..sort((a, b) => scores[b].compareTo(scores[a]));

  return [for (final i in indices.take(take)) (index: i, score: scores[i])];
}
