# Vendored `pdf` 3.13.0 (patched)

Upstream: https://pub.dev/packages/pdf/versions/3.13.0 (Apache-2.0, see LICENSE).
Only `lib/`, `LICENSE` and `pubspec.yaml` are kept. Wired in through
`dependency_overrides` in the app's `pubspec.yaml`, so `printing` uses it too.

## Patch: RTL words positioned by ink width instead of advance

`lib/src/widgets/text.dart` — `_Line.realign` placed each word of a
right-to-left line at `delta - (offset.x + width)`, where `width` is the
glyphs' ink bounds. Line layout advances by `advanceWidth`, so any word whose
ink is wider or narrower than its advance shifted sideways. With Cairo, a word
ending in «ر» (ink overhangs its advance) next to digits (ink narrower than
their advance) lost the whole space between them: «يناير2020»,
«ديسمبرالماضي».

Fix: `_Span` gains an `advance` getter (`_Word` returns
`metrics.advanceWidth`, other spans keep `width`), and both RTL branches of
`realign` use it.

Still present in 3.13.1. Drop this directory and the override once upstream
fixes it.
