# Roadmap Pengembangan — food_recognizer

> Dokumen rencana utama untuk submission Dicoding *Belajar Penerapan Machine Learning untuk Flutter*.
> Target: **Advanced tier (4 pts di semua kriteria)**.
> Terakhir diperbarui: 2026-07-24.

## Prinsip penting

- **Tiap tier itu numpuk (cumulative).** Untuk 4 pts, harus mengerjakan Basic → Skilled → Advanced sekaligus, bukan pilih salah satu.
- **Lulus = minimal 2 pts tiap kriteria.** Nilai 0 di satu kriteria = submission ditolak.
- **Plan before coding.** Tiap fitur diusulkan dulu, tunggu approval, baru edit file.
- Yang butuh setup akun eksternal (Firebase, Gemini) ditaruh belakang, biar aplikasi cepat kelihatan jalan.
- **Ikut format mentor.** Branch `submission` di repo `dicodingacademy/a758-machine-learning-flutter` = skeleton resmi: struktur `controller/` + `ui/` + `widget/` dengan **Provider**. Kita bangun di atas kerangka itu.

## Peta 3 kriteria

| Kriteria | Basic (2) | Skilled (3) | Advanced (4) |
|---|---|---|---|
| **1. Ambil gambar** | `image_picker` (kamera/galeri) | + crop pakai `image_cropper` | + live camera stream pakai `camera` |
| **2. Machine Learning** | model TFLite via LiteRT (`tflite_flutter`) | + inferensi jalan di **Isolate** | + model diunduh dari **Firebase ML** |
| **3. Halaman prediksi** | foto + nama makanan + confidence | + resep dari **MealDB API** | + nutrisi dari **Gemini API** |

## Fakta model ML (jangan dilanggar)

- Model Kaggle `google/aiy/tfLite/vision-classifier-food-v1`. Input **224×224 RGB**, output probabilitas atas **2023 kelas makanan**.
- Model HANYA klasifikasi nama-makanan-dari-gambar. Tidak bisa cek layak-makan, tidak bisa list bahan, tidak bisa estimasi nutrisi, tidak bisa tolak gambar non-makanan.
- Bahan → dari MealDB. Nutrisi → dari Gemini.
- Preprocessing gambar statis: `image_lib.decodeImageFile(path)` (package `image`) sebelum resize ke 224×224. Frame kamera: `ImageUtils.convertCameraImage(cameraImage)`.

## Gotcha yang bikin submission ditolak

- Harus build bersih di Flutter stable terbaru. Build error = auto reject.
- Overflow error di UI = reject. Cek layout di layar kecil.
- Kalau pakai Firebase ML: `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart` WAJIB di-commit.
- Izin kamera/galeri harus benar (Android manifest + iOS `Info.plist`). Gagal minta izin = reject.
- Tiap asset <5 MB; ZIP final <25 MB.

---

## Urutan pengerjaan

### Tahap 0 — Fondasi  ✅ SELESAI (2026-07-24)

Tujuan: kerangka proyek rapi sebelum nambah fitur. Belum ada fitur ML/API.
Hasil: rename app ID → `com.projecopedia.*` (semua platform), struktur `lib/` mentor terbentuk, `flutter analyze` bersih, smoke test lolos.

- [x] Tambah dependency awal ke `pubspec.yaml`: `provider` (^6.1.5 terpasang) + `image_picker` (^1.1.2). Sisanya ditambah saat fiturnya dikerjakan.
- [x] Bikin struktur folder di `lib/` — **ikut format mentor** (branch `submission`):
  ```
  lib/
  ├── main.dart              # entry: MultiProvider → ChangeNotifierProvider → MaterialApp → HomePage
  ├── controller/            # state + orkestrasi (class ChangeNotifier), diakses via Provider
  │   └── home_controller.dart
  ├── ui/                    # halaman penuh
  │   ├── home_page.dart
  │   └── result_page.dart
  ├── widget/                # widget reusable (mis. item hasil klasifikasi)
  │   └── classification_item.dart
  ├── service/   (nanti)     # akses "luar" mentah: ML/TFLite, MealDB, Gemini, image picker
  ├── model/     (nanti)     # class data murni (hasil prediksi, resep, nutrisi)
  └── util/      (nanti)     # helper (preprocessing gambar, konstanta)
  ```
  *Kenapa:* `controller/ui/widget` = kerangka wajib dari mentor (pakai Provider). `service/model/util` kita tambah saat butuh (belum ada di skeleton mentor) supaya controller nggak gemuk — controller memanggil service, service yang benar-benar akses ML/API.
- [x] Ganti `main.dart` bawaan (demo counter) → skeleton ala mentor: `MultiProvider(HomeController)` → `HomePage` sederhana (judul app + tombol placeholder "Ambil Gambar") + `ResultPage` kosong. Bonus: `widget/classification_item.dart`.
- [x] Verifikasi: `flutter pub get` + `flutter analyze` bersih + `flutter test` lolos.
- [x] Rename application ID `com.example.*` → `com.projecopedia.*` konsisten (Android namespace + applicationId + MainActivity.kt, iOS/macOS bundle id, linux/windows).

**Keputusan state management — SUDAH DIPUTUS: `Provider` dari awal.** Mentor mewajibkan lewat skeleton (`provider: ^6.1.2`, `ChangeNotifierProvider` di `main.dart`). Tiap "state" ditaruh di class `ChangeNotifier` dalam `controller/`, panggil `notifyListeners()` saat berubah, UI membaca via `context.watch`/`context.read`.

### Tahap 1 — Kriteria 1: Ambil gambar

Paling gampang, tanpa akun/API. Kerjakan bertingkat:

- [x] **Basic:** `image_picker` — ambil dari kamera & galeri, tampilkan gambar terpilih di halaman. ✅ (branch `feat/ambil-gambar`) — `ImageService` bungkus picker + `permission_handler`, `HomeController` state XFile, `HomePage` bottom sheet + preview 1:1 + SnackBar error, 6 widget test.
- [x] **Skilled:** `image_cropper` — crop bagian penting gambar. ✅ (branch `feat/crop-gambar`) — crop otomatis setelah pilih foto, rasio dikunci 1:1 (cocok input model 224×224). Batal crop → foto asli dipakai. `UCropActivity` didaftarkan di AndroidManifest. 8 widget test.
- [x] **Advanced:** `camera` — live camera feed. ✅ (branch `feat/kamera-live`) — `CameraPage` (preview realtime + shutter + flip kamera, lifecycle aman via WidgetsBindingObserver). Opsi ke-3 di bottom sheet; jepret → crop 1:1 → preview. Izin CAMERA reuse dari tier Basic. 12 widget test. Catatan: identifikasi realtime menyusul di Kriteria 2 (butuh model).
- [x] Setup izin: Android `AndroidManifest.xml` (`CAMERA`) + iOS `Info.plist` (`NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription`). ✅ Galeri Android 13+ pakai Photo Picker (tanpa izin storage).

### Tahap 2 — Kriteria 2: ML inference

Jantung aplikasi. **PRASYARAT: download aset dulu** (akan dipandu step-by-step):
- Model `.tflite`: Kaggle `google/aiy/tfLite/vision-classifier-food-v1`.
- Sample images: https://github.com/dicodingacademy/assets/raw/refs/heads/main/flutter_ml/assets/assets.zip

**FAKTA MODEL (dari inspeksi `.tflite` asli, BUKAN 224):** input **192×192×3 uint8** (piksel mentah 0–255), output **[1,2024] uint8** (confidence = nilai × 0.00390625). Indeks 0 = `__background__`, 1–2023 = makanan. Label dari `assets/labels/aiy_food_V1_labelmap.csv` (dari gstatic).

**PENTING — Firebase ML deprecated:** menu Firebase ML **hilang untuk project baru** (shutdown Juni 2027). Pengganti: **Firebase Storage** (bucket `projecopedia-food-recognizer.firebasestorage.app`, path `models/food-model-v1.tflite`, rules `read:true/write:false`). App unduh via SDK `firebase_storage`. Untuk Play Store nanti tetap Storage (future-proof).

Lalu bertingkat:

- [x] **Basic:** `tflite_flutter` + `image`. ✅ (branch `feat/ml-inference`) — `MlService.classify`: decode → resize **192×192** → inferensi uint8 → top-5. `ResultPage` tampil juara + alternatif. Diverifikasi di emulator: nasi-lemak → **"Nasi lemak" 87.9%** (benar!).
- [ ] **Skilled:** pindahkan inferensi ke **Isolate** biar UI nggak freeze. ← BERIKUTNYA (PR-B)
- [x] **Advanced (sumber cloud):** model diunduh dari **Firebase Storage** (bukan Firebase ML yang deprecated). ✅ `firebase_core` init + `firebase_storage` download + cache lokal. Config (`firebase_options.dart`, `google-services.json`, plist) ter-commit.
- [x] Catatan gradle: `applicationId` sudah `com.projecopedia.food_recognizer` (sejak Tahap 0). Tambahan: `kotlin.jvm.target.validation.mode=warning` (JDK 25 vs plugin).

### Tahap 3 — Kriteria 3: Halaman prediksi

- [ ] **Basic:** halaman detail — foto yang diambil + nama makanan hasil inferensi + confidence score (%).
- [ ] **Skilled:** **MealDB API** (gratis, tanpa key) — resep terkait via endpoint Search: nama (`strMeal`), foto (`strMealThumb`), bahan (`strIngredientX`/`strMeasureX`), langkah (`strInstructions`).
- [ ] **Advanced:** **Gemini API** — nutrisi (kalori, karbohidrat, lemak, serat, protein dalam gram) via structured output. API key JANGAN di-hardcode, load saat runtime.

### Tahap 4 — Pra-submission

- [ ] `flutter analyze` + `dart format` bersih.
- [ ] Cek overflow di layar kecil.
- [ ] Pastikan config Firebase ter-commit (kalau dipakai).
- [ ] Jalankan skill `/submission-check` (cek ukuran asset <5 MB, ZIP <25 MB).

---

## Setup yang belum ada (dipandu saat dibutuhkan)

- **Aset model + sample images (Kaggle)** — untuk Tahap 2.
- **Firebase project** — untuk Tahap 2 Advanced (config: `google-services.json` / `GoogleService-Info.plist` / `firebase_options.dart`).
- **Gemini API key** (Google AI Studio) — untuk Tahap 3 Advanced. Keluarkan dari project yang di-commit.

## Alur Git (DIPUTUS user, 2026-07-24) — Git Flow

- `main` = stabil (baseline 1 commit init sampai ada rilis via develop).
- `develop` = integrasi. Tahap 0 (fondasi) sudah masuk via PR #1.
- Branch topik per langkah: `feat/*` `docs/*` `fix/*` `chore/*` → PR ke `develop`.
- `develop` → `main` lewat PR saat rilis.

## Status persetujuan

- ✅ **Rencana Tahap 0 (Fondasi) DISETUJUI user** (2026-07-24). Diselaraskan dgn format mentor (branch `submission`) 2026-07-24.
- ✅ **State management DIPUTUS: `Provider`** (ikut skeleton mentor). Struktur folder ikut mentor: `controller/`, `ui/`, `widget/` (+ `service/model/util` menyusul).
- ✅ **Tier Basic Kriteria 1 SELESAI** (2026-07-24). Diverifikasi di emulator Android. PR #2.
- ✅ **Tier Skilled Kriteria 1 SELESAI** (2026-07-24). Crop 1:1 otomatis, diverifikasi di emulator (layar uCrop muncul & konfirmasi menghasilkan preview).
- ✅ **Tier Advanced Kriteria 1 SELESAI** (2026-07-24). Kamera live (preview + shutter + flip), diverifikasi di emulator. **KRITERIA 1 TUNTAS (Basic+Skilled+Advanced → target 4 poin).**
- ✅ **Kriteria 2 Basic + sumber Advanced SELESAI** (2026-07-24). Inferensi TFLite dari model Firebase Storage, diverifikasi di emulator (nasi-lemak → 87.9% benar). Firebase Storage dipakai (Firebase ML deprecated).
- ✅ **Setup tooling** (2026-07-24): kagglehub, Firebase CLI, FlutterFire CLI, Xcode 26.6, CocoaPods, Ruby 4.0.6, xcodeproj — dicatat di `~/Development/tools/installed-tools.md`. Firebase project `projecopedia-food-recognizer` dibuat.

## ▶️ LANJUT DARI SINI (sesi berikutnya)

- **Terakhir dikerjakan:** Kriteria 2 **Basic + sumber Advanced** (branch `feat/ml-inference`, belum PR/commit saat catatan ini — cek `git log`). Inferensi dari Firebase Storage terbukti jalan.
- **Berikutnya:** **Kriteria 2 tier Skilled — Isolate** (PR-B). Pindahkan `MlService.classify` (decode + resize + `interpreter.run`) ke Isolate agar UI tak freeze. Pola tflite_flutter: kirim `interpreter.address` ke isolate, rekonstruksi `Interpreter.fromAddress`.
- **Lalu:** Kriteria 3 (MealDB resep + Gemini nutrisi) — pakai `topResult.label` sebagai kunci. Config Gemini ada di `05-tips-and-trik.md` (system instruction + structured output).
- **Catatan:** feed kamera live juga bisa disambung ke inferensi realtime nanti (butuh `ImageUtils.convertCameraImage` dari starter project).

## Catatan lingkungan

- `flutter`/`dart` versi **3.44.7 stable** (Dart 3.12.2), terpasang di `/Users/septianmaulana/Development/flutter/bin/`. **Sudah ada di PATH shell tool** — cukup panggil `flutter ...` langsung (tak perlu path lengkap). Diverifikasi 2026-07-24; catatan lama soal "flutter tidak di PATH" sudah usang, abaikan.
- Hook `PostToolUse` aktif: otomatis `dart format` tiap file `.dart` ditulis/diedit.
