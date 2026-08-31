# Changelog

## [2.0.1] - 2026-08-31

### Changed
- The AI cover-letter generator now has its own card on the home screen; previously every AI feature was buried inside a flow and the release looked unchanged on launch.

## [2.0.0] - 2026-08-31

### Added
- AI assistant (Claude, via the Seerati backend): improve the professional summary, rewrite experience descriptions as resume bullets, and generate a cover letter tailored to a pasted job ad — in Arabic or English.
- Backend service (`backend/`): Dart + shelf proxy holding the Claude API key, per-device daily quotas, single-use activation codes, and per-IP rate limiting behind nginx + Cloudflare.
- Activation codes are now verified server-side, so each code unlocks Premium on exactly one device.

### Changed
- Builds without `SEERATI_API_BASE`/`SEERATI_APP_KEY` hide every AI feature and stay fully offline.
- Failed AI generations refund the user's daily quota.

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
