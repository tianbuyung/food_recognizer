---
name: submission-check
description: Pre-submission checklist for the Dicoding Food Recognizer submission. Verifies the project builds and analyzes cleanly, then cleans it and confirms it meets the packaging rules (build/ removed, assets <5MB, ZIP <25MB) before the user zips and submits.
disable-model-invocation: true
---

# Submission check

Run the Dicoding pre-submission checklist for `food_recognizer`. This deletes `build/` via `flutter clean`, so it is user-triggered only — never run automatically mid-development.

Perform these steps in order and report a clear PASS/FAIL for each. Explain findings in Bahasa Indonesia (per CLAUDE.local.md). Stop and warn the user if any hard-reject condition is found.

1. **Static analysis** — run `flutter analyze`. Any error is a submission blocker (reject on build errors). Report warnings too, especially anything hinting at overflow.

2. **Format check** — run `dart format --output=none --set-exit-if-changed .`. If it fails, offer to run `dart format .`.

3. **Firebase config (only if Firebase ML is used)** — if the project imports/uses Firebase ML, confirm these exist, else it's a reject:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
   - `lib/firebase_options.dart`
   If Firebase is not used, skip this step.

4. **No hardcoded API keys** — grep the `lib/` tree for a leaked Gemini/API key (e.g. `AIza...` patterns or obvious `apiKey = "..."`). Flag anything found — keys must not be committed.

5. **Asset sizes** — check every file under any `assets/` directory. Each must be **< 5 MB**. List any offenders with their sizes.

6. **Clean the project** — run `flutter clean`, then confirm the `build/` folder is gone. Remind the user: **do not run or rebuild the app after this point** — running regenerates `build/` and bloats the ZIP.

7. **Estimate ZIP size** — compute the total size of the project excluding `build/`, `.dart_tool/`, and `.git/` (e.g. `du -sh --exclude` or an equivalent). Warn if it approaches or exceeds **25 MB**.

8. **Summary** — print a checklist recap (✅/❌ per item) and a final verdict: ready to ZIP and submit, or list of things to fix first. Remind the user to submit the ZIP via the Dicoding submission page.
