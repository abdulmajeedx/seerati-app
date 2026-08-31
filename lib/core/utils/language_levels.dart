import '../../l10n/app_localizations.dart';

abstract final class LanguageLevels {
  static const beginner = 'beginner';
  static const intermediate = 'intermediate';
  static const advanced = 'advanced';
  static const native = 'native';
  static const all = [beginner, intermediate, advanced, native];

  static String label(String key, AppLocalizations l10n) => switch (key) {
        beginner => l10n.levelBeginner,
        intermediate => l10n.levelIntermediate,
        advanced => l10n.levelAdvanced,
        native => l10n.levelNative,
        _ => key,
      };
}
