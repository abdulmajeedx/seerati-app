# Changelog

## [2.4.0] - 2026-09-23

### Added
- App icon: a resume page on the brand teal, replacing the default Flutter icon. Android gets an adaptive icon (with a monochrome layer for themed icons); iOS gets every required size. Regenerate with `python3 tool/generate_icons.py`.
- Branded launch screen on Android (including the Android 12+ system splash) and iOS, instead of a blank white screen.
- Three-page onboarding (welcome, templates, privacy) with Skip, shown on first launch only; returning users open straight to the home screen.
- The three Premium templates are now distinct layouts, not recolours of the free one:
  - **Modern**: tinted full-height sidebar (photo or initials, contact, skills, languages) beside the main column; continues on every page.
  - **Minimal**: section labels in a narrow side column, hairline rules, photo as a small rounded square.
  - **Colorful**: full-bleed banner with a decorative disc, timeline rule joining entries, filled skill chips.
  - All layouts mirror correctly for Arabic; when there is no photo, the sidebar and banner show the name's initials.
- Template picker shows each template's real first page rendered from the user's own resume, falling back to the schematic sketch while it renders.

### Fixed
- Arabic PDFs: words ending in «ر» (and other letters whose glyph overhangs) no longer run into the next word or number — «يناير2020» and «ديسمبرالماضي» now read «يناير 2020» and «ديسمبر الماضي». The cause is a bug in the `pdf` package's right-to-left word placement; the app now uses a patched copy (`third_party/pdf`, see `PATCHES.md`) until it is fixed upstream.

## [2.3.0] - 2026-08-31

### Added
- **Backup and restore**: export every resume and cover letter (photos included) to a single JSON file you can save or send anywhere, and restore it on any device — no account, no server, nothing leaves the phone unless you share the file yourself.
- Restore merges by id and never deletes: entries in the backup overwrite their counterparts, anything else on the device is left alone.
- The whole file is validated before a single write, so a corrupt or foreign file changes nothing. A photo that fails to decode is skipped rather than failing the restore.
- A backup carries no premium flag or device identity, so sharing the file cannot hand out a paid unlock.

## [2.2.1] - 2026-08-31

### Added
- Server-controlled feature flags (`GET /v1/config`): job search can be switched off from the backend without shipping a release, and the app hides the card instead of offering a feature that would fail. A server that can't be reached fails closed.

### Changed
- Job search is switched **off** by default in the current deployment while its per-call cost is evaluated; a disabled feature reports as "service busy" rather than blaming the user's input.

## [2.2.0] - 2026-08-31

### Added
- Four layered spend ceilings, all denominated in credits where 1 credit ≈ US$0.01 of AI spend: per device per day (15 free / 150 Premium), a lifetime cap per free device (45), a per-IP daily cap (45), and a global daily cap for the whole service (300). The lifetime and per-IP caps are what make reinstalling the app to farm a fresh free quota pointless.
- Endpoint costs now reflect measured spend: text calls 1 credit, cover letters 2, job search 12.
- Responses report the credits left, shown on the home screen.

### Fixed
- A billing or account usage-limit refusal upstream is reported as "service unavailable" instead of "couldn't generate this text", which wrongly told users to rephrase a perfectly good prompt.
- Every limit refusal names the ceiling that refused it, and a refused or failed call moves no counter.

## [2.1.0] - 2026-08-31

### Added
- **AI job search**: enter a role and city, and the assistant runs live web searches across job boards, returning real openings with a link and a one-line explanation of why each fits your resume. Results are matched against your most recent resume's skills and summary.
- Identical searches are cached server-side for 6 hours, so repeated queries cost nothing and return instantly.

### Notes
- A job search consumes 3 AI credits (it runs several web searches and costs roughly 15x a text generation); the free daily allowance is 6 credits, Premium 60.
- Hallucinated links are impossible to surface: every result without a real http(s) URL from the search output is dropped server-side.

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
