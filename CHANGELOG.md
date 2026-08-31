# Changelog

## [1.1.0] - 2026-08-31

### Added
- Local data encryption: Hive boxes now AES-256 encrypted, key stored in Android Keystore (flutter_secure_storage); existing v1.0.0 data migrates automatically with an on-disk backup.
- Offline activation codes: "Have an activation code?" on the paywall unlocks Premium; admin generates codes with `dart run tool/generate_codes.dart [count]`. Rate-limited to 5 attempts/minute.

## [1.0.0] - 2026-08-31

### Added
- Project structure (features/ core/ shared/), Material 3 light/dark theme.
- Full Arabic/English localization (ARB) with persisted language switcher and RTL/LTR support.
- Stepper resume form: personal info + photo, summary, experience, education, skills, languages & courses, with validation.
- 4 PDF templates (Classic free; Modern, Minimal, Colorful premium) rendering Arabic (Cairo, RTL) and English (Roboto, LTR).
- Live PDF preview with share/print; watermark for free users.
- Local storage (Hive): "My Resumes" list with edit/preview/delete.
- Cover letter generator from a bilingual text template, with editor and PDF export.
- One-time in-app purchase unlocking all templates and removing the watermark.
- CI: GitHub Actions Android build workflow; disabled iOS workflow with enablement notes.
