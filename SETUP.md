# 🔧 SETUP — Food Recognizer

Panduan menyiapkan proyek ini **dari nol** (untuk future-you, kontributor, atau
reviewer). Untuk deskripsi & fitur, lihat [README.md](README.md).

> **Tools GLOBAL** (Flutter, Android Studio, Node, dll) dicatat terpisah di
> `~/Development/tools/installed-tools.md`. Dokumen ini **khusus proyek** ini.

---

## 1. Prasyarat

- Flutter SDK (stable terbaru) + perangkat/emulator Android.
- Akun: **Google** (Firebase & Gemini), opsional **Kaggle** (unduh model).

---

## 2. Dependency & paket

```bash
flutter pub get
```

Paket penting per fitur:

| Paket | Fungsi | Kriteria |
|---|---|---|
| `provider` | State management (`ChangeNotifier`) | semua |
| `image_picker` · `image_cropper` · `camera` | Ambil & crop gambar | 1 |
| `permission_handler` | Izin kamera runtime | 1 |
| `tflite_flutter` · `image` · `path_provider` | Inferensi TFLite (+ cache model) | 2 |
| `firebase_core` · `firebase_storage` | Unduh model dari cloud | 2 |
| `http` | MealDB & Gemini API | 3 |
| `flutter_dotenv` | Muat `GEMINI_API_KEY` dari `.env` | 3 |

---

## 3. Model ML (Firebase Storage)

Model **tidak dibundel** (±20 MB > batas asset 5 MB) — diunduh dari Firebase
Storage saat runtime.

**a. Unduh model** (Kaggle `google/aiy/tfLite/vision-classifier-food-v1`):
```python
# pip install kagglehub
import kagglehub
path = kagglehub.model_download("google/aiy/tfLite/vision-classifier-food-v1")
# → ~/.cache/kagglehub/.../1.tflite  (input 192x192 uint8, output [1,2024])
```

**b. Upload ke Firebase Storage:**
- Firebase Console → project → **Build → Storage** → aktifkan.
- **Rules** (izinkan unduh, larang tulis):
  ```
  rules_version = '2';
  service firebase.storage {
    match /b/{bucket}/o {
      match /{allPaths=**} { allow read: if true; allow write: if false; }
    }
  }
  ```
- Upload model ke path **`models/food-model-v1.tflite`** (dirujuk di
  `lib/service/ml_service.dart`).

> ⚠️ Firebase **ML** (custom model) sudah deprecated / hilang untuk project baru
> → dipakai **Firebase Storage** sebagai gantinya.

**c. Config Firebase** (sudah di-commit; regenerate bila ganti project):
```bash
dart pub global activate flutterfire_cli   # perlu Firebase CLI + login
flutterfire configure --platforms=android
# → lib/firebase_options.dart, android/app/google-services.json
```
> Kunci di file config Firebase itu **aman publik by design** (bukan rahasia);
> keamanan via Storage Rules di atas.

---

## 4. Label makanan

`assets/labels/aiy_food_V1_labelmap.csv` (2024 baris: id 0 = `__background__`,
1–2023 = makanan). Sumber:
`https://www.gstatic.com/aihub/tfhub/labelmaps/aiy_food_V1_labelmap.csv`.

---

## 5. Gemini API key (fitur nutrisi)

Key **tidak di-hardcode / tidak di-commit** — dimuat runtime dari `.env`.

```bash
cp .env.example .env
```
Isi key gratis dari [Google AI Studio](https://aistudio.google.com/apikey):
```env
GEMINI_API_KEY=isi_key_kamu
```
- Model dipakai: **`gemini-flash-latest`** (alias; versi spesifik seperti
  `gemini-2.5-flash` bisa "not available to new users").
- `.env` **gitignored** tapi **wajib ada saat build** (didaftarkan sebagai asset)
  — kalau file hilang, `flutter build` GAGAL. Untuk ZIP submission, sertakan
  `.env` (placeholder pun cukup agar build lolos).

---

## 6. Jalankan & tes

```bash
flutter run                 # butuh emulator/perangkat Android
flutter test                # 27 unit/widget test (mock, tanpa jaringan)
flutter analyze             # linter (harus bersih)
```

---

## 7. Troubleshooting (yang pernah ditemui)

| Gejala | Sebab & solusi |
|---|---|
| `Inconsistent JVM Target` saat build | JDK sistem terlalu baru vs plugin. `android/gradle.properties`: `kotlin.jvm.target.validation.mode=warning` |
| `flutterfire configure` error `xcodeproj (LoadError)` | Gem Ruby kurang: `gem install xcodeproj` (atau pilih `--platforms=android` saja) |
| `No file or variants found for asset: .env` | File `.env` tidak ada. Buat dari `.env.example`. |
| Nutrisi "Gagal memuat" | `GEMINI_API_KEY` belum diisi/valid, atau kuota project habis (429). |
| Flutter tak deteksi Brave (web) | `export CHROME_EXECUTABLE="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"` |

---

## 8. Alur Git (Git Flow)

`feat/*` `docs/*` `fix/*` `chore/*` → **PR ke `develop`** → **PR `develop` → `main`** (rilis).
