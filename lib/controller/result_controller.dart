import 'package:flutter/foundation.dart';

import 'package:food_recognizer/model/classification.dart';
import 'package:food_recognizer/service/ml_service.dart';

/// Tahapan proses analisis untuk ditampilkan UI.
enum AnalysisStatus {
  /// Belum mulai.
  idle,

  /// Sedang mengunduh model dari Firebase (hanya saat pertama kali).
  downloadingModel,

  /// Model siap, sedang menjalankan inferensi.
  classifying,

  /// Selesai, hasil tersedia.
  done,

  /// Gagal.
  error,
}

/// Controller untuk [ResultPage].
///
/// Memakai [MlService] **bersama** (dibuat di root app via Provider) sehingga
/// model cukup dimuat sekali; controller ini tidak me-dispose service tersebut.
class ResultController extends ChangeNotifier {
  // named param privat tak diizinkan, jadi assign eksplisit satu-satunya cara.
  // ignore: prefer_initializing_formals
  ResultController({required MlService mlService}) : _mlService = mlService;

  final MlService _mlService;

  AnalysisStatus _status = AnalysisStatus.idle;
  AnalysisStatus get status => _status;

  /// Progres unduhan model 0.0–1.0 (relevan saat [AnalysisStatus.downloadingModel]).
  double _downloadProgress = 0;
  double get downloadProgress => _downloadProgress;

  List<Classification> _results = const [];
  List<Classification> get results => _results;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Prediksi teratas (null bila belum ada hasil).
  Classification? get topResult => _results.isEmpty ? null : _results.first;

  /// Kandidat selain juara (untuk daftar "alternatif").
  List<Classification> get alternatives =>
      _results.length <= 1 ? const [] : _results.sublist(1);

  /// Menjalankan seluruh alur: siapkan model (unduh bila perlu) → inferensi.
  Future<void> analyze(String imagePath) async {
    _errorMessage = null;
    _downloadProgress = 0;
    _status = _mlService.isReady
        ? AnalysisStatus.classifying
        : AnalysisStatus.downloadingModel;
    notifyListeners();

    try {
      await _mlService.prepare(
        onDownloadProgress: (p) {
          _downloadProgress = p;
          notifyListeners();
        },
      );

      _status = AnalysisStatus.classifying;
      notifyListeners();

      _results = await _mlService.classify(imagePath, topK: 5);
      _status = AnalysisStatus.done;
    } catch (e) {
      _errorMessage = 'Gagal menganalisis gambar.\n$e';
      _status = AnalysisStatus.error;
    }
    notifyListeners();
  }
}
