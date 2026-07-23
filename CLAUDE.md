# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`food_recognizer` is a Flutter app built as the final submission for the Dicoding course *Belajar Penerapan Machine Learning untuk Flutter*. It takes a photo of food and classifies it on-device with a TensorFlow Lite (LiteRT) model, then shows a prediction page with extra info. Currently a pristine `flutter create` scaffold — all features below are still to be built.

Full graded spec: `@docs/submission-guidance/` (read `02-kriteria.md` for criteria, `05-tips-and-trik.md` for model/API technical tips). Target: **Advanced tier (4 pts on every criterion)**.

## Commands

- Install deps: `flutter pub get`
- Run: `flutter run` (target a device with `-d chrome`, `-d macos`, `-d android`, …)
- Test: `flutter test` — single file: `flutter test test/widget_test.dart`
- Analyze/lint: `flutter analyze` (uses `flutter_lints`, default rules)
- Format: `dart format .` — check only: `dart format --output=none --set-exit-if-changed .`
- Pre-submission cleanup: use the `/submission-check` skill (do not hand-run `flutter clean` mid-development — it deletes `build/`)

## Submission criteria (what "done" means)

Each criterion is scored 0–4; **need ≥2 on each to pass, 4 on each for the target grade**. Aiming for Advanced means building every tier:

1. **Image capture** — `image_picker` (gallery/camera) → crop with `image_cropper` → live identification via `camera` stream.
2. **ML inference** — classify with the provided Kaggle food model via LiteRT (`tflite_flutter`) → run inference in an **Isolate** so the UI never freezes → deploy/download the model dynamically via **Firebase ML**.
3. **Prediction page** — show captured image + predicted food name + confidence → related recipes from **MealDB API** → nutrition (calories, carbs, fat, fiber, protein) from **Gemini API**.

## ML model facts (do not violate)

- Model: Kaggle `google/aiy/tfLite/vision-classifier-food-v1`. Input **224×224 RGB**, output probabilities over **2023 food classes**.
- The model ONLY classifies food-name-from-image. It cannot tell if food is edible, list ingredients, estimate nutrition, or reject non-food images — get ingredients from MealDB and nutrition from Gemini instead.
- Static-image preprocessing: decode with `image_lib.decodeImageFile(path)` (package `image`) before resizing to 224×224. Camera-feed frames convert via `ImageUtils.convertCameraImage(cameraImage)`.

## Gotchas that cause submission rejection

- Must build cleanly on the **latest stable Flutter** — a build error = automatic reject.
- Any **overflow error** in the UI = reject. Watch layouts on small screens.
- If Firebase ML is used, the config files MUST be committed: `google-services.json` (Android), `GoogleService-Info.plist` (iOS), and `firebase_options.dart`.
- Request camera/gallery permissions correctly (Android manifest + iOS `Info.plist`); a failed permission request = reject.
- Assets must each be <5 MB; final submission ZIP <25 MB (see `/submission-check`).

## Conventions

- Package import path is `package:food_recognizer/...`.
- Keep API keys OUT of the committed project (Gemini key especially) — load them at runtime, don't hardcode.
