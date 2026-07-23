# Roadmap Pengembangan — food_recognizer

> Dokumen rencana utama untuk submission Dicoding *Belajar Penerapan Machine Learning untuk Flutter*.
> Target: **Advanced tier (4 pts di semua kriteria)**.
> Terakhir diperbarui: 2026-07-24.

## Prinsip penting

- **Tiap tier itu numpuk (cumulative).** Untuk 4 pts, harus mengerjakan Basic → Skilled → Advanced sekaligus, bukan pilih salah satu.
- **Lulus = minimal 2 pts tiap kriteria.** Nilai 0 di satu kriteria = submission ditolak.
- **Plan before coding.** Tiap fitur diusulkan dulu, tunggu approval, baru edit file.
- Yang butuh setup akun eksternal (Firebase, Gemini) ditaruh belakang, biar aplikasi cepat kelihatan jalan.

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

### Tahap 0 — Fondasi  ← SEDANG DIKERJAKAN

Tujuan: kerangka proyek rapi sebelum nambah fitur. Belum ada fitur ML/API.

- [ ] Tambah dependency awal ke `pubspec.yaml`: `image_picker` (yang lain ditambah saat fiturnya dikerjakan, biar gampang lacak error versi/build).
- [ ] Bikin struktur folder di `lib/`:
  ```
  lib/
  ├── main.dart          # entry point, setup MaterialApp + tema
  ├── screens/           # halaman (Home, Prediksi, dll.)
  │   └── home_screen.dart
  ├── services/          # logika akses "luar": ML, MealDB, Gemini, image picker
  ├── models/            # class data (hasil prediksi, resep, nutrisi)
  ├── widgets/           # widget reusable
  └── utils/             # helper (preprocessing gambar, konstanta)
  ```
  *Kenapa:* pisahkan UI (screens/widgets) dari logika (services) dari data (models). `main.dart` nggak jadi file raksasa.
- [ ] Ganti `main.dart` bawaan (demo counter) → `HomeScreen` sederhana: judul aplikasi + tombol placeholder "Ambil Gambar" (belum fungsional).
- [ ] Verifikasi: `flutter pub get` + `flutter analyze` bersih.

**Keputusan tertunda — state management:** rekomendasi mulai simpel (`setState` + `StatefulWidget`), perkenalkan `Provider` kalau state mulai ribet (misal hasil ML dibagi ke banyak halaman). Alternatif: `Provider` dari awal (banyak dipakai di kelas Dicoding lain).

### Tahap 1 — Kriteria 1: Ambil gambar

Paling gampang, tanpa akun/API. Kerjakan bertingkat:

- [ ] **Basic:** `image_picker` — ambil dari kamera & galeri, tampilkan gambar terpilih di halaman.
- [ ] **Skilled:** `image_cropper` — crop bagian penting gambar.
- [ ] **Advanced:** `camera` — live camera stream / camera feed untuk identifikasi.
- [ ] Setup izin: Android `AndroidManifest.xml` + iOS `Info.plist` (kamera & galeri).

### Tahap 2 — Kriteria 2: ML inference

Jantung aplikasi. **PRASYARAT: download aset dulu** (akan dipandu step-by-step):
- Model `.tflite`: Kaggle `google/aiy/tfLite/vision-classifier-food-v1`.
- Sample images: https://github.com/dicodingacademy/assets/raw/refs/heads/main/flutter_ml/assets/assets.zip

Lalu bertingkat:

- [ ] **Basic:** `tflite_flutter` + package `image`. Load model, preprocess 224×224, inferensi setelah gambar diambil. Uji dulu pakai sample images.
- [ ] **Skilled:** pindahkan inferensi ke **Isolate** biar UI nggak freeze.
- [ ] **Advanced:** **Firebase ML** — deploy model ke cloud, unduh dinamis dari app. (Butuh akun Firebase; config files WAJIB di-commit.)

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

## Status persetujuan

- ✅ **Rencana Tahap 0 (Fondasi) DISETUJUI user** (2026-07-24). Siap dieksekusi.
- ⏳ **Keputusan tertunda — state management:** belum dipilih antara `setState` dulu (rekomendasi) vs `Provider` dari awal. Tanyakan lagi di awal sesi berikutnya sebelum mulai koding.

## Catatan lingkungan

- `flutter`/`dart` ada di `/Users/septianmaulana/Development/flutter/bin/`. **Pakai path lengkap** untuk menjalankan flutter (mis. `/Users/septianmaulana/Development/flutter/bin/flutter pub get`).
- **Kenapa `flutter` tidak ada di PATH tool?** Bukan bug setup user. User sudah daftarkan flutter di `.zshenv:2` DAN `.zshrc:129` (jalan normal di Terminal interaktif). Tapi tool berjalan di dalam harness **cmux** yang menyuntikkan PATH snapshot sendiri (lihat entri `cmux-cli-shims` di depan PATH) dan tidak me-source `.zshenv`/`.zshrc`, jadi baris flutter tidak kepakai di shell tool. Tidak berdampak ke aplikasi — cukup pakai path lengkap. **Jangan investigasi ulang isu ini.**
- Hook `PostToolUse` aktif: otomatis `dart format` tiap file `.dart` ditulis/diedit.
